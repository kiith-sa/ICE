
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Main pong program class.
module ice.ice;


import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;

import dgamevfs._;

import util.yaml;

import ice.campaign;
import ice.credits;
import ice.exceptions;
import ice.game;
import ice.guiswapper;
import ice.playerprofile;
import gui.guielement;
import gui2.buttonwidget;
import gui2.exceptions;
import gui2.guisystem;
import gui2.rootwidget;
import gui2.slotwidget;
import video.videodriver;
import video.sdlglvideodriver;
import video.videodrivercontainer;
import platform.platform;
import platform.sdlplatform;
import monitor.monitormanager;
import memory.memory;
import memory.memorymonitorable;
import formats.image;
import time.eventcounter;
import math.vector2;
import math.rect;
import util.frameprofiler;
import util.signal;
import util.weaksingleton;
import color;
import image;


/// Level selection GUI.
class LevelGUI: SwappableGUI
{
    /// Initialize level selection menu.
    /// 
    /// Params: guiSystem = GUI system to build the menu widgets with.
    ///         levels    = YAML to load level filenames from.
    ///         initGame  = Function that takes level filename and starts a game.
    /// 
    /// Throws: GUIInitException on failure.
    this(GUISystem guiSystem, ref YAMLNode levels, void delegate(const string) initGame)
    {
        auto menuHeight = to!string((levels.length * 8 + 24) + 8);
        // Styles.
        auto buttonStyleDefault =  "{borderColor: rgbaC0C0FF60, fontColor: rgbaA0A0FFC0}";
        auto buttonStyleFocused =  "{borderColor: rgbaC0C0FFA0, fontColor: rgbaC0C0FFC0}";
        auto buttonStyleActive  =  "{borderColor: rgbaC0C0FFFF, fontColor: rgbaE0E0FFFF}";

        auto builder = WidgetBuilder(guiSystem);

        // Root widget.
        builder.buildWidget!"root"((ref WidgetBuilder b)
        {
            b.styleManager("line");
            b.style("", "{drawBorder: false}");
            b.layoutManager("boxManual");
            b.layout("{x: 'pLeft', y: 'pTop', w: 'pWidth', h: 'pHeight'}");

            // Sidebar.
            b.buildWidget!"container"((ref WidgetBuilder b)
            {
                b.style("", "{borderColor: rgbaC0C0FFB0}");
                b.layout("{x: 'pRight - 176', y: 16, w: 160, h: 'pBottom - 32'}");

                // Menu container.
                b.buildWidget!"container"((ref WidgetBuilder b)
                {
                    b.style("", "{drawBorder: false}");
                    b.layout("{x: pLeft, y: 'pTop + 136', w: 'pWidth', h: "
                             ~ menuHeight ~ "}");

                    uint l = 0;
                    // Level buttons.
                    foreach(string level; levels)
                    {
                        auto offset = to!string(8 + (24 + 8) * l);

                        b.buildWidget!"button"((ref WidgetBuilder b)
                        {
                            b.name = "l" ~ to!string(l);
                            b.style("", buttonStyleDefault);
                            b.style("focused", buttonStyleFocused);
                            b.style("active", buttonStyleActive);
                            b.layout("{x: 'pLeft + 8', y: 'pTop + " ~ offset ~ 
                                     "', w: 'pWidth - 16', h: 24}");
                            b.widgetParams("{text: " ~ level ~ "}");
                        });
                        ++l;
                    }

                    // Back button.
                    b.buildWidget!"button"((ref WidgetBuilder b)
                    {
                        auto offset = to!string(8 + (24 + 8) * l);
                        b.name = "back";
                        b.style("", buttonStyleDefault);
                        b.style("focused", buttonStyleFocused);
                        b.style("active", buttonStyleActive);
                        b.layout("{x: 'pLeft + 8', y: 'pTop + " ~ offset ~ 
                                 "', w: 'pWidth - 16', h: 24}");
                        b.widgetParams("{text: Back}");
                    });
                });
            });
        });

        // Button actions.
        auto levelMenu = cast(RootWidget)builder.builtWidgets.back;
        auto l = 0;
        foreach(string level; levels)
        {
            levelMenu.get!ButtonWidget("l" ~ to!string(l))
                          .pressed.connect({initGame(level);});
            ++l;
        }

        super(levelMenu);
        levelMenu.back!ButtonWidget.pressed.connect({swapGUI_("ice");});
    }
}

/**
 * Class holding all GUI used by ICE (main menu, etc.).
 *
 * Signal:
 *     public mixin Signal!() quit
 *
 *     Emitted when the player clicks the button to quit. 
 *
 * Signal:
 *     public mixin Signal!() resetVideo
 *
 *     Emitted when the player clicks the button to reset video mode. 
 */
class IceGUI: SwappableGUI
{
    ///TODO replace old GUI with the new YAML loadable GUI.
    private:
        /// Root widget of the main ICE GUI (the main menu).
        RootWidget iceGUI_;
        ///Parent of all Pong GUI elements.
        GUIElement parent_;
        ///Monitor view widget.
        MonitorView monitor_;

    public:
        ///Emitted when the player clicks the button to quit.
        mixin Signal!() quit;
        ///Emitted when the player clicks the button to reset video mode.
        mixin Signal!() resetVideo;

        /**
         * Construct IceGUI with specified parameters.
         *
         * Params:  guiSystem  = Reference to the GUI system.
         *          gameDir    = Game data directory.
         *          parent     = GUI element to use as parent for all pong GUI elements.
         *          monitor    = Monitor subsystem, used to initialize monitor GUI view.
         *
         * Throws:  GUIInitException on failure.
         *          YAMLException on a YAML error.
         *          VFSException on a filesystem error.
         */
        this(GUISystem guiSystem, VFSDir gameDir, GUIElement parent, MonitorManager monitor)
        {
            parent_     = parent;

            with(new MonitorViewFactory(monitor))
            {
                x      = "16";
                y      = "16";
                width  = "192 + w_right / 4";
                height = "168 + w_bottom / 6";
                this.monitor_ = produce();
            }
            parent_.addChild(monitor_);
            monitor_.hide();

            iceGUI_ = guiSystem.loadWidgetTree(
                          loadYAML(gameDir.dir("gui").file("gameGUI.yaml")));

            iceGUI_.playerSetup!ButtonWidget.pressed.connect({swapGUI_("profiles");});
            iceGUI_.campaigns!ButtonWidget.pressed.connect({swapGUI_("campaigns");});
            iceGUI_.levels!ButtonWidget.pressed.connect({swapGUI_("levels");});
            iceGUI_.credits!ButtonWidget.pressed.connect({swapGUI_("credits");});
            iceGUI_.quit!ButtonWidget.pressed.connect(&quit.emit);
            iceGUI_.resetVideo!ButtonWidget.pressed.connect(&resetVideo.emit);

            super(iceGUI_);
        }

        ///Destroy the IceGUI.
        ~this()
        {
            monitor_.die();

            quit.disconnectAll();
            resetVideo.disconnectAll();
        }

        ///Get the monitor widget.
        @property const(MonitorView) monitor() const {return monitor_;}

        ///Toggle monitor display.
        void monitorToggle()
        {
            if(monitor_.visible){monitor_.hide();}
            else{monitor_.show();}
        }
}

/// "Main" ICE class.
class Ice
{
    mixin WeakSingleton;
    private:
        ///FPS counter.
        EventCounter fpsCounter_;
        ///Continue running?
        bool continue_ = true;

        ///Container managing video driver and its dependencies.
        VideoDriverContainer videoDriverContainer_;
        ///Container managing game and its dependencies.
        GameContainer gameContainer_;

        ///Platform used for user input.
        Platform platform_;
        ///Video driver.
        VideoDriver videoDriver_;
        ///Game.
        Game game_;
        ///Root directory of the game's virtual file system.
        VFSDir gameDir_;
        ///Root element of the GUI.
        GUIRoot guiRoot_;
        ///New GUI system (will replace guiRoot_)
        GUISystem guiSystem_;
        ///Monitor subsystem, providing debugging and profiling info.
        MonitorManager monitor_;
        ///Swaps root widgets of various GUIs.
        GUISwapper guiSwapper_;
        ///ICE GUI.
        IceGUI gui_;
        ///Player profile manager.
        ProfileManager profileManager_;
        ///Manages campaigns.
        CampaignManager campaignManager_;

        ///Main ICE config file (YAML).
        YAMLNode config_;
       
        ///Used for memory monitoring.
        MemoryMonitorable memory_;

        ///Data storage for the frame profiler, when enabled.
        ubyte[] frameProfilerData_;
        ///Is the frame profiler enabled?
        bool frameProfilerEnabled_;

    public:
        /**
         * Initialize ICE.
         *
         * Params:  gameDir = Root directory of the game's virtual file system.
         *
         * Throws GameStartupException on an expected, correctly handled failure.
         */
        this(VFSDir gameDir)
        {
            gameDir_ = gameDir;

            writeln("Initializing ICE...");
            scope(failure){writeln("ICE initialization failed");}

            singletonCtor();
            scope(failure){singletonDtor();}

            initConfig();
            writeln("Initialized Config");
            initPlatform();
            writeln("Initialized Platform");
            scope(failure){destroyPlatform();}
            initVideo();
            writeln("Initialized Video");
            scope(failure){destroyVideo();}
            initMonitor();
            writeln("Initialized Monitor");
            scope(failure){destroyMonitor();}
            initPlayerProfiles();
            writeln("Initialized player profiles");
            scope(failure){destroyPlayerProfiles();}
            initCampaigns();
            writeln("Initialized campaigns");
            scope(failure){destroyCampaigns();}
            initGUI();
            writeln("Initialized GUI");
            scope(failure){destroyGUI();}

            //Update FPS every second.
            fpsCounter_ = EventCounter(1.0);
            fpsCounter_.update.connect(&fpsUpdate);

            initFrameProfiler();
            scope(failure){destroyFrameProfiler();}
        }

        ///Destroy Ice and all subsystems.
        ~this()
        {
            writeln("Destroying ICE");

            clear(fpsCounter_);

            destroyFrameProfiler();
            if(game_ !is null){destroyGame();}
            destroyPlayerProfiles();
            destroyCampaigns();
            destroyGUI();
            destroyMonitor();
            destroyVideo();
            destroyPlatform();

            singletonDtor();
        }

        ///Main ICE event loop.
        void run()
        {
            ulong iterations = 0;
            scope(failure)
            {
                writeln("Failure in ICE main loop, iteration ", iterations);
            }

            platform_.key.connect(&keyHandlerGlobal);
            platform_.key.connect(&keyHandler);

            while(platform_.run() && continue_)
            {
                if(game_ !is null) {frameProfilerResume();}

                {
                    auto frame = Frame("ICE frame");
                    //Count this frame
                    fpsCounter_.event();

                    {
                        auto zone = Zone("VideoDriver startFrame");
                        videoDriver_.startFrame();
                    }
                    if(game_ !is null)
                    {
                        auto zone = Zone("Game run");
                        //update game state
                        if(!game_.run()){destroyGame();}
                    }

                    {
                        auto zone = Zone("GUI update");
                        //Must be updated after game.
                        //That is because destroyGame might be called, resulting
                        //in destruction of Game-specific GUI monitors, 
                        //which need to be cleaned up (in update()) - otherwise 
                        //draw() would try to draw destroyed GUI monitors.
                        guiRoot_.update();
                    }

                    {
                        auto zone = Zone("GUI draw");
                        guiRoot_.draw(videoDriver_);
                        guiSystem_.render(videoDriver_);
                    }
                    {
                        auto zone = Zone("VideoDriver endFrame");
                        videoDriver_.endFrame();
                    }

                    {
                        auto zone = Zone("Memory update");
                        memory_.update();
                    }

                    ++iterations;
                }
                if(game_ !is null) {frameProfilerPause();}
            }
            writeln("FPS statistics:\n", fpsCounter_.statistics, "\n");
        }

    private:
        ///Load ICE configuration from YAML.
        void initConfig()
        {
            try
            {
                auto configFile = gameDir_.file("config.yaml");
                config_ = loadYAML(configFile);
            }
            catch(YAMLException e)
            {
                throw new GameStartupException("Failed to load main ICE config file: " ~ e.msg);
            }
            catch(VFSException e)
            {
                throw new GameStartupException("Failed to load main ICE config file: " ~ e.msg);
            }
        }

        ///Initialize the Platform subsystem.
        void initPlatform()
        {
            try
            {
                platform_ = new SDLPlatform();
            }
            catch(PlatformException e)
            {
                platform_ = null;
                throw new GameStartupException("Failed to initialize platform: " ~ e.msg);
            }
        }

        ///Initialize the video subsystem. Throws GameStartupException on failure.
        void initVideo()
        {
            try{videoDriverContainer_ = new VideoDriverContainer(gameDir_);}
            catch(VideoDriverException e)
            {
                throw new GameStartupException("Failed to initialize video "
                                               "driver dependencies: " ~ e.msg);
            }
            initVideoDriverFromConfig();
            if(videoDriver_ is null)
            {
                videoDriverContainer_.destroy();
                clear(videoDriverContainer_);
                throw new GameStartupException("Failed to initialize video driver.");
            }
            rescaleViewport();
        }

        ///Initialize the monitor subsystem.
        void initMonitor()
        {
            monitor_ = new MonitorManager();
            memory_  = new MemoryMonitorable();
            monitor_.addMonitorable(memory_, "Memory");
            monitor_.addMonitorable(videoDriver_, "Video");
        }

        /// Init GUI subsystem.
        ///
        /// Throws: GameStartupException on failure.
        void initGUI()
        {
            guiSystem_ = new GUISystem(platform_);
            guiSystem_.setGUISize(videoDriver_.screenWidth,
                                  videoDriver_.screenHeight);

            // TODO this will be gradually removed and replaced by the new, 
            //      YAML-loadable GUI.
            guiRoot_ = new GUIRoot(platform_);

            try
            {
                auto levelsFile = gameDir_.file("levels.yaml");
                YAMLNode levels = loadYAML(levelsFile);

                guiSwapper_       = new GUISwapper(guiSystem_.rootSlot);

                // Function to start a level outside a campaign.
                //
                // Used by the level selection menu.
                void startLevelSeparate(const string levelName)
                {
                    try
                    {
                        auto source = loadYAML(gameDir_.file(levelName));
                        initGame(source, null);
                    }
                    catch(YAMLException e)
                    {
                        writeln("Failed to separately load level ", levelName, ": ", e.msg);
                    }
                    catch(VFSException e)
                    {
                        writeln("Failed to separately load level ", levelName, ": ", e.msg);
                    }
                }
                auto levelGUI     = new LevelGUI(guiSystem_, levels, &startLevelSeparate);
                auto credits      = new Credits(guiSystem_, gameDir);
                auto campaignsGUI = new CampaignsGUI(guiSystem_, campaignManager_, gameDir_);
                auto campaignGUI  =
                    new CampaignGUI(guiSystem_, gameDir_, campaignManager_.currentCampaign,
                                    profileManager_.currentProfile, &initGame);
                profileManager_.changedProfile.connect(&campaignGUI.playerProfile);
                campaignManager_.changedCampaign.connect(&campaignGUI.campaign);
                auto profileGUI   = 
                    new ProfileGUI(profileManager_, guiSystem_, guiSystem_.rootSlot, gameDir_);
                gui_ = new IceGUI(guiSystem_, gameDir_, guiRoot_.root, monitor_);
                guiSwapper_.addGUI(gui_,         "ice");
                guiSwapper_.addGUI(credits,      "credits");
                guiSwapper_.addGUI(levelGUI,     "levels");
                guiSwapper_.addGUI(campaignsGUI, "campaigns");
                guiSwapper_.addGUI(campaignGUI,  "campaign");
                guiSwapper_.addGUI(profileGUI,   "profiles");
                guiSwapper_.setGUI("ice");
            }
            catch(GUIInitException e)
            {
                throw new GameStartupException("Failed to initialize ICE GUI: ", e.msg);
            }
            catch(YAMLException e)
            {
                throw new GameStartupException("Failed to initialize ICE GUI: ", e.msg);
            }
            catch(VFSException e)
            {
                throw new GameStartupException("Failed to initialize ICE GUI: ", e.msg);
            }

            gui_.quit.connect(&exit);
            gui_.resetVideo.connect(&resetVideoMode);

            gameContainer_ = new GameContainer();
        }

        /// Destroy the GUI subsystem.
        void destroyGUI()
        {
            clear(gui_);
            clear(guiSystem_);
            clear(guiRoot_);
        }


        ///Allocate memory for the frame profiler and initialize it (if enabled).
        void initFrameProfiler()
        {
            auto profilerConfig   = config_["frameProfiler"];
            frameProfilerEnabled_ = profilerConfig["enabled"].as!bool;
            if(frameProfilerEnabled_)
            {
                frameProfilerData_ = 
                    allocArray!ubyte(profilerConfig["memoryMiB"].as!uint * 1024 * 1024);
                frameProfilerInit(frameProfilerData_, profilerConfig["frameSkip"].as!uint);
                frameProfilerPause();
            }
        }

        ///Dump frame profiler and deallocate its memory.
        void destroyFrameProfiler()
        {
            // If we failed during initialization, frameProfilerData_ might
            // not yet be initialized.
            if(frameProfilerEnabled_ && null !is frameProfilerData_)
            {
                auto logDir = gameDir_.dir("logs");
                if(!logDir.exists) {logDir.create();}
                VFSFile profilerDump = logDir.file("frameProfilerDump.yaml");
                auto stream = VFSStream(profilerDump.output);
                writeln("Writing frame profile...");
                frameProfilerDump((string line)
                {
                    // Write dots to show we're still working.
                    static counter = 0;
                    if(counter % (64 * 1024) == 0){writeln(".");}
                    ++counter;
                    stream.writeLine(line);
                });
                // Newline after the dots.
                writeln("");
                free(frameProfilerData_);
                frameProfilerEnd();
            }
        }

        /// Initialize any code related to player profiles.
        void initPlayerProfiles()
        {
            try
            {
                profileManager_ = new ProfileManager(gameDir_);
            }
            catch(ProfileException e)
            {
                throw new GameStartupException("Failed to initialize profile manager: "
                                               ~ e.msg);
            }
        }

        /// Deinitialize any code related to player profiles.
        void destroyPlayerProfiles()
        {
            try
            {
                profileManager_.save();
                clear(profileManager_);
                profileManager_ = null;
            }
            catch(ProfileException e)
            {
                writeln("Failed to save player profiles: " ~ e.msg);
            }
        }

        /// Initialize any code related to campaigns.
        void initCampaigns()
        {
            try
            {
                campaignManager_ = new CampaignManager(gameDir_);
            }
            catch(CampaignInitException e)
            {
                throw new GameStartupException("Failed to initialize campaign manager: "
                                               ~ e.msg);
            }
        }

        /// Deinitialize any code related to campaigns.
        void destroyCampaigns()
        {
            try
            {
                campaignManager_.save();
                clear(campaignManager_);
                campaignManager_ = null;
            }
            catch(CampaignSaveException e)
            {
                writeln("Failed to save campaign manager config: " ~ e.msg);
            }
        }

        ///Destroy Monitor subsystem.
        void destroyMonitor()
        {
            monitor_.removeMonitorable("Memory");
            clear(memory_);
            //video driver might be already destroyed in exceptional circumstances
            if(videoDriver_ !is null){monitor_.removeMonitorable("Video");}
            clear(monitor_);
        }

        ///Destroy Video subsystem.
        void destroyVideo()
        {
            //Video driver might be already destroyed in exceptional circumstances
            //such as a failed video driver reset.
            if(videoDriver_ is null){return;}
            videoDriverContainer_.destroy();
            clear(videoDriverContainer_);
            videoDriver_ = null;
        }

        ///Destroy Platform subsystem.
        void destroyPlatform()
        {
            clear(platform_);
            platform_ = null;
        }

        ///Start game.
        void initGame(ref YAMLNode levelSource,
                      void delegate(GameOverData) gameOverCallback = null)
        {
            platform_.key.disconnect(&keyHandler);

            guiSwapper_.setGUI(null);
            try
            {
                game_ = gameContainer_.produce(platform_,
                                               monitor_,
                                               guiRoot_.root,
                                               videoDriver_,
                                               gameDir_,
                                               profileManager_.currentProfile,
                                               levelSource);
                if(null !is gameOverCallback)
                {
                    game_.atGameOver.connect(gameOverCallback);
                }
            }
            catch(GameStartException e)
            {
                writeln("Game failed to start: " ~ e.msg);

                guiSwapper_.setGUI("ice");
                platform_.key.connect(&keyHandler);
            }
        }

        ///End game.
        void destroyGame()
        {
            gameContainer_.destroy();
            game_ = null;
            platform_.key.connect(&keyHandler);
            guiSwapper_.setGUI("ice");
        }

        ///Exit ICE.
        void exit(){continue_ = false;}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void keyHandler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed) switch(key)
            {
                case Key.Escape: exit(); break;
                default: break;
            }
        }

        /**
         * Process keyboard input (global).
         *
         * This key handler is always connected, regardless of whether we're in
         * game or main menu.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void keyHandlerGlobal(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed) switch(key)
            {
                case Key.K_1: videoDriver_.drawMode = DrawMode.RAMBuffers;  break;
                case Key.K_2: videoDriver_.drawMode = DrawMode.VRAMBuffers; break;
                case Key.F10: gui_.monitorToggle();   break;
                case Key.Scrollock: saveScreenshot(); break;
                default: break;
            }
        }

        ///Update FPS display.
        void fpsUpdate(real fps)
        {
            platform_.windowCaption = "FPS: " ~ to!string(fps);
        }

        ///Reset the video driver.
        void resetVideoMode()
        {
            monitor_.removeMonitorable("Video");

            videoDriverContainer_.destroy();
            scope(failure){videoDriver_ = null;}

            initVideoDriverFromConfig();

            if(videoDriver_ is null)
            {
                writeln("Video driver reset failed.");
                exit();
                return;
            }

            guiSystem_.setGUISize(videoDriver_.screenWidth,
                                  videoDriver_.screenHeight);

            rescaleViewport();

            monitor_.addMonitorable(videoDriver_, "Video");
        }

        /**
         * Initialize video driver fromm YAML config.
         *
         * This only loads configuration and uses videoDriverContainer_ to
         * produce the driver. videoDriverContainer_ must not store any 
         * VideoDriver already.
         */
        void initVideoDriverFromConfig()
        {
            try
            {
                auto video       = config_["video"];
                const width      = video["width"].as!uint;
                const height     = video["height"].as!uint;
                const depth      = video["depth"].as!uint;
                const format     = depth == 16 ? ColorFormat.RGB_565 : ColorFormat.RGBA_8;
                const modeStr    = video["drawMode"].as!string;
                const drawMode   = modeStr == "RAMBuffers" ? DrawMode.RAMBuffers 
                                                           : DrawMode.VRAMBuffers;
                const fullscreen = video["fullscreen"].as!bool;

                if(![16, 32].canFind(depth))
                {
                    writeln("Unsupported video mode depth: ", depth,
                            " - falling back to 32bit");
                }
                if(!["RAMBuffers", "VRAMBuffers"].canFind(modeStr))
                {
                    writeln("Unknown draw mode: ", modeStr,
                            " - falling back to VRAMBuffers");
                }
                videoDriver_ = videoDriverContainer_.produce!SDLGLVideoDriver
                               (width, height, format, fullscreen);
                videoDriver_.drawMode = drawMode;
            }
            catch(YAMLException e)
            {
                writeln("Error initializing video mode from YAML configuration. "
                        "Falling back to 800x600 32bit windowed");
                videoDriver_ = videoDriverContainer_.produce!SDLGLVideoDriver
                               (800, 600, ColorFormat.RGBA_8, false);
            }

            if(game_ !is null)
            {
                game_.videoDriver = videoDriver_;
            }
        }

        ///Rescale viewport according to current resolution and game area.
        void rescaleViewport()
        {
            //Zoom according to the new video mode.
            const area  = game_.gameArea;
            const wMult = videoDriver_.screenWidth  / area.width;
            const hMult = videoDriver_.screenHeight / area.height;
            const zoom  = min(wMult, hMult);

            //Center game area on screen.
            const offset = Vector2d(area.min.x - (wMult / zoom - 1.0) * 0.5 * area.width,
                                    area.min.y - (hMult / zoom - 1.0) * 0.5 * area.height);

            videoDriver_.zoom(zoom);
            videoDriver_.viewOffset(offset);
            if(guiRoot_ !is null){guiRoot_.realign(videoDriver_);}
        }

        ///Save screenshot (to data/main/screenshots).
        void saveScreenshot()
        {
            Image screenshot;

            videoDriver_.screenshot(screenshot);

            try
            {
                auto screenshotDir = gameDir_.dir("user_data::main::screenshots");
                screenshotDir.create();

                foreach(s; 0 .. 10000)
                {
                    string fileName = format("screenshot_%05d.png", s);
                    auto file = screenshotDir.file(fileName);
                    if(!file.exists)
                    {
                        writeln("Writing screenshot " ~ fileName);
                        writeImage(screenshot, file);
                        return;
                    }
                }
            }
            catch(VFSException e){writeln("Screenshot saving error: " ~ e.msg);}
            catch(ImageFileException e){writeln("Screenshot saving error: " ~ e.msg);}
        }
}
