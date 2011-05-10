//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module pong.hud;
@safe


import std.algorithm;
import std.conv;

import pong.player;
import gui.guielement;
import gui.guistatictext;
import time.time;
import math.math;
import color;


///In game HUD.
class HUD
{
    private:
        alias std.conv.to to;

        ///Parent of all HUD elements.
        GUIElement parent_;

        ///Displays player 1 score.
        GUIStaticText score_text_1_;
        ///Displays player 2 score.
        GUIStaticText score_text_2_;
        ///Displays time left in game.
        GUIStaticText time_text_;

        ///Maximum time the game can take in game time.
        real time_limit_;

    public:
        /**
         * Constructs HUD with specified parameters.
         *
         * Params:  parent     = Parent GUI element for all HUD elements.
         *          time_limit = Maximum time the game will take.
         */
        this(GUIElement parent, in real time_limit)
        {
            parent_ = parent;
            time_limit_ = time_limit;

            with(new GUIStaticTextFactory)
            {
                x = "p_left + 8";
                y = "p_top + 8";
                width = "96";
                height = "16";
                font_size = 16;
                font = "orbitron-light.ttf";
                align_x = AlignX.Right;
                score_text_1_ = produce();

                y = "p_bottom - 24";
                score_text_2_ = produce();

                x = "p_right - 112";
                font = "orbitron-bold.ttf";
                time_text_ = produce();
            }

            parent_.add_child(score_text_1_);
            parent_.add_child(score_text_2_);
            parent_.add_child(time_text_);
        }

        /**
         * Update the HUD.
         *
         * Params:    time_left = Time left until time limit runs out.
         *            player_1  = First player of the game.
         *            player_2  = Second player of the game. 
         */
        void update(real time_left, in Player player_1, in Player player_2)
        {
            //update time display
            time_left = max(time_left, 0.0L);
            const string time_str = time_string(time_left);
            immutable Color color_start = Color(160, 160, 255, 160);
            immutable Color color_end = Color.red;
            //only update if the text has changed
            if(time_str != time_text_.text)
            {
                time_text_.text = time_str != "0:0" ? time_str : time_str ~ " !";

                const real t = max(time_left / time_limit_, 1.0L);
                time_text_.text_color = color_start.interpolated(color_end, t);
            }

            //update score displays
            string score_str_1 = player_1.name ~ ": " ~ to!string(player_1.score);
            string score_str_2 = player_2.name ~ ": " ~ to!string(player_2.score);
            //only update if the text has changed
            if(score_text_1_.text != score_str_1){score_text_1_.text = score_str_1;}
            if(score_text_2_.text != score_str_2){score_text_2_.text = score_str_2;}
        }

        ///Hide the HUD.
        void hide()
        {
            score_text_1_.hide();
            score_text_2_.hide();
            time_text_.hide();
        }

        ///Show the HUD.
        void show()
        {
            score_text_1_.show();
            score_text_2_.show();
            time_text_.show();
        }

        ///Destroy the HUD.
        void die()
        {
            score_text_1_.die();
            score_text_1_ = null;

            score_text_2_.die();
            score_text_2_ = null;

            time_text_.die();
            time_text_ = null;
        }
}
