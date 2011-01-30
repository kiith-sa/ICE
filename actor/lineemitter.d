module actor.lineemitter;


import std.math;

import actor.actor;
import actor.actorcontainer;
import actor.particleemitter;
import physics.physicsbody;
import video.videodriver;
import math.vector2;
import color;
import factory;


///Particle emitter that emits lines.
class LineEmitter : ParticleEmitter
{
    invariant
    {
        assert(line_length_ > 0.0, "LineEmitter line length must be more than 0");
        assert(line_width_ > 0.0, "LineEmitter line width must be more than 0");
        assert(emit_velocity_ != Vector2f(0.0, 0.0), 
               "Can't emit line particles with zero velocity");
    }

    protected:
        //Length of line particles drawn.
        float line_length_ = 8.0f;
        //Width of line particles drawn.
        float line_width_ = 2.0f;
        //Color of particles at the beginning of their life.
        Color start_color_ = Color.white;
        //Color of particles at the end of their life.
        Color end_color_ = Color(255, 255, 255, 0);

    public:
        ///Set length of the line particles drawn.
        final void line_length(float length){line_length_ = length;}

        ///Set width of the line particles drawn.
        final void line_width(float width){line_width_ = width;}

        ///Set color the particles have at the beginning of their lifetimes.
        final void start_color(Color color){start_color_ = color;}

        ///Set color the particles have at the end of their lifetimes.
        final void end_color(Color color){end_color_ = color;}

    protected:
        /*
         * Construct a LineEmitter with specified parameters.
         *
         * Params:  container       = Container to manage the emitter.
         *          physics_body    = Physics body of the emitter.
         *          owner           = Class to attach this emitter to. 
         *                            If null, the emitter is independent.
         *          life_time       = Life time of the emitter. 
         *                            If negative, lifetime is indefinite.
         *          particle_life   = Life time of particles emitted.
         *          emit_frequency  = Frequency at which to emit particles, 
         *                            in particles per second.
         *          emit_velocity   = Base velocity of particles emitted.
         *          angle_variation = Variation of angle of emit velocity, in radians.
         *          line_length     = Length of lines emitted in pixels.
         *          line_width      = Width of lines emitted in pixels.
         *          start_color     = Color at the beginning of particle lifetime.
         *          end_color       = Color at the end of particle lifetime.  
         */                          
        this(ActorContainer container, PhysicsBody physics_body, Actor owner, 
             real life_time, real particle_life, real emit_frequency, 
             Vector2f emit_velocity, real angle_variation, float line_length, 
             float line_width, Color start_color, Color end_color)
        {
            line_length_ = line_length;
            line_width_ = line_width;
            start_color_ = start_color;
            end_color_ = end_color;
            super(container, physics_body, owner, life_time, particle_life,
                  emit_frequency, emit_velocity, angle_variation);
        }

        override void draw()
        {
            auto driver = VideoDriver.get;
            driver.line_aa = true;
            driver.line_width = line_width_;
            Color color;
            //draw particles
            foreach(ref p; Particles)
            {
                color = end_color_.interpolated(start_color_, 
                                                p.timer.age_relative(game_time_));
                //determine line from particle velocity
                //note-we assume here that particle velocity is never zero,
                //otherwise normalization would break
                driver.draw_line(p.position, 
                                 p.position + p.velocity.normalized * line_length_, 
                                 color, color);
            }
            driver.line_width = 1.0f;
            driver.line_aa = false;
        }
}

/**
 * Base class for all factories producing LineEmitter or derived classes.
 *
 * Params:  line_width  = Width of lines emitted in pixels.
 *          start_color = Color at the beginning of particle lifetime. 
 *          end_color   = Color at the end of particle lifetime. 
 */
abstract class LineEmitterFactoryBase(T) : ParticleEmitterFactory!(T)
{
    mixin(generate_factory("float $ line_width $ 1",
                           "Color $ start_color $ Color.white",
                           "Color $ end_color $ Color.black"));
    //Return physics body constructed from factory parameters. Used by produce().
    protected PhysicsBody physics_body()
    {
        return new PhysicsBody(null, position_, velocity_, 10.0);
    }
}

/**
 * Factory producing line emitters.
 *
 * Params:  line_length = Length of the lines emitted in pixels.
 *                        Default: 5.0
 */
class LineEmitterFactory : LineEmitterFactoryBase!(LineEmitter)
{
    mixin(generate_factory("float $ line_length $ 5.0"));

    public override LineEmitter produce(ActorContainer container)
    {
        return new LineEmitter(container, physics_body, owner_, life_time_,
                               particle_life_, emit_frequency_, emit_velocity_, 
                               angle_variation_, line_length_, line_width_, 
                               start_color_, end_color_);
    }
}
