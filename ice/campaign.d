
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Classes related to campaigns.
module ice.campaign;


import std.algorithm;
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
            campaignManager_.currentCampaign.humanName;

        super(campaignsGUI_);
    }

private:
    // Show GUI for the selected campaign.
    void showCampaign()
    {
        swapGUI_("campaign");
    }

    // Change to the previous campaign.
    void previousCampaign()
    {
        campaignManager_.previousCampaign();
        campaignsGUI_.campaign!ButtonWidget.text =
            campaignManager_.currentCampaign.humanName;
    }

    // Change to the next campaign.
    void nextCampaign()
    {
        campaignManager_.nextCampaign();
        campaignsGUI_.campaign!ButtonWidget.text =
            campaignManager_.currentCampaign.humanName;
    }
}

/// GUI for a particular campaign, allowing to select the level to play.
class CampaignGUI: SwappableGUI
{
private:
    // Root widget of the campaign GUI.
    RootWidget campaignGUI_;

    // Profile of the player playing the game. Might change while this GUI is hidden.
    PlayerProfile playerProfile_;

    // Displayed campaign. Might change while this GUI is hidden.
    Campaign campaign_;

    // Called to initialize the game.
    //
    // The first parameter is the level to start, the second is the 
    // delegate that will be called by the game when the level ends.
    void delegate(ref YAMLNode, void delegate(GameOverData)) initGame_;

public:
    /// Initialize the campaign GUI.
    ///
    /// Params:  gui           = GUI system to load widgets.
    ///          gameDir       = Game data directory.
    ///          campaign      = The first selected campaign.
    ///          playerProfile = Player currently playing the game.
    ///          initGame      = Function called to initialize game, passing 
    ///                          the source of level to play, and a delegate
    ///                          for the game to call when the level ends.
    ///
    /// Throws:  VFSException on a filesystem error.
    ///          GUIInitException if the GUI could not be loaded.
    this(GUISystem gui, VFSDir gameDir, Campaign campaign, 
         PlayerProfile playerProfile, 
         void delegate(ref YAMLNode, void delegate(GameOverData)) initGame)
    {
        initGame_      = initGame;
        campaign_      = campaign;
        playerProfile_ = playerProfile;
        campaignGUI_   = 
            gui.loadWidgetTree(loadYAML(gameDir.dir("gui").file("campaignGUI.yaml")));
        campaignGUI_.back!ButtonWidget.pressed.connect({swapGUI_("campaigns");});
        campaignGUI_.previous!ButtonWidget.pressed.connect(&previousLevel);
        campaignGUI_.next!ButtonWidget.pressed.connect(&nextLevel);
        campaignGUI_.level!ButtonWidget.pressed.connect(&startLevel);
        super(campaignGUI_);
        resetLevel();
    }

private:
    // Start playing the currently selected level.
    void startLevel()
    {
        const name        = campaign_.name;
        const humanName   = campaign_.humanName;
        const oldProgress = playerProfile_.campaignProgress(name, humanName);
        const lastAccessibleLevel = campaign_.currentLevel[0] == oldProgress;
        // Called when the game ends. If the player has won, increase campaign progress.
        void processGameOver(GameOverData data)
        {
            if(lastAccessibleLevel && data.gameWon)
            {
                playerProfile_.campaignProgress(name, humanName, oldProgress + 1);
                resetLevel();
            }
        }
        initGame_(campaign_.currentLevel[2], &processGameOver);
    }

    // Change to the previous level.
    void previousLevel()
    {
        // No wraparound.
        if(campaign_.currentLevel[0] >= 1)
        {
            campaign_.previousLevel();
            campaignGUI_.level!ButtonWidget.text = 
                campaign_.currentLevel[2]["name"].as!string;
        }
    }

    // Change to the next level.
    void nextLevel()
    {
        const campaignProgress =
            playerProfile_.campaignProgress(campaign_.name, campaign_.humanName);
        // No wraparound, and don't allow the player to skip levels.
        if(campaign_.currentLevel[0] < min(campaign_.length - 1, campaignProgress))
        {
            campaign_.nextLevel();
            campaignGUI_.level!ButtonWidget.text = 
                campaign_.currentLevel[2]["name"].as!string;
        }
    }

    // Change the selected campaign (called by campaign manager).
    @property void campaign(Campaign campaign)
    {
        campaign_ = campaign;
        resetLevel();
    }

    // Change the player profile, i.e. the player playing the game (called by profile manager).
    @property void playerProfile(PlayerProfile profile)
    {
        playerProfile_ = profile;
        resetLevel();
    }

    // Reset the currently selected level.
    //
    // Called when the campaign or player profile changes.
    void resetLevel()
    {
        auto level = min(campaign_.length - 1,
                         playerProfile_.campaignProgress(campaign_.name, campaign_.humanName));
        while(campaign_.currentLevel[0] != level)
        {
            campaign_.nextLevel();
        }
        campaignGUI_.level!ButtonWidget.text = 
            campaign_.currentLevel[2]["name"].as!string;
    }
}

/// Exception thrown at campaign initialization errors.
class CampaignInitException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Exception thrown when campaign related data saving fails.
class CampaignSaveException : Exception 
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
    /// Emitted when the selected campaign changes, passing the newly selected campaign.
    mixin Signal!(Campaign) changedCampaign;

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

    /// Save campaigns configuration (e.g. currently selected campaign).
    void save()
    {
        try
        {
            auto campaign = campaigns_[currentCampaign_];
            auto campaignConfig = 
                loadYAML("currentCampaign:\n" ~ 
                         "    name: '" ~ campaign.name ~ "'\n" ~
                         "    humanName: '" ~ campaign.humanName ~ "'\n");
            saveYAML(gameDir_.file("campaigns.yaml"), campaignConfig);
        }
        catch(VFSException e)
        {
            throw new CampaignSaveException
                ("Failed to save campaigns config due to a filesystem error: " ~ e.msg);
        } 
        catch(YAMLException)
        {
            assert(false, "YAMLException at campaigns config writing; this shouldn't happen");
        }
    }

    /// Select the next campaign..
    void nextCampaign()
    {
        currentCampaign_ = (currentCampaign_ + 1) % campaigns_.length;
        changedCampaign.emit(currentCampaign);
    }

    /// Select the previous campaign.
    void previousCampaign()
    {
        currentCampaign_ = (currentCampaign_ - 1) % campaigns_.length;
        changedCampaign.emit(currentCampaign);
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
            writeln("Loading campaign " ~ file.name);
            campaigns_ ~= new Campaign(file.name, loadYAML(file), gameDir_);
        }
        auto campaignsFile    = gameDir_.file("campaigns.yaml");
        if(!campaignsFile.exists)
        {
            return;
        }

        auto campaignsConfig  = loadYAML(campaignsFile);
        auto currentCampaign  = campaignsConfig["currentCampaign"];
        auto currentName      = currentCampaign["name"].as!string;
        auto currentHumanName = currentCampaign["humanName"].as!string;
        foreach(i, campaign; campaigns_)
        {
            const nameMatches = currentName == campaign.name;
            const humanNameMatches = currentHumanName == campaign.humanName;
            // Determine the last selected campaign,
            // handling campaign file renaming.
            if(humanNameMatches)
            {
                // Human name matches, but if this happens with more 
                // campaigns, wait for the one where file name matches as well.
                currentCampaign_ = cast(uint)i;
                // Full match
                if(nameMatches) {break;}
            }
        }
    }
}

/// Campaign; a series of levels played in order.
class Campaign
{
public:
    /// VFS file name of the campaign.
    const string name;

    /// Human readable name of the campaign.
    const string humanName;

private:
    /// Top level game data directory.
    VFSDir gameDir_;

    /// VFS file names of levels in the campaign.
    string[] levelNames_;

    /// YAML sources of levels in the campaign.
    YAMLNode[] levelSources_;

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
    this(const string name, YAMLNode yaml, VFSDir gameDir)
    {
        this.name  = name;
        this.humanName = yaml["name"].as!string;
        gameDir_ = gameDir;
        try foreach(string levelName; yaml["levels"])
        {
            levelNames_   ~= levelName;
            levelSources_ ~= loadYAML(gameDir.file(levelName));
        }
        catch(YAMLException e)
        {
            throw new CampaignInitException("Failed to load campaign " ~ name ~
                                            " due to a YAML error: " ~ e.msg);
        }
        catch(VFSException e)
        {
            throw new CampaignInitException("Failed to load campaign " ~ name ~ 
                                            " due to a filesystem error: " ~ e.msg);
        }
        enforce(!levelNames_.empty,
                new CampaignInitException("No levels in campaign " ~ name));
    }

    /// Select the next level.
    void nextLevel()
    {
        currentLevel_ = (currentLevel_ + 1) % length;
    }

    /// Select the previous level.
    void previousLevel()
    {
        currentLevel_ = (currentLevel_ - 1) % length;
    }

    /// Get the number of levels in the campaign.
    @property size_t length() const pure nothrow {return levelNames_.length;}

    /// Get the index, name and YAML source of the currently selected level.
    Tuple!(uint, string, YAMLNode) currentLevel()
    {
        return tuple(currentLevel_, levelNames_[currentLevel_], 
                     levelSources_[currentLevel_]);
    }
}
