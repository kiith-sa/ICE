
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Line emitter particle system.
module scene.lineemitter;


import std.math;

import scene.actor;
import scene.particleemitter;
import scene.scenemanager;
import physics.physicsbody;
import video.videodriver;
import math.vector2;
import color;
import util.factory;


/**
 * Particle emitter that emits lines.
 *
 * Emitted particles gradually blend color during their lifetime,
 * from specified start color to specified end color.
 */
class LineEmitter : ParticleEmitter
{
    invariant()
    {
        assert(lineLength_ > 0.0, "LineEmitter line length must be greater than 0");
        assert(lineWidth_ > 0.0, "LineEmitter line width must be greater than 0");
        assert(emitVelocity_ != Vector2f(0.0, 0.0), "Can't emit particles with zero velocity");
    }

    protected:
        ///Length of line particles.
        float lineLength_ = 8.0f;
        ///Width of line particles.
        float lineWidth_  = 2.0f;
        ///Color of particles at the beginning of their life.
        Color startColor_ = Color.white;
        ///Color of particles at the end of their life.
        Color endColor_   = rgba!"FFFFFF00";

    public:
        ///Set length of the line particles.
        @property final void lineLength(const float length) pure {lineLength_ = length;}

        ///Set width of the line particles.
        @property final void lineWidth(const float width) pure {lineWidth_ = width;}

        ///Set color the particles have at the beginning of their lifetimes.
        @property final void startColor(const Color color) pure {startColor_ = color;}

        ///Set color the particles have at the end of their lifetimes.
        @property final void endColor(const Color color) pure {endColor_ = color;}

    protected:
        /**
         * Construct a LineEmitter.
         *
         * Params:  physicsBody    = Physics body of the emitter.
         *          owner           = Actor to attach the emitter to. 
         *                            If null, the emitter is independent.
         *          lifeTime       = Life time of the emitter in seconds. 
         *                            If negative, lifetime is indefinite.
         *          particleLife   = Life time of particles emitted.
         *          emitFrequency  = Frequency to emit particles at in particles per second.
         *          emitVelocity   = Base velocity of particles emitted.
         *          angleVariation = Variation of angle of emit velocity in radians.
         *          lineLength     = Length of lines emitted in pixels.
         *          lineWidth      = Width of lines emitted in pixels.
         *          startColor     = Color at the beginning of particle lifetime.
         *          endColor       = Color at the end of particle lifetime.  
         */                          
        this(PhysicsBody physicsBody, Actor owner, 
             const real lifeTime, const real particleLife, const real emitFrequency, 
             const Vector2f emitVelocity, const real angleVariation, const float lineLength, 
             const float lineWidth, const Color startColor, const Color endColor)
        {
            lineLength_ = lineLength;
            lineWidth_  = lineWidth;
            startColor_ = startColor;
            endColor_   = endColor;
            super(physicsBody, owner, lifeTime, particleLife,
                  emitFrequency, emitVelocity, angleVariation);
        }

        override void draw(VideoDriver driver)
        {
            driver.lineAA = true;
            driver.lineWidth = lineWidth_;
            Color color;
            //draw particles
            foreach(ref p; particles_)
            {
                color = endColor_.interpolated(startColor_, p.timer.ageRelative(gameTime_));
                //determine line from particle velocity
                //note that we assume that particle velocity is never zero,
                //otherwise normalization would break
                driver.drawLine(p.position, p.position + p.velocity.normalized * lineLength_,
                                 color, color);
            }
            driver.lineWidth = 1.0f;
            driver.lineAA = false;
        }
}

/**
 * Base class for factories producing LineEmitter or derived classes.
 *
 * Params:  lineWidth  = Width of lines emitted in pixels.
 *                        Default; 1.0
 *          startColor = Color at the beginning of particle lifetime. 
 *                        Default; Color.white
 *          endColor   = Color at the end of particle lifetime. 
 *                        Default; Color.black
 */
abstract class LineEmitterFactoryBase(T) : ParticleEmitterFactory!T
{
    mixin(generateFactory("float $ lineWidth $ 1",
                           "Color $ startColor $ Color.white",
                           "Color $ endColor $ Color.black"));
    ///Return physics body constructed from factory parameters. Used by produce().
    protected PhysicsBody physicsBody()
    {
        return new PhysicsBody(null, position_, velocity_, 10.0);
    }
}

/**
 * Factory producing line emitters.
 *
 * Params:  lineLength = Length of the lines emitted in pixels.
 *                        Default; 5.0
 */
class LineEmitterFactory : LineEmitterFactoryBase!(LineEmitter)
{
    mixin(generateFactory("float $ lineLength $ 5.0"));

    public override LineEmitter produce(SceneManager manager)
    {
        return newActor(manager, 
                        new LineEmitter(physicsBody, owner_, lifeTime_,
                                        particleLife_, emitFrequency_, emitVelocity_, 
                                        angleVariation_, lineLength_, lineWidth_, 
                                        startColor_, endColor_));
    }
}
