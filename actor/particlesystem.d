module actor.particlesystem;


import actor.actor;
import actor.actorcontainer;
import physics.physicsbody;
import math.vector2;
import factory;


///Base class for particle systems.
abstract class ParticleSystem : Actor
{
    private:
        //Time left for this system to live. 
        //If negative, particle system can exist indefinitely.
        real life_time_;

    protected:
        //Actor this particle system is attached to. If null, the system is independent.
        Actor owner_;

    public:
        ///Set time left for this LineTrail to live. Negative means infinite.
        final void life_time(real time){life_time_ = time;}

        override void update(real time_step, real game_time)
        {
            //If life_time_ reaches zero, destroy this 
            if(life_time_ >= 0.0 && life_time_ - time_step <= 0.0){die();}
            life_time_ -= time_step;
        }

        /**
         * Attach this particle system to specified actor.
         *
         * Params:  actor = Actor to attach to.
         */
        final void attach(Actor actor){owner_ = actor;}

        ///Detach this particle system from any actor it's attached to.
        final void detach(){owner_ = null;}

    protected:
        /*
         * Construct an Actor with specified parameters.
         *
         * Params:  container       = Container to manage the system.
         *          physics_body    = Physics body of the system.
         *          owner           = Class to attach this system to. 
         *                            If null, the system is independent.
         *          life_time       = Life time of the system. 
         *                            If negative, lifetime is indefinite.
         */                          
        this(ActorContainer container, PhysicsBody physics_body, Actor owner, 
             real life_time) 
        {
            life_time_ = life_time;
            owner_ = owner;
            super(container, physics_body);
        }
}

/*
 * Base class for particle system factories.
 *
 * Params:  owner           = Actor to attach produced particle system to.
 *                            If null, the particle system is independent.
 *                            Default: null 
 *          life_time       = Life time of the produced system.. 
 *                            If negative, lifetime is indefinite.
 *                            Default: -1.0
 */                          
abstract class ParticleSystemFactory(T) : ActorFactory!(T)
{
    mixin(generate_factory("Actor $ owner $ null",
                           "real $ life_time $ -1.0"));
}
