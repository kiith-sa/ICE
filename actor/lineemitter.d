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
        assert(line_length_ > 0.0, "LineEmitter line length must be more than 0");
        assert(line_width_ > 0.0, "LineEmitter line width must be more than 0");
        assert(emit_velocity_ != Vector2f(0.0, 0.0), 
               "Can't emit line particles with zero velocity");
    }

    protected:
        //Length of line particles drawn.
        float line_length_ = 8.0;
        //Width of line particles drawn.
        uint line_width_ = 2;
        //Color of particles at the beginning of their life.
        Color start_color_ = Color.white;
        //Color of particles at the end of their life.
        Color end_color_ = Color(255, 255, 255, 0);

    public:
        this(Actor owner = null){super(owner);}

        override void draw()
        {
            auto driver = VideoDriver.get;
            driver.line_aa = true;
            driver.line_width = line_width_;
            real time = ActorManager.get.game_time;
            Color color;
            //draw particles
            foreach(ref p; Particles)
            {
                color = end_color_.interpolated(start_color_, p.timer.age_relative(time));
                //determine line from particle velocity
                //note-we assume here that particle velocity is never zero,
                //otherwise normalization would break
                driver.draw_line(p.position, 
                                 p.position + p.velocity.normalized * line_length_, 
                                 color, color);
            }
            driver.line_width = 1;
            driver.line_aa = false;
        }

        ///Set length of the line particles drawn.
        final void line_length(real length){line_length_ = length;}

        ///Set width of the line particles drawn.
        final void line_width(uint width){line_width_ = width;}

        ///Set color the particles have at the beginning of their lifetimes.
        final void start_color(Color color){start_color_ = color;}

        ///Set color the particles have at the end of their lifetimes.
        final void end_color(Color color){end_color_ = color;}
}
