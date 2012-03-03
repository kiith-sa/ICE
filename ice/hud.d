//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module ice.hud;


import std.algorithm;
import std.conv;

import gui.guielement;
import gui.guistatictext;
import math.math;


///In game HUD.
class HUD
{
    private:
        ///Parent of all HUD elements.
        GUIElement parent_;

        ///Placeholder to show that the HUD exists.
        GUIStaticText placeholder_;

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
                y           = "p_top + 8";
                width       = "96";
                height      = "16";
                fontSize    = 16;
                font        = "orbitron-light.ttf";
                alignX      = AlignX.Right;
                placeholder_ = produce();
            }

            parent_.addChild(placeholder_);
            placeholder_.text = "HUD dummy";
        }

        ///Destroy the HUD.
        ~this()
        {
            placeholder_.die();
        }

        /**
         * Update the HUD.
         */
        void update()
        {
        }

        ///Hide the HUD.
        void hide()
        {
            placeholder_.hide();
        }

        ///Show the HUD.
        void show()
        {
            placeholder_.show();
        }
}
