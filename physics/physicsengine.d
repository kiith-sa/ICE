
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Physics engine.
module physics.physicsengine;


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
 *     package mixin Signal!(Statistics) sendStatistics
 *
 *     Used to send statistics data to physics monitors.
 */
final class PhysicsEngine : Monitorable
{
    mixin WeakSingleton;

    invariant()
    {
        assert(penetrationIterationMultiplier_ >= 1.0, 
               "Penetration iteration multiplier must be at least 1.0 to prevent "
               "unresolved penetrations");
        assert(responseIterationMultiplier_ >= 1.0, 
               "Contact response iteration multiplier must be at least 1.0 to prevent "
               "unresolved contacts");
    }

    private:
        ///Spatial manager used for coarse collision detection.
        SpatialManager!PhysicsBody spatialManager_;

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
        real penetrationIterationMultiplier_ = 2.0;
        /*
         * How many times the number of contacts to iterate collision response?
         *
         * E.g. if we have 16 contacts and this is 2.0, we'll do (at most) 32 
         * iterations, allowing us to resolve collision response problems caused by 
         * the first resolution.
         */
        real responseIterationMultiplier_ = 2.0;

        ///Don't bother resolving penetrations smaller than this.
        real acceptablePenetration = 0.1;
        ///Don't bother resolving velocity errors smaller than this.
        real acceptableVelocityError = 0.05;

        ///Statistics data for monitoring.
        Statistics statistics_;

    package:
        ///Used to send statistics data to physics monitors.
        mixin Signal!Statistics sendStatistics;

    public:
        /**
         * Construct the PhysicsEngine.
         *
         * Params:  spatialManager = Spatial manager to use for coarse collision detection.
         */
        this(SpatialManager!PhysicsBody spatialManager)
        {
            singletonCtor();
            spatialManager_ = spatialManager;
        }

        ///Destroy the PhysicsEngine.
        ~this()
        {
            //destroy any remaining bodies
            foreach(physicsBody; bodies_)
            {
                physicsBody.die(0);
                physicsBody.onDiePackage();
            }
            foreach(physicsBody; bodies_)
            {
                physicsBody.removeFromSpatial(spatialManager_);
                clear(physicsBody);
            }
            clear(bodies_);
            sendStatistics.disconnectAll();
            singletonDtor();
        }

        /**
         * Run the physics simulation of a single frame.
         *
         * Params:  timeStep    = Time length of the update in seconds.
         */
        void update(const real timeStep)
        {
            updating_ = true;

            //update all bodies' states
            foreach(physicsBody; bodies_)
            {
                physicsBody.updatePackage(timeStep, spatialManager_);
            }

            //handle collisions
            detectContacts();
            resolvePenetrations();
            collisionResponse();

            statistics_.contacts = cast(uint)contacts_.length;
            sendStatistics.emit(statistics_);
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
         * Params:  physicsBody = Body to add.
         */
        void addBody(PhysicsBody physicsBody)
        in
        {
            assert(!canFind!"a is b"(bodies_, physicsBody),
                   "Adding the same physics body twice");
            assert(!updating_, "Can't add new physics bodies during a physics update");
        }
        body
        {
            statistics_.bodies++;
            if(physicsBody.volume !is null)
            {
                statistics_.colBodies++;
                physicsBody.addToSpatial(spatialManager_);
            }

            bodies_ ~= physicsBody;
        }

        ///Call onDie() of all bodies dead at specified update and remove them.
        void collectDead(const size_t updateIndex)
        {
            foreach(physicsBody; bodies_) if(physicsBody.dead(updateIndex))
            {
                physicsBody.onDiePackage();
            }

            auto l = 0;
            for(size_t bodyFrom = 0; bodyFrom < bodies_.length; ++bodyFrom)
            {
                auto physicsBody = bodies_[bodyFrom];
                if(physicsBody.dead(updateIndex))
                {
                    statistics_.bodies--;
                    if(physicsBody.volume !is null)
                    {
                        statistics_.colBodies--;
                        physicsBody.removeFromSpatial(spatialManager_);
                    }
                    .clear(physicsBody);
                    continue;
                }
                bodies_[l] = physicsBody;
                ++l;
            } 
            bodies_.length = l;
        }

        @property MonitorDataInterface monitorData()
        {
            SubMonitor function(PhysicsEngine)[string] ctors_;
            ctors_["Contacts"] = &newGraphMonitor!(PhysicsEngine, Statistics, 
                                                     "contacts", "penetration", "response");

            ctors_["Bodies"] = &newGraphMonitor!(PhysicsEngine, Statistics, 
                                                   "bodies", "colBodies"),
            ctors_["Coarse"] = &newGraphMonitor!(PhysicsEngine, Statistics, "tests");
            return new MonitorData!PhysicsEngine(this, ctors_);
        }

    private:
        ///Detect collisions between bodies.
        void detectContacts()
        {
            Contact currentContact;
            //use spatial manager for coarse collision detection
            foreach(bodies; spatialManager_.iterable)
            {
                //we only need to check a subrange of bodies_
                //since we'd get the same pairs of objects checked anyway
                foreach(a, bodyA; bodies) foreach(b; a + 1 .. bodies.length)
                {
                    statistics_.tests++;
                    //fine collision detection
                    if(detectContact(bodyA, bodies[b], currentContact))
                    {
                        contacts_ ~= currentContact;
                    }
                }
            }
        }

        ///Resolve interpenetrations between bodies.
        void resolvePenetrations()
        {
            //number of iterations to process - penetration resolution might introduce
            //more penetrations so we need to have more iterations than contacts

            const iterations = cast(uint)(contacts_.length * 
                                          penetrationIterationMultiplier_);

            //contact we're currently resolving
            Contact contact;

            //position change of bodyA of current contact after resolution
            Vector2f changeA;
            //position change of bodyB of current contact after resolution
            Vector2f changeB;

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
                if(contact.penetration < acceptablePenetration){break;}

                contact.resolvePenetration(changeA, changeB);

                //adjust other contacts where adjusted bodies are involved
                foreach(ref contactB; contacts_) with(contactB)
                {
                    float adjustA(){return changeA.dotProduct(contactNormal);}
                    float adjustB(){return changeB.dotProduct(contactNormal);}

                    if(bodyA is contact.bodyA)     {penetration += adjustA();}
                    else if(bodyA is contact.bodyB){penetration += adjustB();}
                    if(bodyB is contact.bodyA)     {penetration -= adjustA();}
                    else if(bodyB is contact.bodyB){penetration -= adjustB();}
                }
            }
        }

        ///Process collision responses.
        void collisionResponse()
        {
            //number of iterations to process - collision response
            //might introduce more errors so we need to have more
            //iterations than contacts
            const iterations = cast(size_t)(contacts_.length * 
                                            responseIterationMultiplier_);

            Contact contact;

            //resolve collision response from greatest to smallest desired 
            //velocity change
            foreach(iteration;  0 .. iterations)
            {
                statistics_.response++;
                //get the contact with maximum desired delta velocity
                contact = minPos!((ref Contact a, ref Contact b)
                                  {return a.desiredDeltaVelocity > b.desiredDeltaVelocity;})
                                  (contacts_)[0];

                //ignore insignificant errors
                if(contact.desiredDeltaVelocity < acceptableVelocityError){break;}

                contact.collisionResponse();

                //don't need to adjust parameters of other contacts involving bodies from
                //currently resolved contact as these parameters are computed on demand
            }
        }
} 
