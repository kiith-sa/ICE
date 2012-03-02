
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for all particle systems.
module scene.particlesystem;


import scene.actor;
import scene.scenemanager;
import physics.physicsbody;
import math.vector2;
import util.factory;


///Base class for particle systems.
abstract class ParticleSystem : Actor
{
    private:
        ///Time left for the system to live. If negative, the system can exist indefinitely.
        real lifeTime_;

    protected:
        ///Actor the particle system is attached to. If null, the system is independent.
        Actor owner_;

    public:
        ///Set time left for the LineTrail to live. Negative means infinite.
        final void lifeTime(const real time) pure {lifeTime_ = time;}

        /**
         * Attach the particle system to specified actor.
         *
         * Params:  actor = Actor to attach to.
         */
        final void attach(Actor actor) pure {owner_ = actor;}

        ///Detach the particle system from any actor it's attached to.
        final void detach() pure {owner_ = null;}

    protected:
        /**
         * Construct a ParticleSystem.
         *
         * Params:  physicsBody    = Physics body of the system.
         *          owner           = Class to attach the system to. 
         *                            If null, the system is independent.
         *          lifeTime       = Life time of the system. 
         *                            If negative, lifetime is indefinite.
         */                          
        this(PhysicsBody physicsBody, Actor owner, const real lifeTime)
        {
            lifeTime_ = lifeTime;
            owner_ = owner;
            super(physicsBody);
        }

        override void update(SceneManager manager)
        {
            //If lifeTime_ reaches zero, destroy the system
            if(lifeTime_ >= 0.0 && lifeTime_ - manager.timeStep <= 0.0)
            {
                die(manager.updateIndex);
            }
            lifeTime_ -= manager.timeStep;
        }
}

/**
 * Base class for particle system factories.
 *
 * Params:  owner    = Actor to attach produced particle system to.
 *                     If null, the particle system will be independent.
 *                     Default; null 
 *          lifeTime = Life time of the produced system. 
 *                     If negative, lifetime is indefinite.
 *                     Default; -1.0
 */                          
abstract class ParticleSystemFactory(T) : ActorFactory!T
{
    mixin(generateFactory("Actor $ owner $ null",
                           "real $ lifeTime $ -1.0"));
}
