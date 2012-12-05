//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///In game HUD.
module ice.hud;


import std.algorithm;
import std.array;
import std.conv;
import std.typecons;

import dgamevfs._;

import color;
import component.statisticscomponent;
import component.weaponcomponent;
import gui2.exceptions;
import gui2.guisystem;
import gui2.labelwidget;
import gui2.progressbarwidget;
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
        // Time left for the current message text to stay on the HUD.
        float messageTextTimeLeft_ = 0.0f;

        // Root widget of the HUD.
        RootWidget hudGUI_;


        // Shows information text set by the level script.
        //
        // (will be removed unless we can make it more usable).
        // Can be null (so modders can remove the widget).
        LabelWidget infoTextLabel_;

        // Shows current player health.
        //
        // Can be null (so modders can remove the widget).
        ProgressBarWidget healthBar_;

        // Shows player score.
        //
        // Can be null (so modders can remove the widget).
        LabelWidget scoreLabel_;

        // Progress bars showing reload status for player weapons.
        //
        // We automatically handle any number of weapon reload bars so 
        // new weapons and their HUD items can be added without touching
        // the source code.
        ProgressBarWidget[] weaponReloadBars_;

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

            infoTextLabel_ = hudGUI_.infoText!(LabelWidget,     Yes.optional);
            healthBar_     = hudGUI_.health!(ProgressBarWidget, Yes.optional);
            scoreLabel_    = hudGUI_.score!(LabelWidget,        Yes.optional);
            uint w = 1;
            for(;;++w)
            {
                auto reloadBar = hudGUI_.get!(ProgressBarWidget, Yes.optional)
                                             ("weapon" ~ to!string(w));
                if(reloadBar is null) {break;}
                weaponReloadBars_ ~= reloadBar;
            }
            super(hudGUI_);
        }

        /// Destroy the HUD.
        ~this()
        {
        }

        /// Update the game GUI, using game time subsystem to measure time.
        void update(const GameTime gameTime)
        {
            if(infoTextLabel_ is null || infoTextLabel_.text.empty){return;}
            messageTextTimeLeft_ -= gameTime.timeStep;
            if(messageTextTimeLeft_ <= 0)
            {
                infoTextLabel_.text = "";
            }
        }

        ///Set the message text on the bottom of the HUD for specified (game) time.
        void messageText(string rhs, float time) 
        {
            if(infoTextLabel_ is null){return;}
            infoTextLabel_.text  = rhs;
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
            if(healthBar_ is null){return;}
            healthBar_.progress = health;
        }

        ///Update any player statistics related displays in the HUD.
        void updatePlayerStatistics(ref const StatisticsComponent statistics)
        {
            if(scoreLabel_ is null){return;}
            scoreLabel_.text = to!string(statistics.expGained);
        }

        ///Update player weapon data (e.g. reloading) in the HUD.
        void updatePlayerWeapon(ref const WeaponComponent weapon)
        {
            const weapons = weapon.weapons;
            // The first reload bar handles the second weapon, second the
            // third, and so on, hence weapons.length - 1.
            for (size_t w = 0; w < min(weaponReloadBars_.length, weapons.length - 1); ++w)
            {
                const remaining = cast(float)weapons[w + 1].reloadTimeRemainingRatio;
                weaponReloadBars_[w].progress = clamp(1.0f - remaining , 0.0f, 1.0f);
            }
        }
}
