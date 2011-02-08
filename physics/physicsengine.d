module physics.physicsengine;


import physics.physicsbody;
import physics.contact;
import physics.contactdetect;
import physics.physicsmonitor;
import spatial.spatialmanager;
import spatial.gridspatialmanager;
import gui.guielement;
import monitor.monitormenu;
import monitor.monitorable;
import math.vector2;
import signal;
import weaksingleton;
import arrayutil;
import iterator;


/**
 * Handles collision detection and physics simulation.
 *
 * Physics is processed on PhysicsBodies which contain state like mass, velocity
 * and collision volume.
 */
final class PhysicsEngine : Monitorable
{
    mixin WeakSingleton;

    invariant
    {
        assert(penetration_iteration_multiplier_ >= 1.0, 
               "Penetration iteration multiplier must be at least 1.0 to prevent "
               "unresolved penetrations");
        assert(response_iteration_multiplier_ >= 1.0, 
               "Contact response iteration multiplier must be at least 1.0 to prevent "
               "unresolved contacts");
    }

    private:
        //Spatial manager used for coarse collision detection.
        SpatialManager!(PhysicsBody) spatial_manager_;

        //Are we updating (running the simulation) right now?
        bool updating_;

        //Stores all bodies we're simulating. Will be replaced by a spatial manager.
        PhysicsBody[] bodies_;

        //Stores all contacts detected during current frame.
        //Might be replaced by a binary tree sorted by penetration depth or desired
        //delta velocity. (or both?)
        Contact[] contacts_;

        //How many times the number of contacts to iterate penetration resolution?
        //E.g. if we have 16 contacts and this is 2.0, we'll do (at most) 32 
        //iterations, allowing us to resolve penetrations resulting from the first
        //resolution.
        real penetration_iteration_multiplier_ = 2.0;

        //How many times the number of contacts to iterate collision response?
        //E.g. if we have 16 contacts and this is 2.0, we'll do (at most) 32 
        //iterations, allowing us to resolve collision response problems resulting 
        //from the first resolution.
        real response_iteration_multiplier_ = 2.0;

        //Don't bother resolving penetrations smaller than this.
        real acceptable_penetration = 0.1;

        //Don't bother resolving velocity errors smaller than this.
        real acceptable_velocity_error = 0.05;

        //Statistics data for monitoring.
        Statistics statistics_;

    package:
        //Used to send statistics data to physics monitors.
        mixin Signal!(Statistics) send_statistics;

    public:
        /**
         * Construct the PhysicsEngine.
         *
         * Params:  spatial_manager = Spatial manager to use for coarse collision detection.
         */
        this(SpatialManager!(PhysicsBody) spatial_manager)
        {
            singleton_ctor();
            spatial_manager_ = spatial_manager;
        }

        ///Destroy this PhysicsEngine.
        void die()
        {
            foreach(physics_body; bodies_){physics_body.die();}
            bodies_ = [];
            singleton_dtor();
        }

        ///Run the physics simulation of a single frame.
        void update(real time_step)
        {
            updating_ = true;

            //update all bodies' states
            foreach(physics_body; bodies_)
            {
                physics_body.update(time_step, spatial_manager_);
            }

            //handle collisions
            detect_contacts();
            resolve_penetrations();
            collision_response();

            statistics_.contacts = contacts_.length;
            send_statistics.emit(statistics_);
            statistics_.zero();

            //clear contacts
            contacts_.length = 0;
            updating_ = false;
        }

        MonitorMenu monitor_menu(){return new PhysicsEngineMonitor(this);}

        //Add a new physics body to the simulation
        //Can't be called during an update.
        void add_body(PhysicsBody physics_body)
        in
        {
            assert(!bodies_.contains(physics_body, true), 
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

        //Remove a physics body from the simulation
        //Can't be called during an update.
        void remove_body(PhysicsBody physics_body)
        in
        {
            assert(bodies_.contains(physics_body, true), 
                   "Can't remove a physics body that is not in the PhysicsEngine");
            assert(!updating_, "Can't remove physics bodies during a physics update");
        }
        body
        {
            alias arrayutil.remove remove;

            statistics_.bodies--;
            if(physics_body.volume !is null)
            {
                statistics_.col_bodies--;
                physics_body.remove_from_spatial(spatial_manager_);
            }

            bodies_.remove(physics_body, true);
        }

    private:
        //Detect collisions between bodies.
        void detect_contacts()
        {
            Contact current_contact;
            foreach(bodies; spatial_manager_.iterator)
            {
                foreach(uint a, body_a; bodies)
                {
                    //we only need to check a subrange of bodies_
                    //since we'd get the same pairs of objects checked anyway
                    for(uint b = a + 1; b < bodies.length; b++)
                    {
                        statistics_.tests++;
                        if(detect_contact(body_a, bodies[b], current_contact))
                        {
                            contacts_ ~= current_contact;
                        }
                    }
                }
            }
        }

        //Resolve interpenetrations between bodies.
        void resolve_penetrations()
        {
            //number of iterations to process - penetration resolution
            //might introduce more penetrations so we need to have more
            //iterations than contacts
            uint iterations = cast(uint)(contacts_.length * penetration_iteration_multiplier_);
            //this could be optimized by storing contacts
            //in a binary tree sorted by penetration, and/or by only working
            //with small groups of contacts (determined by coarse collision detection)
            //at a time

            //contact we're currently resolving
            Contact contact;

            //position change of body_a of current contact after resolution
            Vector2f change_a;
            //position change of body_b of current contact after resolution
            Vector2f change_b;

            //resolve penetrations from greatest to smallest
            for(uint iteration = 0; iteration < iterations; iteration++)
            {
                statistics_.penetration++;
                //note: this is probably slow, but readable, will be fixed only
                //if slowdown is measurable

                //find greatest penetration
                contact = contacts_.max((ref Contact a, ref Contact b)
                                        {return a.penetration > b.penetration;});

                //ignore insignificant penetrations
                if(contact.penetration < acceptable_penetration){break;}

                contact.resolve_penetration(change_a, change_b);

                //adjust other contacts where adjusted bodies are involved
                foreach(ref contact_b; contacts_)
                {
                    float adjust_a(){return change_a.dot_product(contact_b.contact_normal);}
                    float adjust_b(){return change_b.dot_product(contact_b.contact_normal);}

                    if(contact_b.body_a is contact.body_a)
                    {
                        contact_b.penetration += adjust_a();
                    }
                    else if(contact_b.body_a is contact.body_b)
                    {
                        contact_b.penetration += adjust_b();
                    }
                    if(contact_b.body_b is contact.body_a)
                    {
                        contact_b.penetration -= adjust_a();
                    }
                    else if(contact_b.body_b is contact.body_b)
                    {
                        contact_b.penetration -= adjust_b();
                    }
                }
            }
        }

        //Process collision responses to the contacts.
        void collision_response()
        {
            //number of iterations to process - collision response
            //might introduce more errors so we need to have more
            //iterations than contacts
            uint iterations = cast(uint)(contacts_.length * 
                                         response_iteration_multiplier_);

            Contact contact;

            //resolve collision response from greatest to smallest desired 
            //velocity change
            for(uint iteration = 0; iteration < iterations; iteration++)
            {
                statistics_.response++;
                //get the contact with maximum desired delta velocity
                contact = contacts_.max((ref Contact a, ref Contact b)
                                        {return a.desired_delta_velocity > 
                                                b.desired_delta_velocity;});

                //ignore insignificant errors
                if(contact.desired_delta_velocity < acceptable_velocity_error){break;}

                contact.collision_response();

                //don't need to adjust any parameters of contacts involving
                //bodies from currently resolved contact as they are computed
                //on demand
            }
        }
}
