//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///AI and human player classes.
module ice.player;


import component.controllercomponent;
import component.entitysystem;
import math.math;
import math.vector2;
import platform.platform;
import time.timer;


/**
 * Parent class for all players.
 *
 * Note that it is expected to explicitly destroy the Player using clear()
 * once it is not used anymore.
 */
abstract class Player
{
    protected:
        ///Player name.
        const string name_;
        ///Current player score.
        uint score_ = 0;

    public:
        ///Get name of this player.
        @property string name() const pure nothrow {return name_;}

        /**
         * Update player state.
         * 
         * Params:  game = Reference to the game.
         */
        void update(){}

        ///Control entity with specified ID through its ControllerComponent.
        void control(EntityID id, ref ControllerComponent control) pure nothrow;

        ///String representation of the player (currently just returns player name).
        override string toString() const pure nothrow
        {
            return name_;
        }

    protected:
        /**
         * Construct a player.
         * 
         * Params:  name   = Player name.
         */
        this(const string name)
        {
            name_   = name;
        }
}

///AI player.
final class AIPlayer : Player
{
    protected:
        ///Timer determining when to update the AI.
        Timer updateTimer_;
        ///Position of the ball during last AI update.
        Vector2f ballLast_;

    public:
        /**
         * Construct an AI player.
         * 
         * Params:  name         = Player name.
         *          updatePeriod = Time period of AI updates.
         */
        this(const string name, const real updatePeriod)
        {
            super(name);
            updateTimer_ = Timer(updatePeriod);
        }

        override void control(EntityID id, ref ControllerComponent control) pure nothrow
        {
            assert(false, "AIPlayer.control() : not yet implemented");
        }

        override void update()
        {
            if(updateTimer_.expired())
            {
                updateTimer_.reset();

                assert(false, "AI Player update(): not yet implemented");
            }
        }
}

///Human player controlling the game through user input.
final class HumanPlayer : Player
{
    private:
        ///Platform for user input.
        Platform platform_;

    public:
        /**
         * Construct a human player.
         *
         * Params:  platform = Platform for user input.
         *          name     = Name of the player.
         */
        this(Platform platform, const string name)
        {
            super(name);
            platform_ = platform;
            platform_.key.connect(&keyHandler);
        }

        override void control(EntityID id, ref ControllerComponent control) pure nothrow
        {
            bool kp(Key key) nothrow {return platform_.isKeyPressed(key);}

            //Aggregate input from direction buttons into a direction vector.
            auto direction = Vector2f(0.0f, 0.0f);
            if(kp(Key.K_A) || kp(Key.Left))  {direction += Vector2f(1.0f, 0.0f);}
            if(kp(Key.K_D) || kp(Key.Right)) {direction += Vector2f(-1.0f, 0.0f);}
            if(kp(Key.K_W) || kp(Key.Up))    {direction += Vector2f(0.0f, 1.0f);}
            if(kp(Key.K_S) || kp(Key.Down))  {direction += Vector2f(0.0f, -1.0f);}
            control.movementDirection = direction.normalized;

            control.firing[0] = kp(Key.Space) || kp(Key.Lctrl);

            control.firing[1] = kp(Key.K_J) || kp(Key.NP_4);
            control.firing[2] = kp(Key.K_K) || kp(Key.NP_2);
            control.firing[3] = kp(Key.K_L) || kp(Key.NP_6);
            control.firing[4] = kp(Key.K_I) || kp(Key.NP_8);
        }
        
        ///Destroy this HumanPlayer.
        ~this(){platform_.key.disconnect(&keyHandler);}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void keyHandler(KeyState state, Key key, dchar unicode)
        {
        }
}
