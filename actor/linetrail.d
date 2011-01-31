module actor.linetrail;


import std.math;

import actor.actor;
import actor.actorcontainer;
import actor.particleemitter;
import actor.lineemitter;
import physics.physicsbody;
import video.videodriver;
import math.math;
import math.vector2;
import time.timer;
import color;
import arrayutil;


///Line trail particle system (trail following moving objects). Needs an owner to work.
final class LineTrail : LineEmitter
{
    private:
        //determines when it's time to update 
        Timer update_timer_;

    public:
        override void emit_frequency(real frequency)
        {
            assert(frequency >= 0.0, "LineTrail emit frequency must be > 0");
            super.emit_frequency(frequency);
        } 

    protected:
        /*
         * Construct a LineTrail with specified parameters.
         *
         * Params:  container       = Container to manage the trail.
         *          physics_body    = Physics body of the trail.
         *          owner           = Class to attach this trail to. 
         *                            If null, the trail is independent.
         *          life_time       = Life time of the trail. 
         *                            If negative, lifetime is indefinite.
         *          particle_life   = Life time of particles emitted.
         *          emit_frequency  = Frequency at which to emit particles, 
         *                            in particles per second.
         *          line_width      = Width of lines emitted in pixels.
         *          start_color     = Color at the beginning of particle lifetime.
         *          end_color       = Color at the end of particle lifetime.  
         *          emit_velocity   = Not valid (fix with particle system overhaul).
         *          angle_variation = Not valid (fix with particle system overhaul).
         */                          
        this(ActorContainer container, PhysicsBody physics_body, Actor owner, 
             real life_time, real particle_life, real emit_frequency, 
             Vector2f emit_velocity, real angle_variation, 
             float line_width, Color start_color, Color end_color)
        {
            super(container, physics_body, owner, life_time, particle_life,
                  emit_frequency, emit_velocity, angle_variation,
                  1.0f, line_width, start_color, end_color);
        }

        override void emit(real time_step)
        {
            if(update_timer_.expired(game_time_))
            {
                Particle trail;
                trail.position = owner_ is null ? physics_body_.position 
                                                : owner_.position;
                trail.timer = Timer(particle_life, game_time_);
                Particles ~= trail;

                update_timer_ = Timer(1.0 / super.emit_frequency, game_time_);
            }
        }
        
        ///Draw the particle system.
        override void draw(VideoDriver driver)
        {
            if(Particles.length >= 2)
            {
                //start of the current line
                Vector2f v1 = Particles[0].position;
                //end of the current line
                Vector2f v2;
                //start color of the current line
                Color c1 = end_color_;
                //end color of the current line
                Color c2;

                driver.line_aa = true;
                driver.line_width = line_width_;

                //using for instead of foreach purely for performance reasons
                for(uint p = 1; p < Particles.length; p++)
                {
                    v2 = Particles[p].position;
                    c2 = end_color_.interpolated(start_color_, 
                         Particles[p].timer.age_relative(game_time_));
                    driver.draw_line(v1, v2, c1, c2);
                    v1 = v2;
                    c1 = c2;
                }
                driver.line_width = 1;
                driver.line_aa = false;
            }
        }
}      

///Factory used to produce line trails.
class LineTrailFactory : LineEmitterFactoryBase!(LineTrail)
{
    public override LineTrail produce(ActorContainer container)
    {                                                      
        return new LineTrail(container, physics_body, owner_, life_time_,
                             particle_life_, emit_frequency_, emit_velocity_, 
                             angle_variation_, line_width_, start_color_, end_color_);
    }
}
