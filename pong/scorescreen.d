//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module pong.scorescreen;
@safe


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
        GUIStaticText winner_text_;
        ///Text showing player names.
        GUIStaticText names_text_;
        ///Text showing player scores.
        GUIStaticText scores_text_;
        ///Text showing time the game took.
        GUIStaticText time_text_;

    public:
        ///Emitted when the score screen expires.
        mixin Signal!() expired;

        /**
         * Construct a score screen.
         *
         * Params: parent    = GUI element to attach the score screen to.
         *         player_1  = First player of the game.
         *         player_2  = Second player of the game.
         *         time      = Time the game took in seconds.
         */
        this(GUIElement parent, in Player player_1, in Player player_2, in real time)
        in
        {
            assert(player_1.score != player_2.score, 
                   "Score screen shown but neither of the players is victorious");
        }
        body
        {
            with(new GUIElementFactory)
            {
                x = "p_right / 2 - 192";
                y = "p_bottom / 2 - 128";
                width = "384";
                height = "256";
                container_ = produce();
            }

            parent_ = parent;
            parent_.add_child(container_);

            string winner = player_1.score > player_2.score ? 
                            player_1.name : player_2.name;

            with(new GUIStaticTextFactory)
            {
                x = "p_left + 48";
                y = "p_top + 96";
                width = "128";
                height = "16";
                font_size = 14;
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-light.ttf";
                text = "Time: " ~ time_string(time);
                //text showing time the game took
                time_text_ = produce();

                x = "p_left";
                y = "p_top + 16";
                width = "p_width";
                height = "32";
                font_size = 24;
                text_color = Color(192, 192, 255, 128);
                align_x = AlignX.Center;
                font = "orbitron-bold.ttf";
                text = "WINNER: " ~ winner;
                //text showing the winner of the game
                winner_text_ = produce();
            }

            container_.add_child(time_text_);
            container_.add_child(winner_text_);

            init_scores(player_1, player_2);

            timer_ = Timer(8);
        }

        ///Update the score screen (and check for expiration).
        void update()
        {
            if(timer_.expired){expired.emit();}
        }

        ///Destroy the score screen.
        void die()
        {
            container_.die();
            expired.disconnect_all();
        }
        
    private:
        ///Initialize players/scores list.
        void init_scores(in Player player_1, in Player player_2)
        {
            with(new GUIStaticTextFactory)
            {
                x = "p_left + 48";
                y = "p_top + 48";
                width = "128";
                height = "32";
                font_size = 14;
                text_color = Color(160, 160, 255, 128);
                font = "orbitron-light.ttf";
                text = player_1.name ~ "\n" ~ player_2.name;
                names_text_ = produce();

                x = "p_right - 128";
                width = "64";
                text_color = Color(224, 224, 255, 160);
                font = "orbitron-bold.ttf";
                text = to!string(player_1.score) ~ "\n" ~ to!string(player_2.score);
                align_x = AlignX.Right;
                scores_text_ = produce();
            }

            container_.add_child(names_text_);
            container_.add_child(scores_text_);
        }
}
