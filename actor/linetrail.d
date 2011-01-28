module actor.linetrail;


import std.math;

import actor.actor;
import actor.actormanager;
import actor.particleemitter;
import actor.lineemitter;
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
        /**
         * Construct a LineTrail with specifed parameters.
         * If attached to an owner, must be detached.
         *
         * Params:    owner      = Owner of the trail. LineTrail must have an owner to work properly.
         */
        this(Actor owner = null)
        {
            assert(owner !is null, "A LineTrail must be constructed with an owner");

            super(owner);

            emit_frequency(100.0);

            //this will expire and be reset at first emit call.
            update_timer_ = Timer(0.0, 0.0);   
        }

        override void emit_frequency(real frequency)
        {
            assert(frequency >= 0.0, "LineTrail emit frequency must be > 0");
            super.emit_frequency(frequency);
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
                Color c1 = end_color_;
                //end color of the current line
                Color c2;

                VideoDriver.get.line_aa = true;
                VideoDriver.get.line_width = line_width_;

                //using for instead of foreach purely for performance reasons
                for(uint p = 1; p < Particles.length; p++)
                {
                    v2 = Particles[p].position;
                    c2 = end_color_.interpolated(start_color_, 
                         Particles[p].timer.age_relative(game_time_));
                    VideoDriver.get.draw_line(v1, v2, c1, c2);
                    v1 = v2;
                    c1 = c2;
                }
                VideoDriver.get.line_width = 1;
                VideoDriver.get.line_aa = false;
            }
        }

    protected:
        override void emit(real time_step)
        {
            if(owner_)
            {
                if(update_timer_.expired(game_time_))
                {
                    Particle trail;
                    trail.position = owner_.position;
                    trail.timer = Timer(particle_life, game_time_);
                    Particles ~= trail;

                    update_timer_ = Timer(1.0 / super.emit_frequency, game_time_);
                }
            }
        }
}      
