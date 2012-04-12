//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module ice.hud;


import std.algorithm;
import std.array;
import std.conv;

import gui.guielement;
import gui.guistatictext;
import math.math;
import time.gametime;


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
        }

        ///Show the HUD.
        void show()
        {
            messageText_.show();
        }
        
        ///Set the message text on the bottom of the HUD for specified (game) time.
        void messageText(string rhs, float time) 
        {
            messageText_.text = rhs;
            messageTextTimeLeft_ = time;
        }
}
