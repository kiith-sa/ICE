
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module scene.particleemitter;


import std.random;
import std.math;

import scene.actor;
import scene.actorcontainer;
import scene.particlesystem;
import physics.physicsbody;
import math.math;
import math.vector2;
import time.timer;
import containers.array;
import util.factory;
import containers.vector;


///Single particle of a particle system.
private struct Particle
{
    ///Timer determining life time of the particle.
    Timer timer;
    ///Position of the particle in world space.
    Vector2f position;
    ///Velocity of the particle in world space.
    Vector2f velocity;
    
    /**
     * Update the particle.
     *
     * Params:  time_step = Time step of the update.
     */
    void update(real time_step){position += velocity * time_step;}
}

///Base class for particle emitters.
abstract class ParticleEmitter : ParticleSystem
{
    invariant
    {
        assert(particle_life_ > 0.0, "Lifetime of particles emitted must be > 0");
        assert(emit_frequency_ >= 0.0, "Particle emit frequency must not be negative");
        assert(angle_variation_ >= 0.0, "Particle angle variation must not be negative");
    }

    private:
        ///Lifetime of particles emitted.
        real particle_life_ = 5.0;
        ///Time since the last particle was emitted.
        real time_accumulated_ = 0.0;
        ///Variation of angles of particles' velocities (in radians).
        real angle_variation_ = PI / 2;
        ///Emit frequency in particles per second.
        real emit_frequency_ = 10.0;

    protected:
        ///Particles in the system.
        Vector!(Particle) particles_;

        ///Velocity to emit particles at.
        Vector2f emit_velocity_ = Vector2f(1.0, 0.0);
        ///Current game time.
        real game_time_;

    public:
        ///Set life time of particles emitted.
        final void particle_life(real life){particle_life_ = life;}
        
        ///Get life time of particles emitted.
        final real particle_life(){return particle_life_;}

        ///Set number of particles to emit per second.
        void emit_frequency(real frequency){emit_frequency_ = frequency;}
        
        ///Get number of particles emitted per second.
        final real emit_frequency(){return emit_frequency_;}

        ///Set velocity to emit particles at.
        final void emit_velocity(Vector2f velocity){emit_velocity_ = velocity;}

        ///Set angle variation of particles emitted in radians.
        final void angle_variation(real variation){angle_variation_ = variation;}

        override void die()
        {
            particles_.die();
            super.die();
        }

    protected:
        /**
         * Construct a ParticleEmitter with specified parameters.
         *
         * Params:  container       = Actor container to manage the emitter.
         *          physics_body    = Physics body of the emitter.
         *          owner           = Class to attach the emitter to. 
         *                            If null, the emitter is independent.
         *          life_time       = Life time of the emitter. 
         *                            If negative, lifetime is indefinite.
         *          particle_life   = Life time of particles emitted.
         *          emit_frequency  = Frequency to emit particles at in particles per second.
         *          emit_velocity   = Base velocity of particles emitted.
         *          angle_variation = Variation of angle of emit velocity in radians.
         */                          
        this(ActorContainer container, PhysicsBody physics_body, Actor owner, 
             real life_time, real particle_life, real emit_frequency, 
             Vector2f emit_velocity, real angle_variation)
        {
            particle_life_ = particle_life;
            emit_frequency_ = emit_frequency;
            angle_variation_ = angle_variation;
            emit_velocity_ = emit_velocity;
            particles_ = Vector!(Particle)();

            super(container, physics_body, owner, life_time);
        }

        override void update(real time_step, real game_time)
        {
            //if attached, get position from the owner.
            if(owner_ !is null){physics_body_.position = owner_.position;}

            game_time_ = game_time;

            //remove expired particles
            bool expired(ref Particle particle){return particle.timer.expired(game_time);}
            particles_.remove(&expired);

            //emit new particles
            emit(time_step);

            //update particles
            foreach(ref particle; particles_){particle.update(time_step);}

            super.update(time_step, game_time);
        }

        /**
         * Emit particles if any should be emitted this frame.
         * 
         * Params:  time_step = Time step in seconds.
         */
        void emit(real time_step)
        {
            time_accumulated_ += time_step;
            if(equals(emit_frequency_, 0.0L)){return;}
            real emit_period = 1.0 / emit_frequency_;
            while(time_accumulated_ >= emit_period)
            {
                //add a new particle
                Particle particle;
                with(particle)
                {
                    timer = Timer(particle_life_, game_time_);
                    position = physics_body_.position;
                    velocity = emit_velocity_;
                    velocity.angle = particle.velocity.angle + 
                                     random(-angle_variation_, angle_variation_);
                }
                particles_ ~= particle;

                time_accumulated_ -= emit_period;
            }
        }
}

/**
 * Base class for factories producing ParticleEmitter derived classes.
 *
 * Params:  particle_life   = Life time of particles emitted in seconds.
 *                            Default; 5.0
 *          emit_frequency  = Frequency to emit particles at in particles per second.
 *                            Default; 10.0
 *          emit_velocity   = Base velocity of particles emitted.
 *                            Default; Vector2f(1.0f, 1.0f)
 *          angle_variation = Variation of angle of emit velocity in radians.
 *                            Default; PI / 2
 */                          
abstract class ParticleEmitterFactory(T) : ParticleSystemFactory!(T)
{
    mixin(generate_factory("real $ particle_life $ 5.0",
                           "real $ emit_frequency $ 10.0",
                           "Vector2f $ emit_velocity $ Vector2f(1.0f, 1.0f)",
                           "real $ angle_variation $ PI / 2"));
}
