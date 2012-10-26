
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

import gui.guibutton;
import gui.guielement;
import gui.guimenu;
import gui2.guisystem;
import gui2.buttonwidget;
import gui2.rootwidget;
import gui2.slotwidget;
import platform.platform;
import util.signal;
import util.unittests;
import util.yaml;

/// GUI frontend for the profile manager.
class ProfileGUI
{
private:
    // Profile GUI root widget.
    RootWidget profileGUI_;

    // Reference to the profile manager (creating, deleting and accessing profiles).
    ProfileManager profileManager_;

    // Parent slot widget the profile GUI is connected to.
    SlotWidget parentSlot_;

public:
    /// Emitted when the profile manager GUI should be exited.
    mixin Signal!() back;

    /// Construct a ProfileGUI.
    ///
    /// This loads the widget tree.
    /// 
    /// Params: profileManager = ProfileManager this GUI is working with.
    ///         gui            = Reference to the GUI system to load widgets with.
    ///         parentSlot     = Parent slot widget to connect the profile GUI to.
    ///
    /// Throws: GUIInitException on failure.
    this(ProfileManager profileManager, GUISystem gui, SlotWidget parentSlot)
    {
        profileManager_ = profileManager;
        parentSlot_     = parentSlot;

        string guiString =
            "!!pairs\n" ~
            "- styleManager: line\n" ~
            "- layoutManager: boxManual #parent/window width/height/top/left/etc\n" ~
            "- layout: {x: 'pLeft', y: 'pTop', w: 'pWidth', h: 'pHeight'}\n" ~
            "#Main container\n" ~
            "- widget container:\n" ~
            "    !!pairs\n" ~
            "    - style:\n" ~
            "        lineWidth: 2.0\n" ~
            "        lineColor: rgbaC0C0FFB0\n" ~
            "    - layout: {x: 'pRight - 176', y: 16, w: 160, h: 'pBottom - 32'}\n" ~
            "    #Profile action menu\n" ~
            "    - widget container:\n" ~
            "        !!pairs\n" ~
            "        - style: {drawBorder: false}\n" ~
            "        - layout: {x: pLeft, y: 'pTop + 136', w: 'pWidth', h: '24 * 3 + 8 * 4'}\n" ~
            "        - widget button newProfile:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pLeft + 8', y: 'pTop + 8', w: pWidth - 16, h: 24}\n" ~
            "            - text: NewProfile\n" ~
            "        - widget button deleteProfile:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pLeft + 8', y: 'pTop + 40', w: pWidth - 16, h: 24}\n" ~
            "            - text: Delete Profile\n" ~
            "        - widget button back:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pLeft + 8', y: 'pTop + 72', w: pWidth - 16, h: 24}\n" ~
            "            - text: Back\n" ~
            "    #Profile selector container\n" ~
            "    - widget container:\n" ~
            "        !!pairs\n" ~
            "        - layout: {x: pLeft, y: 'pTop + 272', w: pWidth, h: '24 + 8 * 2'}\n" ~
            "        - style: {drawBorder : false}\n" ~
            "        - widget button previous:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pLeft + 8', y: 'pTop + 8', w: 12, h: 24}\n" ~
            "            - text: '<'\n" ~
            "        - widget button profile:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pLeft + 24', y: 'pTop + 8', w: 'pRight - pLeft - 48', h: 24}\n" ~
            "            - text: DUMMY\n" ~
            "        - widget button next:\n" ~
            "            !!pairs\n" ~
            "            - layout: {x: 'pRight - 20', y: 'pTop + 8', w: 12, h: 24}\n" ~
            "            - text: '>'\n";
        profileGUI_ = gui.loadWidgetTree(loadYAML(guiString));

        profileGUI_.newProfile!ButtonWidget.pressed.connect(&showAddNewProfile);
        profileGUI_.deleteProfile!ButtonWidget.pressed.connect(&showAddNewProfile);
        profileGUI_.back!ButtonWidget.pressed.connect(&hide);

        profileGUI_.previous!ButtonWidget.pressed.connect(&previousProfile);
        profileGUI_.next!ButtonWidget.pressed.connect(&nextProfile);

        profileGUI_.profile!ButtonWidget.pressed.connect(&showProfileDetails);
        profileGUI_.profile!ButtonWidget.text = profileManager_.currentProfile.name;
    }

    /// Show the GUI on screen.
    ///
    /// The caller must first disconnect any RootWidget connected to the parent 
    /// slot widget.
    void show()
    {
        assert(parentSlot_.free, "Trying to show Profile GUI but previously connected RootWidget was not disconnected");
        parentSlot_.connect(profileGUI_);
    }

private:
    // Hide the profile GUI (when the "back" button is clicked).
    void hide()
    {
        parentSlot_.disconnect(profileGUI_);
        back.emit();
    }

    // Show the dialog to add new profile (enter name, etc.)
    void showAddNewProfile()
    {
        //TODO (after other GUI tested) GUI to add a profile
    }

    // Show the profile details GUI screen.
    void showProfileDetails()
    {
        //TODO (After campaign)
        //     custom screen showing:
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
                saveYAML(profileCfgFile,
                         YAMLNode(["currentProfileIndex"], [currentProfileIndex_]));
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
        void nextProfile() pure nothrow
        {
            currentProfileIndex_ = (currentProfileIndex_ + 1) % profiles_.length;
        }

        /// Switch to the previous profile.
        void previousProfile() pure nothrow
        {
            currentProfileIndex_ = 
                (cast(uint)profiles_.length + currentProfileIndex_ - 1) % profiles_.length;
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
            bool matchingProfile(PlayerProfile p){return p is profile;}
            assert(profiles_.canFind!matchingProfile(),
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

            profiles_ = remove!matchingProfile(profiles_);
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
            bool validChar(dchar c){return !isAlphaNum(c) && c != '_';}
            if(name.canFind!validChar())
            {
                return false;
            }

            // Case insensitive for Windows compatibility
            bool existing(ref PlayerProfile p){return p.name.toLower() == name.toLower();}
            if(profiles_.canFind!existing())
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
                profiles_ ~= new PlayerProfile(dir.name, dir);
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
    //TODO use in level (note - level must still set the position)
    //TODO (once campaigns work) progress in campaigns

    /*
     * Spawner entity that will modify playership at spawn time.
     *
     * This makes an RPG system possible.
     */
    YAMLNode playerShipSpawner_;

    // Directory storing the profile data.
    VFSDir profileDir_;

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
            // spawner:
            //   - entity: ships/playerShip.yaml
            auto spawn  = YAMLNode([YAMLNode(["entity"], ["ships/playerShip.yaml"])]);
            playerShipSpawner_ = YAMLNode(["spawner"], [spawn]);
            save();
        }

        this.name = name;
        profileDir_ = profileDir;
        try if(profileDir_.exists)
        {
            auto spawnerFile = profileDir_.file("playerShipSpawner.yaml");
            if(spawnerFile.exists())
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
            auto spawnerFile = profileDir_.file("playerShipSpawner.yaml");
            saveYAML(spawnerFile, playerShipSpawner_);
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
