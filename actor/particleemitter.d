module actor.particleemitter;


import std.random;
import std.math;

import actor.actor;
import actor.actormanager;
import actor.particlesystem;
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
    void update(){position += velocity * ActorManager.get.frame_length;}
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
        //Total particles emitted since emit_start_
        ulong total_emitted_ = 0;
        //Time when emit_frequency_ was changed last.
        real emit_start_;
        //Velocity to emit particles at.
        Vector2f emit_velocity_ = Vector2f(1.0, 0.0);
        //Variation of the angle of particles velocities (in radians).
        real angle_variation_ = PI / 2;
        //Emit frequency in particles per second.
        real emit_frequency_ = 10.0;

    protected:
        Particle [] Particles;

    public:
        ///Constructor. If attached to an owner, must be detached.
        this(Actor owner = null)
        {
            super(Vector2f(0.0f,0.0f), Vector2f(0.0f,0.0f), owner);
            emit_start_ = ActorManager.get.frame_time;
        }
        
        override void update()
        {
            real frame_length = ActorManager.get.frame_length;

            //update position
            if(owner_ !is null)
            {
                //get position from owner
                position_ = owner_.next_position;
            }
            else
            {
                //update position normally (don't need update_physics since
                //we don't collide with anything)
                position_ += velocity_ * frame_length;
            }

            //remove expired particles
            real time = ActorManager.get.frame_time;
            bool expired(ref Particle particle){return particle.timer.expired(time);}
            Particles.remove(&expired);

            //emit new particles
            emit();

            //update particles
            foreach(ref particle; Particles){particle.update();}

            super.update();
        }

        ///Set life time of particles emitted.
        final void particle_life(real life){particle_life_ = life;}
        
        ///Return life time of particles emitted.
        final real particle_life(){return particle_life_;}

        ///Set number of particles to emit per second.
        void emit_frequency(real frequency)
        {
            emit_frequency_ = frequency;
            //Reset emit counters
            total_emitted_ = 0;
            emit_start_ = ActorManager.get.frame_time;
        }
        
        ///Return number of particles emitted per second.
        final real emit_frequency(){return emit_frequency_;}

        ///Set velocity to emit particles at.
        final void emit_velocity(Vector2f velocity){emit_velocity_ = velocity;}

        ///Set angle variation of particles emitted in radians.
        final void angle_variation(real variation){angle_variation_ = variation;}

    protected:
        //Emit particles if any should be emitted this frame.
        void emit()
        {
            real time = ActorManager.get.frame_time;
            //Total number of particles that should be emitted by now
            uint particles_needed = round32((time - emit_start_) * emit_frequency_);
            //Particles to emit (using int for error checking)
            int particles = particles_needed - total_emitted_;
            assert(particles >= 0, "Can't emit negative number of particles");

            //Emit particles, if any
            for(uint p = 0; p < particles; ++p)
            {
                Particle particle;

                particle.timer = Timer(particle_life_, time);
                particle.position = position_;
                real angle_delta = random(-angle_variation_, angle_variation_);
                particle.velocity = emit_velocity_;
                particle.velocity.angle = particle.velocity.angle + angle_delta;

                Particles ~= particle;
            }

            total_emitted_ += particles;
        }
}
