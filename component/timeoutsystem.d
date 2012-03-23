
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///System that processes various timeouts in the game.
module component.timeoutsystem;


import time.gametime;

import component.deathtimeoutcomponent;
import component.entitysystem;
import component.system;


///System that handles various timeouts in the game.
class TimeoutSystem : System
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Game time subsystem.
        const GameTime gameTime_;

    public:
        /**
         * Construct a TimeoutSystem working on entities from specified EntitySystem
         * and using specified game time subsystem to determine time.
         */
        this(EntitySystem entitySystem, const GameTime gameTime)
        {
            entitySystem_ = entitySystem;
            gameTime_     = gameTime;
        }

        ///Update the ControllerSystem, processing entities with various timeout components.
        void update()
        {
            //Kill any entities whose lifetime has expired.
            foreach(ref Entity e, ref DeathTimeoutComponent timeout; entitySystem_)
            {
                timeout.timeLeft -= gameTime_.timeStep;
                if(timeout.timeLeft < 0.0f){e.kill();}
            }
        }
}
