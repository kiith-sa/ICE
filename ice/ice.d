
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Main pong program class.
module ice.ice;


import std.algorithm;
import std.conv;
import std.stdio;
import std.string;

import dgamevfs._;

import util.yaml;

import ice.exceptions;
import ice.game;
import ice.credits;
import gui.guielement;
import gui.guimenu;
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


/** 
 * Class holding all GUI used by ICE (main menu, etc.).
 *
 * Signal:
 *     public mixin Signal!() levelMenuOpen
 *
 *     Emitted when the player clicks the button to open level menu.
 *
 * Signal:
 *     public mixin Signal!() creditsStart
 *
 *     Emitted when the credits screen is opened. 
 *
 * Signal:
 *     public mixin Signal!() creditsEnd
 *
 *     Emitted when the credits screen is closed. 
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
class IceGUI
{
    private:
        ///Parent of all Pong GUI elements.
        GUIElement parent_;
        ///Monitor view widget.
        MonitorView monitor_;
        ///Container of the main menu.
        GUIElement menuContainer_;
        ///Container of the level menu.
        GUIElement levelMenuContainer_;
        ///Main menu.
        GUIMenu menu_;
        ///Credits screen (null unless shown).
        Credits credits_;
        ///Platform for keyboard I/O.
        Platform platform_;

    public:
        ///Emitted when the player clicks the button to open the level menu.
        mixin Signal!() levelMenuOpen;
        ///Emitted when the credits screen is opened.
        mixin Signal!() creditsStart;
        ///Emitted when the credits screen is closed.
        mixin Signal!() creditsEnd;
        ///Emitted when the player clicks the button to quit.
        mixin Signal!() quit;
        ///Emitted when the player clicks the button to reset video mode.
        mixin Signal!() resetVideo;

        /**
         * Construct IceGUI with specified parameters.
         *
         * Params:  parent   = GUI element to use as parent for all pong GUI elements.
         *          monitor  = Monitor subsystem, used to initialize monitor GUI view.
         *          platform = Platform for keyboard I/O.
         */
        this(GUIElement parent, MonitorManager monitor, Platform platform)
        {
            parent_   = parent;
            platform_ = platform;

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

            with(new GUIElementFactory)
            {
                x      = "p_right - 176";
                y      = "16";
                width  = "160";
                height = "p_bottom - 32";
                menuContainer_ = produce();
            }
            parent_.addChild(menuContainer_);

            with(new GUIMenuVerticalFactory)
            {
                x           = "p_left";
                y           = "p_top + 136";
                itemWidth   = "144";
                itemHeight  = "24";
                itemSpacing = "8";
                addItem("Levels", &levelMenuOpen.emit);
                addItem("Credits", &creditsShow);
                addItem("Quit", &quit.emit);
                addItem("(DEBUG) Reset video", &resetVideo.emit);
                menu_ = produce();
            }
            menuContainer_.addChild(menu_);
        }

        ///Destroy the IceGUI.
        ~this()
        {
            monitor_.die();

            if(credits_ !is null){clear(credits_);}

            if(levelMenuContainer_ !is null)
            {
                levelMenuContainer_.die();
                levelMenuContainer_ = null;
            }

            menuContainer_.die();

            levelMenuOpen.disconnectAll();
            creditsStart.disconnectAll();
            creditsEnd.disconnectAll();
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

        ///Show main menu.
        void menuShow(){menuContainer_.show();};

        ///Hide main menu.
        void menuHide(){menuContainer_.hide();};

        ///Show level selection menu.
        ///
        ///Params:  levels   = YAML to load level filenames from.
        ///         initGame = Function that takes level filename and starts a game.
        void levelMenuShow(ref YAMLNode levels, void delegate(const string) initGame)
        {
            if(levelMenuContainer_ !is null)
            {
                levelMenuContainer_.die();
                levelMenuContainer_ = null;
            }

            with(new GUIElementFactory)
            {
                x      = "p_right - 176";
                y      = "16";
                width  = "160";
                height = "p_bottom - 32";
                levelMenuContainer_ = produce();
            }
            parent_.addChild(levelMenuContainer_);

            with(new GUIMenuVerticalFactory)
            {
                x           = "p_left";
                y           = "p_top + 136";
                itemWidth   = "144";
                itemHeight  = "24";
                itemSpacing = "8";
                foreach(string level; levels)
                {
                    addItem(level, {initGame(level);});
                }
                levelMenuContainer_.addChild(produce());
            }
        }

        ///Hide the level menu.
        void levelMenuHide()
        {
            levelMenuContainer_.hide();
        }

    private:
        ///Show credits screen (and hide main menu).
        void creditsShow()
        {
            menuHide();
            credits_ = new Credits(parent_);
            credits_.closed.connect(&creditsHide);
            platform_.key.connect(&credits_.keyHandler);
            creditsStart.emit();
        }

        ///Hide credits screen (and show main menu).
        void creditsHide()
        {
            platform_.key.disconnect(&credits_.keyHandler);
            clear(credits_);
            credits_ = null;
            menuShow();
            creditsEnd.emit();
        }
}

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
        ///Monitor subsystem, providing debugging and profiling info.
        MonitorManager monitor_;
        ///ICE GUI.
        IceGUI gui_;

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

        ///Init GUI subsystem.
        void initGUI()
        {
            guiRoot_ = new GUIRoot(platform_);

            gui_ = new IceGUI(guiRoot_.root, monitor_, platform_);
            gui_.creditsStart.connect(&creditsStart);
            gui_.creditsEnd.connect(&creditsEnd);
            gui_.levelMenuOpen.connect(&showLevelMenu);
            gui_.quit.connect(&exit);
            gui_.resetVideo.connect(&resetVideoMode);

            gameContainer_ = new GameContainer();
        }

        ///Destroy GUI subsystem.
        void destroyGUI()
        {
            clear(gui_);
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
                frameProfilerDump((string line){stream.writeLine(line);});
                free(frameProfilerData_);
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

        ///Show the menu to select levels in the game.
        void showLevelMenu()
        {
            gui_.menuHide();
            auto levelsFile = gameDir_.file("levels.yaml");
            YAMLNode levels = loadYAML(levelsFile);
            gui_.levelMenuShow(levels, &initGame);
        }

        ///Start game.
        void initGame(const string levelName)
        {
            platform_.key.disconnect(&keyHandler);

            gui_.levelMenuHide();
            try
            {
                game_ = gameContainer_.produce(platform_, 
                                               monitor_, 
                                               guiRoot_.root,
                                               videoDriver_,
                                               gameDir_,
                                               levelName);
            }
            catch(GameStartException e)
            {
                writeln("Game failed to start: " ~ e.msg);

                gui_.menuShow();
                platform_.key.connect(&keyHandler);
            }
        }

        ///End game.
        void destroyGame()
        {
            gameContainer_.destroy();
            game_ = null;
            platform_.key.connect(&keyHandler);
            gui_.menuShow();
        }

        ///Show credits screen.
        void creditsStart()
        {
            platform_.key.disconnect(&keyHandler);
        }

        ///Hide (destroy) credits screen.
        void creditsEnd()
        {
            platform_.key.connect(&keyHandler);
        }

        ///Exit Pong.
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
