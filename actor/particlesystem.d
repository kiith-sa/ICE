module actor.particlesystem;


import std.string;
import std.random;
import std.math;

import actor.actormanager;
import video.videodriver;
import math.math;
import math.vector2;
import color;
import timer;
import util;

///Base class for particle systems.
abstract class ParticleSystem : Actor
{
    protected:
        //Time left for this system to live. 
        //If negative, particle system can exist indefinitely.
        real LifeTime = -1.0;

        Actor Owner = null;

    public:
        ///Set time left for this LineTrail to live. Negative means infinite.
        void life_time(real time)
        {
            LifeTime = time;
        }

        void update()
        {
            real frame_length = ActorManager.get.frame_length;
            //If LifeTime reaches zero, destroy this 
            if(LifeTime >= 0.0 && LifeTime - frame_length <= 0.0)
            {
                die();
            }
            LifeTime -= frame_length;
        }

        void detach()
        {
            Owner = null;
        }

    protected:
        //Construct Actor with specified properties.
        this(Vector2f position, Vector2f velocity = Vector2f(0.0, 0.0),
             Actor owner = null,
             real life_time = -1.0) 
        {
            super(position, velocity);
            LifeTime = life_time;
            Owner = owner;
        }
}

///Single particle of the particle system
private struct Particle
{
    //Timer of the particle, determines its lifetime.
    Timer timer;
    Vector2f position;
    Vector2f velocity;
    
    //Update state of the particle.
    void update()
    {
        position += velocity * ActorManager.get.frame_length;
    }
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
                Position = next_position(Owner);
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
        void particle_life(real life)
        {
            ParticleLife = life;
        }

        ///Set number of particles to emit per second.
        void emit_frequency(real frequency)
        {
            EmitFrequency = frequency;
            //Reset emit counters
            TotalEmitted = 0;
            EmitStart = ActorManager.get.frame_time;
        }

        ///Set velocity to emit particles at.
        void emit_velocity(Vector2f velocity)
        {
            EmitVelocity = velocity;
        }

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

///Particle emitter that emits lines.
class LineEmitter : ParticleEmitter
{
    invariant
    {
        assert(LineLength > 0.0, "LineEmitter line length must be more than 0");
        assert(LineWidth > 0.0, "LineEmitter line width must be more than 0");
    }

    protected:
        //Length of line particles drawn.
        float LineLength = 8.0;
        //Width of line particles drawn.
        uint LineWidth = 2;
        //Color of particles at the beginning of their life.
        Color StartColor = Color(255, 255, 255, 255);
        //Color of particles at the end of their life.
        Color EndColor = Color(255, 255, 255, 0);

    public:
        this(Actor owner = null)
        {
            super(owner);
        }

        override void draw()
        {
            auto driver = VideoDriver.get;
            driver.line_aa = true;
            driver.line_width = LineWidth;
            real time = ActorManager.get.frame_time;
            Color color;
            //draw particles
            foreach(ref p; Particles)
            {
                color = EndColor.interpolated(StartColor, p.timer.age_relative(time));
                //determine line from particle velocity
                driver.draw_line(p.position, 
                                 p.position + p.velocity.normalized * LineLength, 
                                 color, color);
            }
            driver.line_width = 1;
            driver.line_aa = false;
        }

        ///Set length of the line particles drawn.
        void line_length(real length)
        {
            LineLength = length;
        }

        ///Set width of the line particles drawn.
        void line_width(uint width)
        {
            LineWidth = width;
        }

        ///Set color the particles have at the beginning of their lifetimes.
        void start_color(Color color)
        {
            StartColor = color;
        }

        ///Set color the particles have at the end of their lifetimes.
        void end_color(Color color)
        {
            EndColor = color;
        }
}

///Line trail particle system (trail following moving objects). Needs an owner to work.
class LineTrail : LineEmitter
{
    private:
        //determines when it's time to update 
        Timer UpdateTimer;

    public:
        /**
         * Construct a LineTrail with specifed parameters.
         * If attached to an owner, must be detached.
         *
         * Params:    position   = Starting position of the trail.
         *            trail_time = Delay between front and end of the tail.
         *            start      = Color of start of the trail.
         *            end        = Color of end of the trail.
         *            width      = Width of the trail.
         *            owner      = Owner of the trail. LineTrail must have an owner to work properly.
         */
        this(Actor owner = null)
        {
            assert(owner !is null, "A LineTrail must be constructed with an owner");

            super(owner);

            real time = ActorManager.get.frame_time;
            
            emit_frequency(100.0);
            UpdateTimer(1.0 / EmitFrequency, time);   
        }
        
        override void emit_frequency(real frequency)
        {
            assert(frequency >= 0.0, "LineTrail emit frequency must be > 0");

            EmitFrequency = frequency;
        }
        
        ///Draw the particle system.
        override void draw()
        {
            if(Particles.length >= 2)
            {
                //start of the current line
                Vector2f v1 = Particles[0].position;
                //end of the current line
                Vector2f v2;
                //start color of the current line
                Color c1 = EndColor;
                //end color of the current line
                Color c2;
                real time = ActorManager.get.frame_time;

                VideoDriver.get.line_aa = true;
                VideoDriver.get.line_width = LineWidth;
                foreach(ref particle; Particles[1 .. $])
                {
                    v2 = particle.position;
                    c2 = EndColor.interpolated(StartColor, 
                         particle.timer.age_relative(time));
                    VideoDriver.get.draw_line(v1, v2, c1, c2);
                    v1 = v2;
                    c1 = c2;
                }
                VideoDriver.get.line_width = 1;
                VideoDriver.get.line_aa = false;
            }
        }

    protected:
        //Emit particles if any should be emitted this frame.
        override void emit()
        {
            if(Owner)
            {
                real time = ActorManager.get.frame_time;
                if(UpdateTimer.expired(time))
                {
                    Particle trail;
                    trail.position = next_position(Owner);
                    trail.timer(ParticleLife, time);
                    Particles ~= trail;

                    UpdateTimer(1.0 / EmitFrequency, time);
                }
            }
        }
}      
