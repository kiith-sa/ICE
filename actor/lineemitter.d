module actor.lineemitter;


import std.math;

import actor.actor;
import actor.actormanager;
import actor.particleemitter;
import video.videodriver;
import math.vector2;
import color;


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
