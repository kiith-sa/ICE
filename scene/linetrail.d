
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Line trail particle system.
module scene.linetrail;


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
        Timer updateTimer_;

    protected:
        /**
         * Construct a LineTrail.
         *
         * Params:  physicsBody    = Physics body of the trail.
         *          owner           = Class to attach the trail to. 
         *                            If null, the trail is independent.
         *          lifeTime       = Life time of the trail in seconds. 
         *                            If negative, lifetime is indefinite.
         *          particleLife   = Life time of particles emitted.
         *          emitFrequency  = Frequency to emit particles at in particles per second.
         *          lineWidth      = Width of lines emitted in pixels.
         *          startColor     = Color at the beginning of particle lifetime.
         *          endColor       = Color at the end of particle lifetime.  
         *          emitVelocity   = Not valid (fix with particle system overhaul).
         *          angleVariation = Not valid (fix with particle system overhaul).
         */                          
        this(PhysicsBody physicsBody, Actor owner, 
             const real lifeTime, const real particleLife, const real emitFrequency, 
             const Vector2f emitVelocity, const real angleVariation, 
             const float lineWidth, const Color startColor, const Color endColor)
        {
            super(physicsBody, owner, lifeTime, particleLife,
                  emitFrequency, emitVelocity, angleVariation,
                  1.0f, lineWidth, startColor, endColor);
        }

        override void emit(const real timeStep)
        {
            if(updateTimer_.expired(gameTime_))
            {
                Particle trail;
                trail.position = owner_ is null ? physicsBody_.position : owner_.position;
                trail.timer = Timer(particleLife, gameTime_);
                particles_ ~= trail;

                updateTimer_ = Timer(1.0 / super.emitFrequency, gameTime_);
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
                Color c1 = endColor_;
                //end color of the current line
                Color c2;

                driver.lineAA = true;
                driver.lineWidth = lineWidth_;

                //using for instead of foreach for performance reasons
                foreach(p; 1 .. particles_.length)
                {
                    v2 = particles_[p].position;
                    c2 = endColor_.interpolated(startColor_, 
                         particles_[p].timer.ageRelative(gameTime_));
                    driver.drawLine(v1, v2, c1, c2);
                    v1 = v2;
                    c1 = c2;
                }
                driver.lineWidth = 1;
                driver.lineAA = false;
            }
        }
}      

///Factory used to produce line trails.
class LineTrailFactory : LineEmitterFactoryBase!LineTrail
{
    public override LineTrail produce(SceneManager manager)
    {                                                      
        return newActor(manager, 
                         new LineTrail(physicsBody, owner_, lifeTime_, particleLife_,
                                       emitFrequency_, emitVelocity_, angleVariation_, 
                                       lineWidth_, startColor_, endColor_));
    }
}
