//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module ice.hud;


import std.algorithm;
import std.array;
import std.conv;

import dgamevfs._;

import color;
import component.statisticscomponent;
import gui2.guisystem;
import gui2.labelwidget;
import gui2.rootwidget;
import ice.guiswapper;
import math.math;
import math.vector2;
import time.gametime;
import util.yaml;
import video.videodriver;


///In game HUD.
class HUD: SwappableGUI
{
    private:
        ///Time left for the current message text to stay on the HUD.
        float messageTextTimeLeft_ = 0.0f;

        ///Ratio of current player health vs max player health.
        float playerHealthRatio_ = 1.0f;

        ///Is the HUD visible?
        bool visible_ = false;

        ///Root widget of the HUD.
        RootWidget hudGUI_;

    public:
        /// Constructs HUD.
        /// 
        /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
        ///         gameDir    = Game data directory.
        ///
        /// Throws: YAMLException on a YAML parsing error.
        ///         VFSException on a filesystem error.
        this(GUISystem guiSystem, VFSDir gameDir)
        {
            auto hudGUIFile = gameDir.dir("gui").file("hudGUI.yaml");
            hudGUI_ = guiSystem.loadWidgetTree(loadYAML(hudGUIFile));
            super(hudGUI_);
        }

        ///Destroy the HUD.
        ~this()
        {
        }

        /**
         * Update the game GUI, using game time subsystem to measure time.
         */
        void update(const GameTime gameTime)
        {
            if(!hudGUI_.infoText!LabelWidget.text.empty)
            {
                messageTextTimeLeft_ -= gameTime.timeStep;
                if(messageTextTimeLeft_ <= 0)
                {
                    hudGUI_.infoText!LabelWidget.text = "";
                }
            }
        }

        ///Hide the HUD.
        void hide()
        {
            visible_ = false;
        }

        ///Show the HUD.
        void show()
        {
            visible_ = true;
        }

        ///Set the message text on the bottom of the HUD for specified (game) time.
        void messageText(string rhs, float time) 
        {
            hudGUI_.infoText!LabelWidget.text = rhs;
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

        ///Update any player statistics related displays in the HUD.
        void updatePlayerStatistics(ref const StatisticsComponent statistics)
        {
            hudGUI_.score!LabelWidget.text = to!string(statistics.expGained);
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
