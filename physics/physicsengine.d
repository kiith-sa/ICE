
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Physics engine.
module physics.physicsengine;
@safe


import std.algorithm;

import physics.physicsbody;
import physics.contact;
import physics.contactdetect;
import physics.physicsmonitor;
import spatial.spatialmanager;
import spatial.gridspatialmanager;
import monitor.monitorable;
import monitor.monitordata;
import monitor.submonitor;
import monitor.graphmonitor;
import math.vector2;
import util.signal;
import util.weaksingleton;
import util.iterable;


/**
 * Handles physics simulation and collision detection.
 *
 * Physics objects are PhysicsBodies which contain state like mass, velocity
 * and collision volume.
 * 
 * Signal:
 *     package mixin Signal!(Statistics) send_statistics
 *
 *     Used to send statistics data to physics monitors.
 */
final class PhysicsEngine : Monitorable
{
    mixin WeakSingleton;

    invariant()
    {
        assert(penetration_iteration_multiplier_ >= 1.0, 
               "Penetration iteration multiplier must be at least 1.0 to prevent "
               "unresolved penetrations");
        assert(response_iteration_multiplier_ >= 1.0, 
               "Contact response iteration multiplier must be at least 1.0 to prevent "
               "unresolved contacts");
    }

    private:
        ///Spatial manager used for coarse collision detection.
        SpatialManager!PhysicsBody spatial_manager_;

        ///Are we updating (running the simulation) right now?
        bool updating_;

        ///Bodies we're simulating.
        PhysicsBody[] bodies_;
        ///Contacts detected during current update.
        Contact[] contacts_;

        /**
         * How many times the number of contacts to iterate penetration resolution?
         *
         * E.g. if we have 16 contacts and this is 2.0, we'll do (at most) 32 
         * iterations, allowing us to resolve secondary penetrations caused by the 
         * first resolution.
         */
        real penetration_iteration_multiplier_ = 2.0;
        /*
         * How many times the number of contacts to iterate collision response?
         *
         * E.g. if we have 16 contacts and this is 2.0, we'll do (at most) 32 
         * iterations, allowing us to resolve collision response problems caused by 
         * the first resolution.
         */
        real response_iteration_multiplier_ = 2.0;

        ///Don't bother resolving penetrations smaller than this.
        real acceptable_penetration = 0.1;
        ///Don't bother resolving velocity errors smaller than this.
        real acceptable_velocity_error = 0.05;

        ///Statistics data for monitoring.
        Statistics statistics_;

    package:
        ///Used to send statistics data to physics monitors.
        mixin Signal!Statistics send_statistics;

    public:
        /**
         * Construct the PhysicsEngine.
         *
         * Params:  spatial_manager = Spatial manager to use for coarse collision detection.
         */
        this(SpatialManager!PhysicsBody spatial_manager)
        {
            singleton_ctor();
            spatial_manager_ = spatial_manager;
        }

        ///Destroy the PhysicsEngine.
        ~this()
        {
            //destroy any remaining bodies
            foreach(physics_body; bodies_)
            {
                physics_body.die(0);
                physics_body.on_die_package();
            }
            foreach(physics_body; bodies_)
            {
                clear(physics_body);
            }
            clear(bodies_);
            send_statistics.disconnect_all();
            singleton_dtor();
        }

        /**
         * Run the physics simulation of a single frame.
         *
         * Params:  time_step    = Time length of the update in seconds.
         */
        void update(in real time_step)
        {
            updating_ = true;

            //update all bodies' states
            foreach(physics_body; bodies_){physics_body.update(time_step, spatial_manager_);}

            //handle collisions
            detect_contacts();
            resolve_penetrations();
            collision_response();

            statistics_.contacts = cast(uint)contacts_.length;
            send_statistics.emit(statistics_);
            statistics_.zero();

            //clear contacts
            contacts_.length = 0;
            updating_ = false;
        }

        /**
         * Add a new physics body to the simulation.
         *
         * Must not be called during an update.
         *
         * Params:  physics_body = Body to add.
         */
        void add_body(PhysicsBody physics_body)
        in
        {
            assert(!canFind!"a is b"(bodies_, physics_body),
                   "Adding the same physics body twice");
            assert(!updating_, "Can't add new physics bodies during a physics update");
        }
        body
        {
            statistics_.bodies++;
            if(physics_body.volume !is null)
            {
                statistics_.col_bodies++;
                physics_body.add_to_spatial(spatial_manager_);
            }

            bodies_ ~= physics_body;
        }

        ///Call on_die() of all bodies dead at specified update and remove them.
        void collect_dead(size_t update_index)
        {
            foreach(physics_body; bodies_) if(physics_body.dead(update_index))
            {
                physics_body.on_die_package();
            }

            auto l = 0;
            for(size_t body_from = 0; body_from < bodies_.length; ++body_from)
            {
                auto physics_body = bodies_[body_from];
                if(physics_body.dead(update_index))
                {
                    .clear(physics_body);
                    continue;
                }
                bodies_[l] = physics_body;
                ++l;
            } 
            bodies_.length = l;
        }


        @property MonitorDataInterface monitor_data()
        {
            SubMonitor function(PhysicsEngine)[string] ctors_;
            ctors_["Contacts"] = &new_graph_monitor!(PhysicsEngine, Statistics, 
                                                     "contacts", "penetration", "response");

            ctors_["Bodies"] = &new_graph_monitor!(PhysicsEngine, Statistics, 
                                                   "bodies", "col_bodies"),
            ctors_["Coarse"] = &new_graph_monitor!(PhysicsEngine, Statistics, "tests");
            return new MonitorData!PhysicsEngine(this, ctors_);
        }

    private:
        ///Detect collisions between bodies.
        void detect_contacts()
        {
            Contact current_contact;
            //use spatial manager for coarse collision detection
            foreach(bodies; spatial_manager_.iterable)
            {
                //we only need to check a subrange of bodies_
                //since we'd get the same pairs of objects checked anyway
                foreach(a, body_a; bodies) foreach(b; a + 1 .. bodies.length)
                {
                    statistics_.tests++;
                    //fine collision detection
                    if(detect_contact(body_a, bodies[b], current_contact))
                    {
                        contacts_ ~= current_contact;
                    }
                }
            }
        }

        ///Resolve interpenetrations between bodies.
        void resolve_penetrations()
        {
            //number of iterations to process - penetration resolution might introduce
            //more penetrations so we need to have more iterations than contacts

            const iterations = cast(uint)(contacts_.length * 
                                          penetration_iteration_multiplier_);

            //contact we're currently resolving
            Contact contact;

            //position change of body_a of current contact after resolution
            Vector2f change_a;
            //position change of body_b of current contact after resolution
            Vector2f change_b;

            //resolve penetrations from greatest to smallest
            foreach(iteration; 0 .. iterations)
            {
                statistics_.penetration++;

                //note: this is probably slow, but readable, will be changed only
                //if slowdown is measurable
                //find greatest penetration
                contact = minPos!((ref Contact a, ref Contact b)
                                  {return a.penetration < b.penetration;})
                                  (contacts_)[0];

                //ignore insignificant penetrations
                if(contact.penetration < acceptable_penetration){break;}

                contact.resolve_penetration(change_a, change_b);

                //adjust other contacts where adjusted bodies are involved
                foreach(ref contact_b; contacts_) with(contact_b)
                {
                    float adjust_a(){return change_a.dot_product(contact_normal);}
                    float adjust_b(){return change_b.dot_product(contact_normal);}

                    if(body_a is contact.body_a)     {penetration += adjust_a();}
                    else if(body_a is contact.body_b){penetration += adjust_b();}
                    if(body_b is contact.body_a)     {penetration -= adjust_a();}
                    else if(body_b is contact.body_b){penetration -= adjust_b();}
                }
            }
        }

        ///Process collision responses.
        void collision_response()
        {
            //number of iterations to process - collision response
            //might introduce more errors so we need to have more
            //iterations than contacts
            const iterations = cast(size_t)(contacts_.length * 
                                            response_iteration_multiplier_);

            Contact contact;

            //resolve collision response from greatest to smallest desired 
            //velocity change
            foreach(iteration;  0 .. iterations)
            {
                statistics_.response++;
                //get the contact with maximum desired delta velocity
                contact = minPos!((ref Contact a, ref Contact b)
                                  {return a.desired_delta_velocity > b.desired_delta_velocity;})
                                  (contacts_)[0];

                //ignore insignificant errors
                if(contact.desired_delta_velocity < acceptable_velocity_error){break;}

                contact.collision_response();

                //don't need to adjust parameters of other contacts involving bodies from
                //currently resolved contact as these parameters are computed on demand
            }
        }
}
