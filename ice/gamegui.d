//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// GUI classes used by Game.
module ice.gamegui;


import std.conv;
import std.random;
import std.string;
import std.typecons;

import dgamevfs._;

import component.statisticscomponent;
import component.weaponcomponent;
import gui2.guisystem;
import gui2.exceptions;
import gui2.labelwidget;
import gui2.rootwidget;
import ice.game;
import ice.guiswapper;
import ice.hud;
import time.gametime;
import util.yaml;


/// Score screen shown when the game ends.
class ScoreScreen: SwappableGUI
{
private:
    // Root widget of the score screen GUI.
    RootWidget scoreGUI_;

    // Labels displaying death/success message, score, time elapsed, shots and kills.
    //
    // Every one of these is optional and might be null.
    LabelWidget deathMessageLabel_, scoreLabel_, timeLabel_, shotsLabel_, killsLabel_;

    /// Messages shown when the player dies.
    static deathMessages_ = ["You have been murderized",
                             "Fail",
                             "LOL U MAD?",
                             "All your base are belong to us",
                             "The trifurcator is exceptionally green",
                             "Cake is a lie",
                             "Swim, swim, hungry!",
                             "Snake? Snake?! SNAAAAAKE!!!!",
                             "42",
                             "You were killed",
                             "Longcat is looooooooooooooooooooooooooooooong",
                             "Delirious Biznasty",
                             ":o) hOnK",
                             "There's a cake in the toilet.",
                             "DIE FISH HITLER DIE!"
                                 "                                                                                "
                                 "I WONT LET YOU KILL MY PEOPLE!",
                             "I'm glasses.",
                             "You are dead"];

    /// Messages shown when the player successfully clears the level.
    static successMessages_ = ["Level cleared",
                               "You survived",
                               "Nice~",
                               "Still alive",
                               "You aren't quite dead yet",
                               "MoThErFuCkInG MiRaClEs",
                               "PCHOOOOOOOO!",
                               "where doing it man WHERE MAKING THIS HAPEN",
                               "42"];

public:
    /// Constructs the score screen.
    /// 
    /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
    ///         gameDir    = Game data directory.
    ///
    /// Throws: YAMLException on a YAML parsing error.
    ///         VFSException on a filesystem error.
    ///         GUIInitException on a GUI loading error.
    this(GUISystem guiSystem, VFSDir gameDir)
    {
        auto scoreGUIFile = gameDir.dir("gui").file("scoreGUI.yaml");
        scoreGUI_ = guiSystem.loadWidgetTree(loadYAML(scoreGUIFile));

        scoreLabel_        = scoreGUI_.score!(LabelWidget,        Yes.optional);
        timeLabel_         = scoreGUI_.time!(LabelWidget,         Yes.optional);
        shotsLabel_        = scoreGUI_.shots!(LabelWidget,        Yes.optional);
        killsLabel_        = scoreGUI_.kills!(LabelWidget,        Yes.optional);
        deathMessageLabel_ = scoreGUI_.deathMessage!(LabelWidget, Yes.optional);

        super(scoreGUI_);
    }

    /// Update the score screen data when the game ends.
    void update(GameOverData data)
    {
        if(deathMessageLabel_ !is null)
        {
            deathMessageLabel_.text =
                randomSample(data.gameWon ? successMessages_ : deathMessages_, 1).front;
        }
        const stats = data.playerStatistics;
        if(scoreLabel_ !is null){scoreLabel_.text = to!string(stats.expGained);}
        if(timeLabel_  !is null){timeLabel_.text  = format("%.1f s", data.totalTime);}
        if(shotsLabel_ !is null){shotsLabel_.text = to!string(stats.burstsFired);}
        if(killsLabel_ !is null){killsLabel_.text = to!string(stats.entitiesKilled);}
    }
}

/**
 * Class holding all GUI used by Game (HUD, etc.).
 */
class GameGUI
{
private:
    ///A reference to the GUI system.
    GUISystem guiSystem_;
    ///A reference to the GUI swapper.
    GUISwapper guiSwapper_;
    ///HUD.
    HUD hud_;
    ///Score screen shown when the game ends.
    ScoreScreen scoreScreen_;
    ///"Really quit?" screen shown when the player presses 'Esc'.
    PlainSwappableGUI quitScreen_;

public:
    /**
     * Construct a GameGUI with specified parameters.
     *
     * Params:  guiSystem  = A reference to the GUI system.
     *          guiSwapper = A reference to the GUI swapper.
     *          gameDir    = Game data directory to load GUI from.
     *
     * Throws:  GameStartException on failure.
     */
    this(GUISystem guiSystem, GUISwapper guiSwapper, VFSDir gameDir)
    {
        guiSystem_   = guiSystem;
        guiSwapper_  = guiSwapper;
        try
        {
            hud_             = new HUD(guiSystem_, gameDir);
            scoreScreen_     = new ScoreScreen(guiSystem_, gameDir);
            auto quitGUIFile = gameDir.dir("gui").file("quitGUI.yaml");
            auto quitYAML    = loadYAML(quitGUIFile);
            quitScreen_      = new PlainSwappableGUI(guiSystem.loadWidgetTree(quitYAML));
        }
        catch(VFSException e)
        {
            throw new GameStartException
                ("Failed to initialize HUD, score or quit screen: " ~ e.msg);
        }
        catch(YAMLException e)
        {
            throw new GameStartException
                ("Failed to initialize HUD, score or quit screen: " ~ e.msg);
        }
        catch(GUIInitException e)
        {
            throw new GameStartException
                ("Failed to initialize HUD, score or quit screen: " ~ e.msg);
        }
        guiSwapper_.addGUI(hud_,         "hud");
        guiSwapper_.addGUI(scoreScreen_, "scores");
        guiSwapper_.addGUI(quitScreen_,  "quit");
    }

    ///Destroy the game GUI.
    ~this()
    {
        if(quitScreenVisible)
        {
            hideQuitScreen();
        }
        guiSwapper_.removeGUI("hud");
        guiSwapper_.removeGUI("scores");
        guiSwapper_.removeGUI("quit");
        clear(hud_);
        clear(scoreScreen_);
        clear(quitScreen_);
    }

    /**
     * Update the game GUI, using game time subsystem to measure time.
     */
    void update(const GameTime gameTime)
    {
        hud_.update(gameTime);
    }

    ///Show the HUD.
    void showHUD()
    {
        guiSwapper_.setGUI("hud");
    }

    ///Set the message text on the bottom of the HUD for specified time in seconds.
    void messageText(string text, float time) 
    {
        hud_.messageText(text, time);
    }

    /**
     * Show the game over screen, with statistics, etc.
     *
     * Params:  data = Data about how the game ended.
     */
    void showGameOverScreen(ref const GameOverData data) 
    {
        scoreScreen_.update(data);
        guiSwapper_.setGUI("scores");
    }

    ///Show the "Really quit?" message.
    void showQuitScreen()
    in
    {
        assert(!quitScreenVisible, 
               "Trying to show the \"Really quit?\" message "
               "but it's already shown");
    }
    body
    {
        guiSwapper_.setGUI("quit");
    }

    ///Hide the "Really quit?" message.
    void hideQuitScreen()
    in
    {
        assert(quitScreenVisible, 
               "Trying to hide the \"Really quit?\" message "
               "but it's not shown");
    }
    body
    {
        guiSwapper_.setGUI("hud");
    }

    ///Is the "Really quit?" message shown?
    @property bool quitScreenVisible() const pure nothrow 
    {
        return guiSwapper_.currentGUIName == "quit";
    }

    ///Update player health display in the HUD. Must be at least 0 and at most 1.
    void updatePlayerHealth(float health)
    {
        hud_.updatePlayerHealth(health);
    }

    ///Update any player statistics related displays in the HUD.
    void updatePlayerStatistics(ref const StatisticsComponent statistics)
    {
        hud_.updatePlayerStatistics(statistics);
    }

    ///Update player weapon data (e.g. reloading) in the HUD.
    void updatePlayerWeapon(ref const WeaponComponent weapon)
    {
        hud_.updatePlayerWeapon(weapon);
    }
}

