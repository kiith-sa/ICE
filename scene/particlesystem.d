
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for all particle systems.
module scene.particlesystem;
@safe


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
        real life_time_;

    protected:
        ///Actor the particle system is attached to. If null, the system is independent.
        Actor owner_;

    public:
        ///Set time left for the LineTrail to live. Negative means infinite.
        final void life_time(in real time){life_time_ = time;}

        /**
         * Attach the particle system to specified actor.
         *
         * Params:  actor = Actor to attach to.
         */
        final void attach(Actor actor){owner_ = actor;}

        ///Detach the particle system from any actor it's attached to.
        final void detach(){owner_ = null;}

    protected:
        /**
         * Construct a ParticleSystem with specified parameters.
         *
         * Params:  physics_body    = Physics body of the system.
         *          owner           = Class to attach the system to. 
         *                            If null, the system is independent.
         *          life_time       = Life time of the system. 
         *                            If negative, lifetime is indefinite.
         */                          
        this(PhysicsBody physics_body, Actor owner, in real life_time)
        {
            life_time_ = life_time;
            owner_ = owner;
            super(physics_body);
        }

        override void update(SceneManager manager)
        {
            //If life_time_ reaches zero, destroy the system
            if(life_time_ >= 0.0 && life_time_ - manager.time_step <= 0.0)
            {
                die(manager.update_index);
            }
            life_time_ -= manager.time_step;
        }
}

/**
 * Base class for particle system factories.
 *
 * Params:  owner           = Actor to attach produced particle system to.
 *                            If null, the particle system will be independent.
 *                            Default; null 
 *          life_time       = Life time of the produced system. 
 *                            If negative, lifetime is indefinite.
 *                            Default; -1.0
 */                          
abstract class ParticleSystemFactory(T) : ActorFactory!T
{
    mixin(generate_factory("Actor $ owner $ null",
                           "real $ life_time $ -1.0"));
}
