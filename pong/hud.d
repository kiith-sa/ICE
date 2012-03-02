//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module pong.hud;


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
        GUIStaticText scoreText1_;
        ///Displays player 2 score.
        GUIStaticText scoreText2_;
        ///Displays time left in game.
        GUIStaticText timeText_;

        ///Maximum time the game can take in game time.
        real timeLimit_;

    public:
        /**
         * Constructs HUD with specified parameters.
         *
         * Params:  parent     = Parent GUI element for all HUD elements.
         *          timeLimit = Maximum time the game will take.
         */
        this(GUIElement parent, in real timeLimit)
        {
            parent_ = parent;
            timeLimit_ = timeLimit;

            with(new GUIStaticTextFactory)
            {
                x             = "p_left + 8";
                y             = "p_top + 8";
                width         = "96";
                height        = "16";
                fontSize     = 16;
                font          = "orbitron-light.ttf";
                alignX       = AlignX.Right;
                scoreText1_ = produce();

                y             = "p_bottom - 24";
                scoreText2_ = produce();

                x             = "p_right - 112";
                font          = "orbitron-bold.ttf";
                timeText_    = produce();
            }

            parent_.addChild(scoreText1_);
            parent_.addChild(scoreText2_);
            parent_.addChild(timeText_);
        }

        ///Destroy the HUD.
        ~this()
        {
            scoreText1_.die();
            scoreText2_.die();
            timeText_.die();
        }

        /**
         * Update the HUD.
         *
         * Params:    timeLeft = Time left until time limit runs out.
         *            player1  = First player of the game.
         *            player2  = Second player of the game. 
         */
        void update(real timeLeft, in Player player1, in Player player2)
        {
            //update time display
            timeLeft             = max(timeLeft, 0.0L);
            const timeStr        = timeString(timeLeft);
            immutable colorStart = rgba!"A0A0FFA0";
            immutable colorEnd   = Color.red;
            //only update if the text has changed
            if(timeStr != timeText_.text)
            {
                timeText_.text = timeStr != "0:0" ? timeStr : timeStr ~ " !";

                const real t = max(timeLeft / timeLimit_, 1.0L);
                timeText_.textColor = colorStart.interpolated(colorEnd, t);
            }

            //update score displays
            scoreText1_.text = player1.name ~ ": " ~ to!string(player1.score);
            scoreText2_.text = player2.name ~ ": " ~ to!string(player2.score); 
        }

        ///Hide the HUD.
        void hide()
        {
            scoreText1_.hide();
            scoreText2_.hide();
            timeText_.hide();
        }

        ///Show the HUD.
        void show()
        {
            scoreText1_.show();
            scoreText2_.show();
            timeText_.show();
        }
}
