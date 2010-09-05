module actor.linetrail;


import std.math;

import actor.actor;
import actor.actormanager;
import actor.particleemitter;
import actor.lineemitter;
import video.videodriver;
import math.math;
import math.vector2;
import color;
import timer;
import arrayutil;


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
            UpdateTimer(1.0 / super.emit_frequency, time);   
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
                    trail.position = Owner.next_position;
                    trail.timer(particle_life, time);
                    Particles ~= trail;

                    UpdateTimer(1.0 / super.emit_frequency, time);
                }
            }
        }
}      
