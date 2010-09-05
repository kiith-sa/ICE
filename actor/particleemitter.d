module actor.particleemitter;


import std.random;
import std.math;

import actor.actor;
import actor.actormanager;
import actor.particlesystem;
import math.math;
import math.vector2;
import timer;
import util;


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
        assert(ParticleLife > 0.0, "Lifetime of particles emitted must be > 0");
        assert(EmitFrequency >= 0.0, "Particle emit frequency must not be negative");
        assert(AngleVariation >= 0.0, "Particle angle variation must not be negative");
    }

    private:
        //Lifetime of particles emitted.
        real ParticleLife = 5.0;
        //Total particles emitted since EmitStart
        ulong TotalEmitted = 0;
        //Time when EmitFrequency was changed last.
        real EmitStart;
        //Velocity to emit particles at.
        Vector2f EmitVelocity = Vector2f(1.0, 0.0);
        //Variation of the angle of particles velocities (in radians).
        real AngleVariation = PI / 2;
        //Emit frequency in particles per second.
        real EmitFrequency = 10.0;

    protected:
        Particle [] Particles;

    public:
        ///Constructor. If attached to an owner, must be detached.
        this(Actor owner = null)
        {
            super(Vector2f(0.0f,0.0f), Vector2f(0.0f,0.0f), owner);
            EmitStart = ActorManager.get.frame_time;
        }
        
        override void update()
        {
            real frame_length = ActorManager.get.frame_length;

            //update position
            if(Owner !is null)
            {
                //get position from owner
                Position = Owner.next_position;
            }
            else
            {
                //update position normally (don't need update_physics since
                //we don't collide with anything)
                Position += Velocity * frame_length;
            }

            //remove expired particles
            bool expired(ref Particle particle)
            {return particle.timer.expired(ActorManager.get.frame_time);}
            Particles.remove(&expired);

            //emit new particles
            emit();

            //update particles
            foreach(ref particle; Particles)
            {
                particle.update();
            }

            super.update();
        }

        ///Set life time of particles emitted.
        void particle_life(real life){ParticleLife = life;}
        
        ///Return life time of particles emitted.
        real particle_life(){return ParticleLife;}

        ///Set number of particles to emit per second.
        void emit_frequency(real frequency)
        {
            EmitFrequency = frequency;
            //Reset emit counters
            TotalEmitted = 0;
            EmitStart = ActorManager.get.frame_time;
        }
        
        ///Return number of particles emitted per second.
        real emit_frequency(){return EmitFrequency;}

        ///Set velocity to emit particles at.
        void emit_velocity(Vector2f velocity){EmitVelocity = velocity;}

        ///Set angle variation of particles emitted in radians.
        void angle_variation(real variation)
        {
            AngleVariation = variation;
        }

    protected:
        //Emit particles if any should be emitted this frame.
        void emit()
        {
            real time = ActorManager.get.frame_time;
            //Total number of particles that should be emitted by now
            uint particles_needed = round32((time - EmitStart) * EmitFrequency);
            //Particles to emit (using int for error checking)
            int particles = particles_needed - TotalEmitted;
            assert(particles >= 0, "Can't emit negative number of particles");

            //Emit particles, if any
            for(uint p = 0; p < particles; ++p)
            {
                Particle particle;

                particle.timer(ParticleLife, time);
                particle.position = Position;
                real angle_delta = random(-AngleVariation, AngleVariation);
                particle.velocity = EmitVelocity;
                particle.velocity.angle = particle.velocity.angle + angle_delta;

                Particles ~= particle;
            }

            TotalEmitted += particles;
        }
}
