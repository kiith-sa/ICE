
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Procedural graphics effects.
module ice.graphicseffect;


import std.algorithm;
import std.math : fmod;
import std.random;
import std.typecons;

import color;
import containers.vector;
import math.math;
import math.rect;
import math.vector2;
import video.videodriver;
import util.signal;
import util.frameprofiler;

//XXX XXX INSERT ZONES HERE NOW!

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
     *          gameTime = Current game time.
     */
    void draw(VideoDriver video, const real gameTime);

private:
    ///Are we done drawing this effect?
    final @property bool done() const pure nothrow {return done_;}

    ///Expire the effect, emitting the onExpired signal. Called before destruction.
    final void expire() {onExpired.emit();}
}

/**
 * Effect that draws lines at random coordinates, optionally vertically scrolling them.
 *
 * Effect parameters are specified each frame by a delegate.
 *
 * The delegate takes a real specifying game time when the effect started,
 * a reference to the game time subsystem and a reference to effect parameters.
 * It returns a boolean that is true when the effect is done and should expire.
 *
 * Example:
 * --------------------
 * //This draws an an increasing number of slowly moving vertical lines in the game area.
 * //It is taken from the Game class, and uses its data member.
 * //Anyone is welcome to create a simpler example not depending on Game.
 * 
 * GraphicsEffect effect = new RandomLinesEffect(gameTime_.gameTime,
 * (const real startTime,
 *  const real currentTime, 
 *  ref RandomLinesEffect.Parameters params)
 * {
 *     const double timeRatio = (currentTime - startTime) / 3.0;
 *     if(timeRatio > 1.0){return true;}
 *     params.bounds   = Game.gameArea;
 *     params.minWidth = 0.3;
 *     params.maxWidth = 2.0;
 *     params.minLength = 4.0f;
 *     params.maxLength = 16.0f;
 *
 *     params.linesPerPixel = round!uint((40 * clamp(timeRatio, 0.0, 1.0)) ^^ 2)
 *                            Game.gameArea.area;
 *     params.color    = rgba!"8080F040";
 *     params.detailLevel = 4;
 *     params.verticalScrollingSpeed = 100.0f;
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
        ///Direction of the lines. Must be a unit (length == 1) vector.
        Vector2f lineDirection = Vector2f(0.0f, 1.0f);
        ///Minimum line width.
        float minWidth = 0.1f;
        ///Maximum line width. Must be > minWidth.
        float maxWidth = 10.0f;
        ///Minimum line length.
        float minLength = 16.0f;
        ///Maximum line length. Must be > minLength.
        float maxLength = 64.0f;
        /**
         * Average number of lines per "pixel" of area specified by bounds. 
         *
         * "Pixel" is a square of distance of 1.0 unit.
         * Must be <= 1.0;
         */
        float linesPerPixel = 0.001f;
        ///Speed of vertical scrolling in units per second.
        float verticalScrollingSpeed = 0.0f;

        /**
         * Higher values result in less random, less "detailed" effect but less overhead.
         *
         * 0 is "full" detail and rather CPU-intensive. 
         * 1 is less detail but a lot cheaper performance-wise.
         * Higher values are even cheaper.
         */
        uint detailLevel = 2;
        ///Color of lines.
        Color color    = rgb!"FFFFFF";

        ///Determine if all of the parameters are valid.
        bool valid() const pure nothrow
        {
            return bounds.valid &&
                   minWidth > 0.0f && minWidth <= maxWidth && maxWidth > 0.0f &&
                   minLength > 0.0f && minLength <= maxLength && maxLength > 0.0f &&
                   linesPerPixel >= 0.0f && linesPerPixel <= 1.0f  &&
                   equals(lineDirection.length, 1.0f);
        }
    }

private:
    ///Parameters of the effect.
    Parameters parameters_;

    ///Delegate that controls effect parameters based on passed start time and current time.
    const bool delegate(const real, const real, ref Parameters) controlDelegate_;

    ///Game time when the effect was constructed.
    const real startTime_;

    ///Random number generator we're using. Must be cheap and fast, not perfect.
    CheapRandomGenerator randomGenerator_;

public:
    ///Construct a RandomLinesEffect starting at startTime using controlDelegate to set its parameters.
    this(const real startTime, 
         bool delegate(const real, const real, ref Parameters) controlDelegate) 
    {
        startTime_ = startTime;
        controlDelegate_ = controlDelegate;
        randomGenerator_ = CheapRandomGenerator(32768);
    }

    override void draw(VideoDriver video, const real gameTime)
    {
        auto zone = Zone("RandomLinesEffect draw");
        //Get the parameters.
        done_ = controlDelegate_(startTime_, gameTime, parameters_);
        if(done){return;}

        assert(parameters_.valid, "Invalid RandomLinesEffect parameters");

        video.lineAA = true;
        const boundsInt = parameters_.bounds.to!int;

        //Skip rows and columns based on detail level.
        const skip = parameters_.detailLevel + 1;
        //We're not storing any of the lines. Rather,
        //we're computing RNG seed based on vertical scrolling speed and
        //incrementing seed for every row.
        //When the effect scrolls, the rows' seeds scroll accordingly.

        uint seed  = -round!uint(gameTime * parameters_.verticalScrollingSpeed / skip);
        //We're not necessarily iterating each "pixel", so update per-pixel probability
        //with skip in mind.

        const pixelProbability = parameters_.linesPerPixel * skip ^^ 2;
        const rowProbability = pixelProbability * (boundsInt.width / skip);

        // Precompute what we can here 
        // (We should probably remove this once optimized or GDC build works)
        const halfSkip            = 0.5 * skip;
        const widthRange          = parameters_.maxWidth  - parameters_.minWidth;
        const lengthRange         = parameters_.maxLength - parameters_.minLength;

        auto loopZone = Zone("RandomLinesEffect draw geneartion loop");

        const rowLength = (boundsInt.max.x - boundsInt.min.x) / skip;
        //Processing "pixels" within boundsInt and generating lines' centers.
        for(int y = boundsInt.min.y; y < boundsInt.max.y; y += skip, ++seed)
        {
            randomGenerator_.seed(seed);

            auto random = randomGenerator_.random();
            auto linesInRow = rowLength * pixelProbability - (rowProbability / (boundsInt.width / skip)) * 2.0 * random;
            // Prevents low-probability lines from not appearing at all.
            if(random <= rowProbability)
            {
                linesInRow += 1.0f;
            }
            const linesInRowInt = cast(uint) linesInRow;
            for (size_t l = 0; l < linesInRowInt; ++l) with(parameters_)
            {
                random = randomGenerator_.random();
                random *= 10.0f;
                random -= cast(uint)random;

                const column = cast(uint)(random * (rowLength - 1) + 0.5f);
                linesInRow -= 1.0f;

                const x = boundsInt.min.x + skip * column;

                //Get line width.
                //Optimization: Getting a random number by stripping the first digit of previous random.
                random *= 10.0f;
                random -= cast(uint)random;
                const width = minWidth + widthRange * random;
                video.lineWidth = width;

                //Get line length.
                //Optimization: Getting a random number by stripping the first digit of previous random.
                random *= 10.0f;
                random -= cast(uint)random;
                const halfLength = 0.5f * (minLength + lengthRange * random);

                //Randomly nudge x, y of each line by a 
                //random value, at most skip / 2
                //Optimization: Getting a random number by stripping the first digit of previous random.
                random *= 10.0f;
                random -= cast(uint)random;
                const xNudge = skip * random - halfSkip;
                //Optimization: Getting a random number by stripping the first digit of previous random.
                random *= 10.0f;
                random -= cast(uint)random;
                const yNudge = skip * random - halfSkip;
                const center = Vector2f(x + xNudge, y + yNudge);

                //Finally, draw the line.
                video.drawLine(center - halfLength * lineDirection,
                               center + halfLength * lineDirection,
                               color,
                               color);
            }
        }

        //Restore video driver state.
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
 *     const currentTime, 
 *     ref TextEffect.Parameters params)
 *    {
 *        const double timeRatio = (currentTime - startTime) / 1.5;
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
    const bool delegate(const real, const real, ref Parameters) controlDelegate_;

    ///Game time when the effect was constructed.
    const real startTime_;

public:
    ///Construct a TextEffect starting at startTime using controlDelegate to set its parameters.
    this(const real startTime, 
         bool delegate(const real, const real, ref Parameters) controlDelegate) pure nothrow
    {
        startTime_ = startTime;
        controlDelegate_ = controlDelegate;
    }

    override void draw(VideoDriver video, const real gameTime)
    {
        auto zone = Zone("TextEffect draw");
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
        ~this() 
        {
            foreach(ref effect; effects_)
            {
                clear(effect);
            }
            clear(effects_);
        }

        ///Draw graphics effects with specified video driver and current time.
        void draw(VideoDriver video, const real currentTime)
        {
            //Must keep track of expired effects to destroy them.
            Vector!(void*) expired;

            foreach(effect; effects_)
            {
                effect.draw(video, currentTime);

                if(effect.done)
                {
                    effect.expire();
                    expired ~= cast(void*)effect;
                }
            }

            //Remove expired effects.
            effects_ = effects_.remove!(e => e.done)();

            foreach(effect; expired)
            {
                clear(cast(GraphicsEffect)effect);
            }
        }

        ///Add a new graphics effect.
        void addEffect(GraphicsEffect effect) pure nothrow {effects_ ~= effect;}
}

private:
import containers.fixedarray;

///Cheap random number generator used by graphics effects. Returns randoms between 0.0 and 1.0 .
struct CheapRandomGenerator
{
    private:
        ///Table of random numbers generated at construction.
        FixedArray!float table_;

        ///Table of offsets into table_ used when seeding.
        FixedArray!uint offsets_;

        /**
         * Current offset_ into table_. 
         *
         * Set to offsets_[seed % size_] at seed() and incremented at random().
         */
        uint offset_;

        ///Size of table_ and offsets_.
        uint size_;

    public:
        ///Create a CheapRandomGenerator. Larger size means more randomness but also memory usage.
        this(const uint size)
        {
            size_ = size;
            table_ = FixedArray!float(size_);
            offsets_ = FixedArray!uint(size_);

            foreach(i; 0 .. size_)
            {
                table_[i] = uniform(0.0f, 1.0f);
                offsets_[i] = uniform(0, size_);
            }
        }

        ///Seed the generator.
        void seed(const uint seed) pure nothrow
        {
            offset_ = offsets_[seed % size_];
        }

        ///Get a random number between 0.0f and 1.0f.
        float random() pure nothrow
        {
            return table_[(offset_++) % size_];
        }
}
