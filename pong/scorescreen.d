//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Score screen.
module pong.scorescreen;


import std.conv;

import pong.player;
import gui.guielement;
import gui.guistatictext;
import time.time;
import time.timer;
import util.signal;
import color;


/**
 * Displays score screen at the end of game.
 *
 * Signal:
 *     public mixin Signal!() expired
 *
 *     Emitted when the score screen expires. 
 */
class ScoreScreen
{
    private:
        ///Score screen ends when this timer expires.
        Timer timer_;

        ///Parent of the score screen container.
        GUIElement parent_;

        ///Container of all score screen GUI elements.
        GUIElement container_;
        ///Text showing the winner.
        GUIStaticText winnerText_;
        ///Text showing player names.
        GUIStaticText namesText_;
        ///Text showing player scores.
        GUIStaticText scoresText_;
        ///Text showing time the game took.
        GUIStaticText timeText_;

    public:
        ///Emitted when the score screen expires.
        mixin Signal!() expired;

        /**
         * Construct a score screen.
         *
         * Params: parent    = GUI element to attach the score screen to.
         *         player1  = First player of the game.
         *         player2  = Second player of the game.
         *         time      = Time the game took in seconds.
         */
        this(GUIElement parent, in Player player1, in Player player2, in real time)
        in
        {
            assert(player1.score != player2.score, 
                   "Score screen shown but neither of the players is victorious");
        }
        body
        {
            with(new GUIElementFactory)
            {
                x          = "p_right / 2 - 192";
                y          = "p_bottom / 2 - 128";
                width      = "384";
                height     = "256";
                container_ = produce();
            }

            parent_ = parent;
            parent_.addChild(container_);

            string winner = player1.score > player2.score ? 
                            player1.name : player2.name;

            with(new GUIStaticTextFactory)
            {
                x            = "p_left + 48";
                y            = "p_top + 96";
                width        = "128";
                height       = "16";
                fontSize    = 14;
                textColor   = rgba!"E0E0FFA0";
                font         = "orbitron-light.ttf";
                text         = "Time: " ~ timeString(time);
                timeText_   = produce();

                x            = "p_left";
                y            = "p_top + 16";
                width        = "p_width";
                height       = "32";
                fontSize    = 24;
                textColor   = rgba!"C0C0FF80";
                alignX      = AlignX.Center;
                font         = "orbitron-bold.ttf";
                text         = "WINNER: " ~ winner;
                winnerText_ = produce();
            }

            container_.addChild(timeText_);
            container_.addChild(winnerText_);

            initScores(player1, player2);

            timer_ = Timer(8);
        }

        ///Destroy the score screen.
        ~this()
        {
            container_.die();
            expired.disconnectAll();
        }

        ///Update the score screen (and check for expiration).
        void update()
        {
            if(timer_.expired){expired.emit();}
        }
        
    private:
        ///Initialize players/scores list.
        void initScores(in Player player1, in Player player2)
        {
            with(new GUIStaticTextFactory)
            {
                x            = "p_left + 48";
                y            = "p_top + 48";
                width        = "128";
                height       = "32";
                fontSize    = 14;
                textColor   = rgba!"A0A0FF80";
                font         = "orbitron-light.ttf";
                text         = player1.name ~ "\n" ~ player2.name;
                namesText_  = produce();

                x            = "p_right - 128";
                width        = "64";
                textColor   = rgba!"E0E0FFA0";
                font         = "orbitron-bold.ttf";
                text         = to!string(player1.score) ~ "\n" ~ to!string(player2.score);
                alignX      = AlignX.Right;
                scoresText_ = produce();
            }

            container_.addChild(namesText_);
            container_.addChild(scoresText_);
        }
}
