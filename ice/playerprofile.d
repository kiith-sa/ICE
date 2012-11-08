
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Classes related to player profiles.
module ice.playerprofile;

import std.algorithm;
import std.array;
import std.ascii: isAlphaNum;
import std.exception;
import std.stdio;
import std.string;
import std.typecons;

import dgamevfs._;

import gui2.guisystem;
import gui2.buttonwidget;
import gui2.lineeditwidget;
import gui2.rootwidget;
import gui2.slotwidget;
import ice.guiswapper;
import util.signal;
import util.unittests;
import util.yaml;

/// GUI frontend for the profile manager.
class ProfileGUI: SwappableGUI
{
private:
    // Reference to the GUI system.
    GUISystem guiSystem_;

    // Profile GUI root widget.
    RootWidget profileGUI_;

    // Root widget of the "add profile" dialog.
    RootWidget addProfileGUI_;

    // Reference to the profile manager (creating, deleting and accessing profiles).
    ProfileManager profileManager_;

    // Parent slot widget the profile GUI is connected to.
    SlotWidget parentSlot_;

public:
    /// Construct a ProfileGUI.
    ///
    /// This loads the widget tree.
    /// 
    /// Params: profileManager = ProfileManager this GUI is working with.
    ///         gui            = Reference to the GUI system to load widgets with.
    ///         parentSlot     = Parent slot widget of the profile GUI 
    ///                          (profile GUI internally swaps its main GUI 
    ///                          for dialogs connected here).
    ///         gameDir        = Game data directory to load the GUI from.
    ///
    /// Throws: GUIInitException on GUI loading failure.
    ///         VFSException if the GUI file/s could not be found.
    this(ProfileManager profileManager, GUISystem gui, SlotWidget parentSlot, VFSDir gameDir)
    {
        scope(failure)
        {
            writeln("ProfileManager.this() or a callee failed");
        }

        guiSystem_      = gui;
        profileManager_ = profileManager;
        parentSlot_     = parentSlot;

        {
            scope(failure)
            {
                writeln("ProfileManager.this() GUI loading failed");
            }
            profileGUI_ = gui.loadWidgetTree(loadYAML(gameDir.dir("gui").file("profileGUI.yaml")));
            super(profileGUI_);

            auto addProfileSource = gameDir.dir("gui").file("addProfileGUI.yaml");
            auto addProfileYAML   = loadYAML(addProfileSource);
            addProfileGUI_ = gui.loadWidgetTree(addProfileYAML);
        }
        {
            scope(failure)
            {
                writeln("ProfileManager.this() signal connection failed");
            }
            bool validChar(dchar c){return isAlphaNum(c) || c == '_';}
            addProfileGUI_.profileNameEdit!LineEditWidget.textEntered.connect(&processProfileName);
            addProfileGUI_.profileNameEdit!LineEditWidget.characterFilter = &validChar;
            profileGUI_.newProfile!ButtonWidget.pressed.connect(&showAddNewProfile);
            profileGUI_.deleteProfile!ButtonWidget.pressed.connect(&deleteCurrentProfile);
            profileGUI_.back!ButtonWidget.pressed.connect({swapGUI_("ice");});

            profileGUI_.previous!ButtonWidget.pressed.connect(&previousProfile);
            profileGUI_.next!ButtonWidget.pressed.connect(&nextProfile);

            profileGUI_.profile!ButtonWidget.pressed.connect(&showProfileDetails);
            profileGUI_.profile!ButtonWidget.text = profileManager_.currentProfile.name;
        }
    }

private:
    // Show the dialog to add new profile (enter name, etc.)
    void showAddNewProfile()
    {
        parentSlot_.disconnect(profileGUI_);
        parentSlot_.connect(addProfileGUI_);
        guiSystem_.focusedWidget = addProfileGUI_.profileNameEdit!LineEditWidget;
    }

    // Process profile name input from the addProfileGUI dialog.
    void processProfileName(string name)
    {
        parentSlot_.disconnect(addProfileGUI_);
        parentSlot_.connect(profileGUI_);
        if(profileManager_.createProfile(name))
        {
            while(profileManager_.currentProfile.name != name)
            {
                nextProfile();
            }
        }
    }

    // Show the profile details GUI screen.
    void showProfileDetails()
    {
        //TODO custom screen showing:
        //     campaign progress,
        //     ship modifications,
        //     player ships killed,
        //     total shots fired,
        //     total hits,
        //     score
    }

    // Delete the currently selected profile.
    //
    // This can fail silently (e.g. if this is the last profile).
    void deleteCurrentProfile()
    {
        try
        {
            profileManager_.deleteProfile(profileManager_.currentProfile);
            profileGUI_.profile!ButtonWidget.text = profileManager_.currentProfile.name;
        }
        catch(ProfileException e)
        {
            writeln("Could not delete profile " ~ 
                    profileManager_.currentProfile.name ~ ": " ~ e.msg);
        }
    }

    // Change to the previous profile.
    void previousProfile()
    {
        profileManager_.previousProfile();
        profileGUI_.profile!ButtonWidget.text = profileManager_.currentProfile.name;
    }

    // Change to the next profile.
    void nextProfile()
    {
        profileManager_.nextProfile();
        profileGUI_.profile!ButtonWidget.text = profileManager_.currentProfile.name;
    }
}

///Exception thrown at player profile related errors.
class ProfileException : Exception 
{
    public this(string msg, string file = __FILE__, int line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// Loads, saves, and provides access to player profiles.
class ProfileManager 
{
    private:
        // Directory storing player profile subdirectories.
        VFSDir profilesDir_;
        // All loaded/created player profiles.
        PlayerProfile[] profiles_;
        // Index of the current profile in profiles_.
        uint currentProfileIndex_;

    public:
        /// Emitted when the selected player profile changes, passing the profile.
        mixin Signal!(PlayerProfile) changedProfile;

        /// Construct a ProfileManager.
        ///
        /// Loads profiles from the profiles/ directory.
        /// Creates the directory if it does not exist.
        ///
        /// Params:  gameDir = Game directory (parent of the profiles/ directory).
        ///
        /// Throws: ProfileException if the profile directory could not be read 
        ///         or on a YAML error.
        this(VFSDir gameDir)
        {
            try
            {
                profilesDir_ = gameDir.dir("profiles");
                if(!profilesDir_.exists) {profilesDir_.create();}
                loadProfiles();
            }
            catch(YAMLException e)
            {
                throw new ProfileException("Failed to initialize ProfileManager "
                                           "due to a YAML error: " ~ e.msg);
            }
            catch(VFSException e)
            {
                throw new ProfileException(
                    "Failed to initialize ProfileManager due to a filesystem "
                    "error (maybe no read/write permissions?) : " ~ e.msg);
            }
            if(profiles_.empty)
            {
                createProfile("Default");
                currentProfileIndex_ = 0;
                save();
            }
        }

        /// Save the current state of all profiles. 
        ///
        /// Should be called before destruction.
        ///
        /// Throws:  ProfileException if the profiles directory could not be written to.
        void save()
        {
            try
            {
                auto profileCfgFile = profilesDir_.file("profiles.yaml");
                auto outMapping = YAMLNode(["currentProfileIndex"], [currentProfileIndex_]);
                saveYAML(profileCfgFile, outMapping);
            }
            catch(VFSException e)
            {
                throw new ProfileException(
                    "Failed to save ProfileManager data due to a filesystem "
                    "error (maybe no read/write permissions?) : " ~ e.msg);
            }
            catch(YAMLException)
            {
                assert(false, "YAML exception at ProfileManager writing; " ~
                              "this shouldn't happen");
            }
            foreach(profile; profiles_)
            {
                profile.save();
            }
        }

        /// Get the number of player profiles.
        @property size_t profileCount() const pure nothrow
        {
            return profiles_.length;
        }

        /// Get the current profile.
        @property PlayerProfile currentProfile() pure nothrow 
        {
            return profiles_[currentProfileIndex_];
        }

        /// Switch to the next profile.
        void nextProfile()
        {
            currentProfileIndex_ = (currentProfileIndex_ + 1) % profiles_.length;
            changedProfile.emit(currentProfile);
        }

        /// Switch to the previous profile.
        void previousProfile()
        {
            currentProfileIndex_ = 
                (cast(uint)profiles_.length + currentProfileIndex_ - 1) % profiles_.length;
            changedProfile.emit(currentProfile);
        }

        /// Delete specified profile.
        ///
        /// This will delete the profile directory.
        ///
        /// Params:  profile = Profile to delete. Must be in the ProfileManager.
        ///
        /// Throws:  ProfileException if the profile directory could not be
        ///          deleted or if this was the last profile.
        void deleteProfile(PlayerProfile profile)
        {
            // Not using std.algorithm to avoid a DMD ICE in release builds.
            size_t removeIdx = size_t.max;
            foreach(i, p; profiles_) if(p is profile)
            {
                removeIdx = i;
                break;
            }
            assert(removeIdx != size_t.max,
                   "Trying to delete a profile not present in ProfileManager");

            try
            {
                profile.profileDir_.remove();
            }
            catch(VFSException e)
            {
                throw new ProfileException
                    ("Failed to delete profile directory " ~ profile.name ~
                     " (maybe no write permission?)");
            }

            enforce(profiles_.length > 1,
                    new ProfileException("Can't remove the last remaining profile'"));

            profiles_[removeIdx + 1 .. $].moveAll(profiles_[removeIdx .. $ - 1]);
            profiles_ = profiles_[0 .. $ - 1];
            currentProfileIndex_ = currentProfileIndex_ % profiles_.length;
        }

        /// Create a new profile.
        ///
        /// Params:  name = Name of the profile. 
        ///
        /// Returns: true if the profile was succesfully created, false if the 
        ///          profile with this name already exists or if the name is 
        ///          invalid (all characters must be alphanumeric or '_').
        ///
        /// Throws:  ProfileException if the profile directory could not be
        ///          created.
        bool createProfile(const string name)
        {
            // Profile names can only contain alphanumeric chars and '_'
            static bool inValidChar(dchar c){return !isAlphaNum(c) && c != '_';}
            if(name.canFind!inValidChar())
            {
                return false;
            }

            // Not using std.algorithm to avoid a DMD ICE in release builds.
            // Case insensitive for Windows compatibility
            foreach(p; profiles_) if(p.name.toLower() == name.toLower())
            {
                // Already existing profile name.
                return false;
            }
            profiles_ ~= new PlayerProfile(name, profilesDir_.dir(name));
            return true;
        }

    private:
        // Load existing player profiles (called at startup).
        void loadProfiles()
        {
            writeln("Loading player profiles");
            auto profileCfgFile = profilesDir_.file("profiles.yaml");
            if(!profileCfgFile.exists)
            {
                currentProfileIndex_ = 0;
            }
            else
            {
                YAMLNode config      = loadYAML(profileCfgFile);
                currentProfileIndex_ = config["currentProfileIndex"].as!uint;
            }

            foreach(dir; profilesDir_.dirs)
            {
                writeln("Loading profile ", dir.name);
                profiles_ ~= new PlayerProfile(dir.name, dir);
            }

            if(currentProfileIndex_ >= profiles_.length)
            {
                currentProfileIndex_ = 0;
            }
        }
}
void unittestProfileManager()
{
    VFSDir unittestDir = new FSDir("__unittest__", "__unittest__", Yes.writable);
    unittestDir.create();
    scope(exit) {unittestDir.remove();}

    auto manager = new ProfileManager(unittestDir);
    auto profilesDir = unittestDir.dir("profiles");
    assert(profilesDir.exists, "Profiles directory was not created");
    assert(manager.profileCount == 1 && manager.currentProfileIndex_ == 0 && 
           manager.currentProfile.name == "Default",
           "Default profile not created correctly");
    auto defaultDir = profilesDir.dir("Default");
    auto profilesCfg = profilesDir.file("profiles.yaml");
    assert(defaultDir.exists, "Default profile directory was not created");
    assert(profilesCfg.exists, "Profiles configuration file was not created");

    manager.nextProfile();
    assert(manager.currentProfile.name == "Default", 
           "Profiles wraparound does not work correctly");
    manager.nextProfile();
    assert(manager.currentProfile.name == "Default", 
           "Profiles wraparound does not work correctly");
    manager.previousProfile();
    assert(manager.currentProfile.name == "Default", 
           "Profiles wraparound does not work correctly");
    manager.previousProfile();
    assert(manager.currentProfile.name == "Default", 
           "Profiles wraparound does not work correctly");

    // Can't delete last remaining profile 
    bool thrown = false;
    try {manager.deleteProfile(manager.currentProfile);}
    catch(ProfileException e){thrown = true;}
    assert(manager.profileCount == 1 && thrown, 
           "ProfileManager deleted last remaining profile");

    assert(manager.createProfile("A"), "Failed to create profile A");
    assert(manager.createProfile("B"), "Failed to create profile B");
    assert(manager.createProfile("C"), "Failed to create profile C");
    assert(!manager.createProfile("A"), "Created a duplicate profile");
    assert(!manager.createProfile("%"), "Created a profile with an invalid name");
    manager.deleteProfile(manager.currentProfile);
    assert(manager.profileCount == 3, "Unexpected profile count");
    assert(manager.currentProfile.name == "A",
           "Current profile not changed correctly after deletion");
    assert(profilesDir.dir("A").exists && 
           profilesDir.dir("B").exists && 
           profilesDir.dir("C").exists, 
           "New profile directories weren't created");
    assert(!defaultDir.exists, "Profile directory not deleted with the profile");
    manager.nextProfile();
    assert(manager.currentProfile.name == "B", "nextProfile() works incorrectly");
    manager.nextProfile();
    assert(manager.currentProfile.name == "C", "nextProfile() works incorrectly");
    manager.nextProfile();
    assert(manager.currentProfile.name == "A", "nextProfile() works incorrectly");
    manager.previousProfile();
    assert(manager.currentProfile.name == "C", "previousProfile() works incorrectly");
    manager.previousProfile();
    assert(manager.currentProfile.name == "B", "previousProfile() works incorrectly");
    manager.previousProfile();
    assert(manager.currentProfile.name == "A", "previousProfile() works incorrectly");

    clear(manager);

    manager = new ProfileManager(unittestDir);
    assert(manager.profileCount == 3, "Either profile saving or loading went wrong");
    uint a, b, c;
    a = b = c = 0;
    foreach(p; 0 .. manager.profileCount)
    {
        manager.nextProfile();
        switch(manager.currentProfile.name)
        {
            case "A": ++a; break;
            case "B": ++b; break;
            case "C": ++c; break;
            default:
                assert(false, "Unexpected profile: " ~ manager.currentProfile.name);
        }
    }
    assert(a == 1 && b == 1 && c == 1,
           "Loaded profiles don't match previously created profiles");
}
mixin registerTest!(unittestProfileManager, "std.playerprofile.ProfileManager");


/// Player profile, handling things such as campaign progress and ship modifications.
class PlayerProfile
{
public:
    // Name of the player.
    const string name;

private:
    // Progress for campaigns this player has played.
    //
    // Triplets of VFS campaign name, human-readable campaign name, level.
    Tuple!(string, string, uint)[] campaignProgress_;

    // Spawner entity that will modify playership at spawn time.
    // 
    // This makes an RPG system possible.
    YAMLNode playerShipSpawner_;

    // Directory storing the profile data.
    VFSDir profileDir_;

public:
    /// Get the entity that will spawn the player ship and modify it at spawn time.
    @property YAMLNode playerShipSpawner() pure nothrow {return playerShipSpawner_;}

    /// Get progress in a campaign.
    ///
    /// Params:   vfsName   = Virtual file system of the campaign. If multiple
    ///                       campaigns have the same human readable name, this is
    ///                       used to determine which one should be used.
    ///           humanName = Human readable name of the campaign.
    ///
    /// Returns:  Current level in the campaign.
    uint campaignProgress(string vfsName, string humanName) const pure nothrow 
    {
        uint result = uint.max;
        // Handles even renamed files; but if both vfs and human names match,
        // we have a definite match.
        foreach(i, ref triplet; campaignProgress_) if(triplet[1] == humanName)
        {
            result = triplet[2];
            if(triplet[0] == vfsName) {return result;}
        }
        if(result == uint.max)
        {
            // Default starting level in a campaign
            return 0;
        }
        return result;
    }

    /// Set progress for a campaign.
    ///
    /// Params:  vfsName   = Virtual file system of the campaign. If multiple
    ///                      campaigns have the same human readable name, this is
    ///                      used to determine which one should be used.
    ///          humanName = Human readable name of the campaign.
    ///          progress  = Campaign progress (current level) to set.
    void campaignProgress(string vfsName, string humanName, uint progress) 
        @safe pure nothrow
    {
        foreach(ref triplet; campaignProgress_)
        {
            if(triplet[0] == vfsName && triplet[1] == humanName)
            {
                triplet[2] = progress;
                return;
            }
        }

        campaignProgress_ ~= tuple(vfsName, humanName, progress);
    }

private:
    // Construct a PlayerProfile.
    //
    // If profileDir exists, the profile is loaded from that directory.
    // Otherwise, profileDir is created and a new profile is created within.
    //
    // Params:  name       = Name of the profile.
    //          profileDir = Directory storing the profile 
    //                       (or to store the profile in).
    //
    // Throws:  ProfileException if the profile failed to load or could not be 
    //          created. 
    this(string name, VFSDir profileDir)
    {
        // Create a new player profile with a spawner that does not modify the player ship.
        void createNew()
        {
            playerShipSpawner_ = 
                loadYAML("spawner:\n" ~
                        "  - entity: ships/playerShip.yaml\n" ~
                        "    condition: spawn\n" ~
                        "    spawnerIsOwner: false\n" ~
                        "    components:\n" ~
                        "        physics:\n" ~
                        "          position: [400, 536]\n" ~
                        "          rotation: 3.141593\n" ~
                        "        statistics:\n"  ~
                        "        player: 0\n"    ~ 
                        "        tags: [_PLR]\n" ~ 
                        "        controller:\n"  ~
                        "        spawner: []");
            save();
        }

        this.name = name;
        profileDir_ = profileDir;
        try if(profileDir_.exists)
        {
            // Load campaign progress
            auto progressFile = profileDir_.file("playerProgress.yaml");
            if(progressFile.exists)
            {
                foreach(YAMLNode campaign; loadYAML(progressFile)["campaignProgress"])
                {
                    campaignProgress_ ~= tuple(campaign["name"].as!string,
                                               campaign["humanName"].as!string,
                                               campaign["progress"].as!uint);
                }
            }
            auto spawnerFile = profileDir_.file("playerShipSpawner.yaml");
            if(spawnerFile.exists)
            {
                playerShipSpawner_ = loadYAML(spawnerFile);
                return;
            }
        }
        catch(YAMLException e)
        {
            throw new ProfileException("Failed to load profile " ~ name ~
                                       " due to a YAML error: " ~ e.msg);
        }
        catch(VFSException e)
        {
            throw new ProfileException(
                "Failed to load profile " ~ name ~ " due to a file system "
                "error (maybe no permission to read/write?): " ~ e.msg);
        }
        createNew();
    }

    // Save current state of the profile to its directory.
    void save()
    {
        if(!profileDir_.exists) {profileDir_.create();}

        try
        {
            auto spawnerFile  = profileDir_.file("playerShipSpawner.yaml");
            auto progressFile = profileDir_.file("playerProgress.yaml");

            saveYAML(spawnerFile, playerShipSpawner_);
            // Save player progress to YAML.
            YAMLNode[] progressSequence;
            foreach(ref triplet; campaignProgress_)
            {
                auto nameYAML      = YAMLNode(triplet[0]);
                auto humanNameYAML = YAMLNode(triplet[1]);
                auto progressYAML  = YAMLNode(triplet[2]);
                progressSequence ~= YAMLNode(["name", "humanName", "progress"],
                                             [nameYAML, humanNameYAML, progressYAML]);
            }
            auto progressYAML = YAMLNode(["campaignProgress"], [YAMLNode(progressSequence)]);
            saveYAML(progressFile, progressYAML);
        }
        catch(VFSException e)
        {
            throw new ProfileException(
                "Failed to save profile " ~ name ~ " due to a file system "
                "error (maybe no permission to read/write?):" ~ e.msg);
        }
        catch(YAMLException e)
        {
            assert(false, 
                   "YAML exception at profile writing - this shouldn't happen: " ~ e.msg);
        }
    }
}
void unittestPlayerProfile()
{
    bool testSpawner(PlayerProfile p)
    {
        try
        {
            return p.playerShipSpawner_["spawner"][0]["entity"].as!string 
                == "ships/playerShip.yaml";
        }
        catch(Exception e)
        {
            writeln("PlayerProfile playerShipSpawner test failed: ", e.msg);
            return false;
        }
    }

    VFSDir unittestDir = new FSDir("__unittest__", "__unittest__", Yes.writable);
    unittestDir.create();
    scope(exit) {unittestDir.remove();}

    auto profilesDir = unittestDir.dir("profiles");
    profilesDir.create();
    auto profileDir = profilesDir.dir("player");

    // New profile
    auto profile = new PlayerProfile("player", profileDir);

    assert(profileDir.exists, "PlayerProfile didn't create its profile dir");
    assert(profileDir.file("playerShipSpawner.yaml").exists,
           "PlayerProfile didn't create its playerShipSpawner file");
    assert(testSpawner(profile), "New playerShipSpawner has unexpected contents");

    clear(profile);

    // Existing profile
    profile = new PlayerProfile("player", profileDir);
    assert(testSpawner(profile), "Loaded playerShipSpawner has unexpected contents");
}
mixin registerTest!(unittestPlayerProfile, "std.playerprofile.PlayerProfile");
