//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module ice.hud;


import std.algorithm;
import std.array;
import std.conv;

import color;
import gui.guielement;
import gui.guistatictext;
import math.math;
import math.vector2;
import time.gametime;
import video.videodriver;


///In game HUD.
class HUD
{
    private:
        ///Parent of all HUD elements.
        GUIElement parent_;

        ///Message text at the bottom of the HUD.
        GUIStaticText messageText_;

        ///Time left for the current message text to stay on the HUD.
        float messageTextTimeLeft_ = 0.0f;

        ///Ratio of current player health vs max player health.
        float playerHealthRatio_ = 1.0f;

        ///Is the HUD visible?
        bool visible_ = false;

    public:
        /**
         * Constructs HUD.
         *
         * Params:  parent = Parent GUI element for all HUD elements.
         */
        this(GUIElement parent)
        {
            parent_ = parent;

            with(new GUIStaticTextFactory)
            {
                x           = "p_left + 8";
                y           = "p_bottom - 24";
                width       = "p_width - 16";
                height      = "16";
                fontSize    = 12;
                font        = "orbitron-light.ttf";
                alignX      = AlignX.Right;
                messageText_ = produce();
            }

            parent_.addChild(messageText_);
        }

        ///Destroy the HUD.
        ~this()
        {
            messageText_.die();
        }

        /**
         * Update the game GUI, using game time subsystem to measure time.
         */
        void update(const GameTime gameTime)
        {
            if(!messageText_.text.empty)
            {
                messageTextTimeLeft_ -= gameTime.timeStep;
                if(messageTextTimeLeft_ <= 0)
                {
                    messageText_.text = "";
                }
            }
        }

        ///Hide the HUD.
        void hide()
        {
            messageText_.hide();
            visible_ = false;
        }

        ///Show the HUD.
        void show()
        {
            messageText_.show();
            visible_ = true;
        }
        
        ///Set the message text on the bottom of the HUD for specified (game) time.
        void messageText(string rhs, float time) 
        {
            messageText_.text = rhs;
            messageTextTimeLeft_ = time;
        }

        ///Update player health ratio. Must be at least 0 and at most 1.
        void updatePlayerHealth(float health)
        in
        {
            assert(health <= 1.0f && health >= 0.0f,
                   "Player health ratio out of range");
        }
        body
        {
            playerHealthRatio_ = health;
        }

        ///Draw any parts of the HUD that need to be drawn manually, not by the GUI subsystem.
        ///
        ///This is a hack to be used until we have a decent GUI subsystem.
        void draw(VideoDriver driver)
        {
            driver.lineWidth = 0.75f;
            const lines = 512;
            const gap   = 1.5f;
            foreach(l; 0 .. lines)
            {
                const color = l < (lines * playerHealthRatio_) ? rgba!"A0A0FF80"
                                                               : rgba!"A0A0FF28";
                driver.drawLine(Vector2f(16.0f + l * gap, 600.0f - 32.0f),
                                Vector2f(16.0f + l * gap, 600.0f - 16.0f),
                                color, color);
            }
            driver.lineWidth = 1.0f;
        }
}
