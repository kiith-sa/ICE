//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///AI and human player classes.
module ice.player;


import ice.game;
import platform.platform;
import time.timer;
import math.math;
import math.vector2;


///Parent class for all players.
abstract class Player
{
    protected:
        ///Player name.
        const string name_;
        ///Current player score.
        uint score_ = 0;

    public:
        ///Get name of this player.
        @property string name() const {return name_;}

        /**
         * Update player state.
         * 
         * Params:  game = Reference to the game.
         */
        void update(Game game){}

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

        override void update(Game game)
        {
            if(updateTimer_.expired())
            {
                updateTimer_.reset();

                //TODO currently does nothing
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
