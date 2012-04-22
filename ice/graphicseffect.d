
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Procedural graphics effects.
module ice.graphicseffect;


import std.algorithm;
import std.random;

import color;
import math.math;
import math.rect;
import math.vector2;
import time.gametime;
import video.videodriver;
import util.signal;


/**
 * Base class for procedural graphics effects.
 *
 * These are usually used for various fullscreen effects that don't depend 
 * on game entities.
 *
 * Managed and drawn by GraphicsEffectManager.
 *
 * Signal:
 *     public mixin Signal!() onExpired
 *
 *     Emitted when the effect expires. 
 */
abstract class GraphicsEffect
{
    protected:
        ///Are we done drawing this effect?
        bool done_ = false;

    public:
        mixin Signal!() onExpired;

        /**
         * Draw the effect.
         *
         * Params:  video    = VideoDriver to draw the effect with.
         *          gameTime = Game time subsystem to get current time.
         */
        void draw(VideoDriver video, const GameTime gameTime);

    private:
        ///Are we done drawing this effect?
        final @property bool done() const pure nothrow {return done_;}

        ///Expire the effect, emitting the onExpired signal. Called before destruction.
        final void expire() {onExpired.emit();}
}

/**
 * Effect that draws horizontal lines at random Y coordinates.
 *
 * Effect parameters are specified each frame by a delegate.
 *
 * The delegate takes a real specifying game time when the effect started,
 * a reference to the game time subsystem and a reference to effect parameters.
 * It returns a boolean that is true when the effect is done and should expire.
 *
 * Example:
 * --------------------
 * //This draws an an increasing number of lines, in the game area.
 * //It is taken from the Game class, and uses its data member.
 * //Anyone is welcome to create a simpler example not depending on Game.
 * 
 * GraphicsEffect effect = new RandomLinesEffect(gameTime_.gameTime,
 * (const real startTime,
 *  const GameTime gameTime, 
 *  ref RandomLinesEffect.Parameters params)
 * {
 *     const double timeRatio = (gameTime.gameTime - startTime) / 3.0;
 *     if(timeRatio > 1.0){return true;}
 *     params.bounds   = Game.gameArea;
 *     params.minWidth = 0.3;
 *     params.maxWidth = 2.0;
 * 
 *     params.lineCount = round!uint((40 * clamp(timeRatio, 0.0, 1.0)) ^^ 2);
 *     params.color    = rgba!"8080F040";
 *     return false;
 * });
 * --------------------
 */
class RandomLinesEffect : GraphicsEffect 
{
    public:
        ///Parameters of a text effect.
        struct Parameters 
        {
            ///Bounds of the area where the lines are drawn.
            Rectf bounds   = Rectf(0.0f, 0.0f, 100.0f, 100.0f);
            ///Minimum line width.
            float minWidth = 0.1f;
            ///Maximum line width.
            float maxWidth = 10.0f;
            ///Number of lines to draw.
            uint lineCount = 100;
            ///Color of lines.
            Color color    = rgb!"FFFFFF";
        }

    private:
        ///Parameters of the effect.
        Parameters parameters_;

        ///Delegate that controls effect parameters based on passed start time and game time.
        const bool delegate(const real, const GameTime, ref Parameters) controlDelegate_;

        ///Game time when the effect was constructed.
        const real startTime_;

    public:
        ///Construct a RandomLinesEffect starting at startTime using controlDelegate to set its parameters.
        this(const real startTime, 
             bool delegate(const real, const GameTime, ref Parameters) controlDelegate)
        {
            startTime_ = startTime;
            controlDelegate_ = controlDelegate;
        }

        override void draw(VideoDriver video, const GameTime gameTime)
        {
            done_ = controlDelegate_(startTime_, gameTime, parameters_);
            if(done){return;}

            video.lineAA = true;
            with(parameters_) foreach(l; 0 .. lineCount)
            {
                video.lineWidth = uniform(minWidth, maxWidth);
                float y = uniform(bounds.min.y, bounds.max.y);
                video.drawLine(Vector2f(bounds.min.x, y), Vector2f(bounds.max.x, y),
                               color, color);
            }
            video.lineWidth = 1.0f;
            video.lineAA = false;
        }
}

/**
 * Text effect.
 *
 * Draws text with parameters specified each frame by a delegate.
 *
 * The delegate takes a real specifying game time when the effect started,
 * a reference to the game time subsystem and a reference to effect parameters.
 * It returns a boolean that is true when the effect is done and should expire.
 *
 * Example:
 * --------------------
 * //This draws an enlarging, fading text in the middle of the game area.
 * //It is taken from the Game class, and uses its data member.
 * //Anyone is welcome to create a simpler example not depending on Game.
 * 
 * GraphicsEffect effect = new TextEffect(gameTime_.gameTime,
 *    (const real startTime,
 *     const GameTime gameTime, 
 *     ref TextEffect.Parameters params)
 *    {
 *        const double timeRatio = (gameTime.gameTime - startTime) / 1.5;
 *        if(timeRatio > 1.0){return true;}
 * 
 *        auto gameOver = "GAME OVER";
 * 
 *        params.text = gameOver;
 * 
 *        params.font = "default";
 *        params.fontSize = 80 + round!uint(max(0.0, timeRatio * 16.0) ^^ 2); 
 * 
 *        //Must set videodriver font and font size to measure text size.
 *        videoDriver_.font     = "default";
 *        videoDriver_.fontSize = params.fontSize;
 *        const textSize        = videoDriver_.textSize(params.text).to!float;
 *        const area            = Game.gameArea;
 *        params.offset         = (area.min + (area.size - textSize) * 0.5).to!int;
 * 
 *        params.color = rgba!"8080F080".interpolated(rgba!"8080F000", 
 *                                                    1.0 - timeRatio ^^ 2);
 *        return false;
 *    });
 * --------------------
 */
class TextEffect : GraphicsEffect
{
    public:
        ///Parameters of a text effect.
        struct Parameters 
        {
            ///Text to draw.
            string text = "DUMMY";
            ///Font to draw with.
            string font = "default";
            ///Left-upper corner of the text on screen.
            Vector2i offset;
            ///Font size.
            uint fontSize;
            ///Font color.
            Color color;
        }

    private:
        ///Parameters of the effect.
        Parameters parameters_;

        ///Delegate that controls effect parameters based on passed start time and game time.
        const bool delegate(const real, const GameTime, ref Parameters) controlDelegate_;

        ///Game time when the effect was constructed.
        const real startTime_;

    public:
        ///Construct a TextEffect starting at startTime using controlDelegate to set its parameters.
        this(const real startTime, 
             bool delegate(const real, const GameTime, ref Parameters) controlDelegate)
        {
            startTime_ = startTime;
            controlDelegate_ = controlDelegate;
        }

        override void draw(VideoDriver video, const GameTime gameTime)
        {
            done_ = controlDelegate_(startTime_, gameTime, parameters_);
            if(done_){return;}

            video.fontSize = parameters_.fontSize;
            video.font     = parameters_.font;
            video.drawText(parameters_.offset, parameters_.text, parameters_.color);
        }
}


///Manages graphics effects.
class GraphicsEffectManager
{
    private:
        ///Currently drawn effects.
        GraphicsEffect[] effects_;

    public:
        ///Destroy all remaining effects and the manager.
        ~this() {clear(effects_);}

        ///Draw graphics effects with specified video driver and game time subsystem.
        void draw(VideoDriver video, const GameTime gameTime)
        {
            foreach(effect; effects_)
            {
                effect.draw(video, gameTime);

                if(effect.done){effect.expire();}
            }

            //Remove expired effects.
            effects_ = effects_.remove!(e => e.done)();
        }

        ///Add a new graphics effect.
        void addEffect(GraphicsEffect effect) pure nothrow {effects_ ~= effect;}
}

