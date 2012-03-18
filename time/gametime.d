
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Timing of game updates.
module time.gametime;


import std.algorithm;

import time.time;
import time.timer;


/**
 * Handles timing of game updates.
 *
 * GameTime ensures that all game logic/physics/etc updates happen with a 
 * constant tick, and asynchronously relative to game renders, while renders
 * can happen whenever time is available.
 *
 * For example, if renders are slow, one render might be followed by multiple 
 * game updates to cover time taken by the render. If they are fast, multple 
 * renders might happen between game updates.
 *
 * If game updates get too slow, they slow down while the game tick length
 * is preserved, resulting in a gameplay slowdown.
 */
class GameTime
{
    private:
        ///Time taken by single game update.
        immutable real timeStep_ = 1.0 / 120.0; 
        ///Time this update started, in game time (i.e; the current game time).
        real gameTime_ = 0.0;
        ///Time update() function started, in absolute time.
        real updateCallStart_ = -1.0;
        ///Time we're behind in game updates.
        real accumulatedTime_ = 0.0;
        ///Game time speed multiplier. Zero means pause (stopped time).
        real timeSpeed_ = 1.0;
        ///Number of the current update.
        size_t tickIndex_ = 0;

    public:
        /**
         * Run as many game updates as needed based on how much time has passed.
         *
         * Passed delegate should update any game subsystems or other state that
         * needs to be updated in synchronization with game ticks.
         *
         * Params:  updateDeleg = Delegate used to update game state.
         */
        void doGameUpdates(void delegate() updateDeleg)
        {
            const real time = getTime();
            //First call to doGameUpdates(), results in no updates.
            if(updateCallStart_ < 0){updateCallStart_ = time;}
            //Time since last update() call.
            real frameLength = max(time - updateCallStart_, 0.0L);
            updateCallStart_ = time;

            //Preventing spiral of death -
            //if we can't keep up updating, slow down the game.
            frameLength = min(frameLength * timeSpeed_, 0.25L);

            accumulatedTime_ += frameLength;

            while(accumulatedTime_ >= timeStep_)
            {
                updateDeleg();

                gameTime_ += timeStep_;
                accumulatedTime_ -= timeStep_;
                ++tickIndex_;
            }
        }

        ///Get current game time.
        @property real gameTime() const pure nothrow {return gameTime_;}

        ///Get current time step (always constant, but kept non-static just in case).
        @property real timeStep() const pure nothrow {return timeStep_;}

        ///Get time speed.
        @property real timeSpeed() const pure nothrow {return timeSpeed_;}

        ///Set time speed.
        @property void timeSpeed(const real rhs) pure nothrow {timeSpeed_ = rhs;}
}
