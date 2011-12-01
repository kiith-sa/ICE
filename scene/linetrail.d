
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Line trail particle system.
module scene.linetrail;
@safe


import std.math;

import scene.actor;
import scene.lineemitter;
import scene.particleemitter;
import scene.scenemanager;
import physics.physicsbody;
import video.videodriver;
import math.math;
import math.vector2;
import time.timer;
import color;


//This is a huge mess, but waiting for complete particle system overhaul to fix it.
///Line trail particle system (trail following moving objects). Needs an owner to work.
final class LineTrail : LineEmitter
{
    private:
        ///Determines when it's time to update.
        Timer update_timer_;

    protected:
        /**
         * Construct a LineTrail with specified parameters.
         *
         * Params:  physics_body    = Physics body of the trail.
         *          owner           = Class to attach the trail to. 
         *                            If null, the trail is independent.
         *          life_time       = Life time of the trail in seconds. 
         *                            If negative, lifetime is indefinite.
         *          particle_life   = Life time of particles emitted.
         *          emit_frequency  = Frequency to emit particles at in particles per second.
         *          line_width      = Width of lines emitted in pixels.
         *          start_color     = Color at the beginning of particle lifetime.
         *          end_color       = Color at the end of particle lifetime.  
         *          emit_velocity   = Not valid (fix with particle system overhaul).
         *          angle_variation = Not valid (fix with particle system overhaul).
         */                          
        this(PhysicsBody physics_body, Actor owner, 
             in real life_time, in real particle_life, in real emit_frequency, 
             in Vector2f emit_velocity, in real angle_variation, 
             in float line_width, in Color start_color, in Color end_color)
        {
            super(physics_body, owner, life_time, particle_life,
                  emit_frequency, emit_velocity, angle_variation,
                  1.0f, line_width, start_color, end_color);
        }

        override void emit(in real time_step)
        {
            if(update_timer_.expired(game_time_))
            {
                Particle trail;
                trail.position = owner_ is null ? physics_body_.position : owner_.position;
                trail.timer = Timer(particle_life, game_time_);
                particles_ ~= trail;

                update_timer_ = Timer(1.0 / super.emit_frequency, game_time_);
            }
        }
        
        override void draw(VideoDriver driver)
        {
            //trail with just one point makes no sense, need at least two
            if(particles_.length >= 2)
            {
                //start of the current line
                Vector2f v1 = particles_[0].position;
                //end of the current line
                Vector2f v2;
                //start color of the current line
                Color c1 = end_color_;
                //end color of the current line
                Color c2;

                driver.line_aa = true;
                driver.line_width = line_width_;

                //using for instead of foreach for performance reasons
                foreach(p; 1 .. particles_.length)
                {
                    v2 = particles_[p].position;
                    c2 = end_color_.interpolated(start_color_, 
                         particles_[p].timer.age_relative(game_time_));
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
class LineTrailFactory : LineEmitterFactoryBase!LineTrail
{
    public override LineTrail produce(SceneManager manager)
    {                                                      
        return new_actor(manager, 
                         new LineTrail(physics_body, owner_, life_time_, particle_life_,
                                       emit_frequency_, emit_velocity_, angle_variation_, 
                                       line_width_, start_color_, end_color_));
    }
}
