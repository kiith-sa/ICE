module actor.particleemitter;


import std.random;
import std.math;

import actor.actor;
import actor.actormanager;
import actor.particlesystem;
import physics.physicsbody;
import math.math;
import math.vector2;
import time.timer;
import arrayutil;


///Single particle of the particle system
private struct Particle
{
    //Timer of the particle, determines its lifetime.
    Timer timer;
    Vector2f position;
    Vector2f velocity;
    
    //Update state of the particle.
    void update(real time_step){position += velocity * time_step;}
}

///Base class for particle emitting particle systems.
abstract class ParticleEmitter : ParticleSystem
{
    invariant
    {
        assert(particle_life_ > 0.0, "Lifetime of particles emitted must be > 0");
        assert(emit_frequency_ >= 0.0, "Particle emit frequency must not be negative");
        assert(angle_variation_ >= 0.0, "Particle angle variation must not be negative");
    }

    private:
        //Lifetime of particles emitted.
        real particle_life_ = 5.0;
        //Time since last particle was emit.
        real time_accumulated_ = 0.0;
        //Variation of the angle of particles velocities (in radians).
        real angle_variation_ = PI / 2;
        //Emit frequency in particles per second.
        real emit_frequency_ = 10.0;

    protected:
        Particle [] Particles;

        //Velocity to emit particles at.
        Vector2f emit_velocity_ = Vector2f(1.0, 0.0);
        //Current game time.
        real game_time_;

    public:
        ///Constructor. If attached to an owner, must be detached.
        this(Actor owner = null)
        {
            super(new PhysicsBody(null, Vector2f(0.0f, 0.0f), Vector2f(0.0f, 0.0f), 2.0),
                  owner);
        }
        
        override void update(real time_step, real game_time)
        {
            //update position
            if(owner_ !is null)
            {
                //get position from owner
                physics_body_.position = owner_.position;
            }

            game_time_ = game_time;

            //remove expired particles
            bool expired(ref Particle particle){return particle.timer.expired(game_time);}
            Particles.remove(&expired);

            //emit new particles
            emit(time_step);

            //update particles
            foreach(ref particle; Particles){particle.update(time_step);}

            super.update(time_step, game_time);
        }

        ///Set life time of particles emitted.
        final void particle_life(real life){particle_life_ = life;}
        
        ///Return life time of particles emitted.
        final real particle_life(){return particle_life_;}

        ///Set number of particles to emit per second.
        void emit_frequency(real frequency){emit_frequency_ = frequency;}
        
        ///Return number of particles emitted per second.
        final real emit_frequency(){return emit_frequency_;}

        ///Set velocity to emit particles at.
        final void emit_velocity(Vector2f velocity){emit_velocity_ = velocity;}

        ///Set angle variation of particles emitted in radians.
        final void angle_variation(real variation){angle_variation_ = variation;}

    protected:
        /*
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
                Particle particle;

                particle.timer = Timer(particle_life_, game_time_);
                particle.position = physics_body_.position;
                real angle_delta = random(-angle_variation_, angle_variation_);
                particle.velocity = emit_velocity_;
                particle.velocity.angle = particle.velocity.angle + angle_delta;

                Particles ~= particle;

                time_accumulated_ -= emit_period;
            }
        }
}
