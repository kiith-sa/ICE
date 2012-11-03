
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Classes related to campaigns.
module ice.campaign;


import std.array;
import std.conv;
import std.exception;
import std.stdio;
import std.typecons;

import dgamevfs._;

import ice.game;
import ice.level;
import ice.playerprofile;
import ice.guiswapper;
import gui2.guisystem;
import gui2.buttonwidget;
import gui2.rootwidget;
import gui2.slotwidget;
import util.signal;
import util.yaml;


/// Campaign selection GUI.
class CampaignsGUI: SwappableGUI
{
private:
    // Reference to the GUI system.
    GUISystem guiSystem_;

    // Campaigns GUI root widget.
    RootWidget campaignsGUI_;

    // Reference to the campaign manager.
    CampaignManager campaignManager_;

public:
    /// Construct a CampaignsGUI.
    ///
    /// This loads the widget tree.
    /// 
    /// Params: gui             = Reference to the GUI system to load widgets with.
    ///         campaignManager = CampaignManager this GUI is working with.
    ///         gameDir         = Game data directory to load the GUI from.
    ///
    /// Throws: GUIInitException on GUI loading failure.
    ///         VFSException if the GUI file/s could not be found.
    this(GUISystem gui, CampaignManager campaignManager, VFSDir gameDir)
    {
        scope(failure)
        {
            writeln("CampaignManager.this() or a callee failed");
        }

        guiSystem_       = gui;
        campaignManager_ = campaignManager;

        campaignsGUI_ =
            gui.loadWidgetTree(loadYAML(gameDir.dir("gui").file("campaignsGUI.yaml")));

        campaignsGUI_.back!ButtonWidget.pressed.connect({swapGUI_("ice");});

        campaignsGUI_.previous!ButtonWidget.pressed.connect(&previousCampaign);
        campaignsGUI_.next!ButtonWidget.pressed.connect(&nextCampaign);

        campaignsGUI_.campaign!ButtonWidget.pressed.connect(&showCampaign);
        campaignsGUI_.campaign!ButtonWidget.text =
            campaignManager_.currentCampaign.name;

        super(campaignsGUI_);
    }

private:
    // Show GUI for the selected campaign.
    void showCampaign()
    {
        //TODO 
    }

    // Change to the previous campaign.
    void previousCampaign()
    {
        campaignManager_.previousCampaign();
        campaignsGUI_.campaign!ButtonWidget.text =
            campaignManager_.currentCampaign.name;
    }

    // Change to the next campaign.
    void nextCampaign()
    {
        campaignManager_.nextCampaign();
        campaignsGUI_.campaign!ButtonWidget.text =
            campaignManager_.currentCampaign.name;
    }
}

/// GUI for a particular campaign, allowing to select the level to play.
class CampaignGUI
{
    // TODO by default, the next level is selected. 
    // Further levels can't be selected. Previous levels can.
    // Probably no wraparound to avoid confusing the player.
}

/// Exception thrown at campaign initialization errors.
class CampaignInitException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Loads and provides access to campaigns.
class CampaignManager
{
private:
    // Game data directory (level file names are relative to this directory).
    VFSDir gameDir_;

    // Campaigns directory.
    VFSDir campaignsDir_;

    // All loaded campaigns.
    Campaign[] campaigns_;

    // Index of the currently selected campaign in campaigns_.
    uint currentCampaign_;

public:
    /// Construct a CampaignManager.
    ///
    /// Loads campaigns from the campaigns/ directory.
    ///
    /// Params:  gameDir = Game data directory (parent of the campaigns/ directory).
    ///
    /// Throws:  CampaignInitException if the campaign directory doesn't exist 
    ///          or if a campaign could not be loaded (e.g. due to a YAML error).
    this(VFSDir gameDir)
    {
        try
        {
            campaignsDir_ = gameDir.dir("campaigns");
            gameDir_      = gameDir;
            loadCampaigns();
        }
        catch(YAMLException e)
        {
            const msg = "Couldn't init campaign manager due to a YAML error: " ~ e.msg;
            throw new CampaignInitException(msg);
        }
        catch(VFSException e)
        {
            const msg = "Couldn't init campaign manager due to a filesystem error: " ~ e.msg;
            throw new CampaignInitException(msg);
        }
    }

    /// Select the next campaign..
    void nextCampaign()
    {
        currentCampaign_ = (currentCampaign_ + 1) % campaigns_.length;
    }

    /// Select the previous campaign.
    void previousCampaign()
    {
        currentCampaign_ = (currentCampaign_ - 1) % campaigns_.length;
    }

    /// Get the currently selected campaign.
    Campaign currentCampaign()
    {
        return campaigns_[currentCampaign_];
    }

private:
    /// Load all campaigns in the campaigns directory.
    ///
    /// Called at initialization.
    ///
    /// Throws:  YAMLException on a YAML parsing error.
    ///          VFSException on a filesystem error.
    void loadCampaigns()
    {
        foreach(file; campaignsDir_.files)
        {
            campaigns_ ~= new Campaign(file.name, loadYAML(file), gameDir_);
        }
    }
}

/// Campaign; a series of levels played in order.
class Campaign
{
public:
    /// VFS file name of the campaign.
    string name;

private:
    /// Top level game data directory.
    VFSDir gameDir_;

    /// VFS file names of levels in the campaign.
    string[] levelNames_;

    /// Index of the currently selected level.
    uint currentLevel_ = 0;

public:
    /// Construct a Campaign.
    ///
    /// Params:  name    = Name of the campaign.
    ///          yaml    = YAML source of the campaign.
    ///          gameDir = Game data directory.
    /// 
    /// Throws:  CampaignInitException on failure.
    this(string name, YAMLNode yaml, VFSDir gameDir)
    {
        this.name  = name;
        gameDir_ = gameDir;
        try foreach(string levelName; yaml["levels"])
        {
            levelNames_ ~= levelName;
        }
        catch(YAMLException e)
        {
            throw new CampaignInitException("Failed to load campaign " ~ name ~
                                            " due to a YAML error: " ~ e.msg);
        }
        enforce(!levelNames_.empty,
                new CampaignInitException("No levels in campaign " ~ name));
    }

    /// Select the next level.
    void nextLevel()
    {
        currentLevel_ = (currentLevel_ + 1) % levelNames_.length;
    }

    /// Select the previous level.
    void previousLevel()
    {
        currentLevel_ = (currentLevel_ - 1) % levelNames_.length;
    }

    /// Get the index and name of the currently selected level.
    Tuple!(uint, string) currentLevel()
    {
        return tuple(currentLevel_, levelNames_[currentLevel_]);
    }

    /// Construct the currently selected (by GUI) level from the campaign.
    ///
    /// Params:  subsystems = Provides access to game subsystems to the level.
    ///          profile    = Profile of the player playing the level.
    ///
    /// Returns: Newly constructed level.
    ///
    /// Throws:  LevelInitException on failure.
    Level constructLevel(GameSubsystems subsystems, PlayerProfile profile)
    {
        const levelName = levelNames_[currentLevel_];
        try
        {
            return new DumbLevel(levelName, loadYAML(gameDir_.file(levelName)),
                                 subsystems, profile.playerShipSpawner);
        }
        catch(YAMLException e)
        {
            const msg = "Campaign " ~ name ~ " failed to construct level " ~
                        levelName ~ " due to a YAML error: " ~ e.msg;
            throw new LevelInitException(msg);
        }
        catch(VFSException e)
        {
            const msg = "Campaign " ~ name ~ " failed to construct level " ~
                        levelName ~ " due to a filesystem error: " ~ e.msg;
            throw new LevelInitException(msg);
        }
    }
}
