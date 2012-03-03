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
import memory.memorymonitorable;
import file.fileio;
import formats.image;
import time.eventcounter;
import math.vector2;
import math.rect;
import util.signal;
import util.weaksingleton;
import color;
import image;


/** 
 * Class holding all GUI used by ICE (main menu, etc.).
 *
 * Signal:
 *     public mixin Signal!() gameStart
 *
 *     Emitted when the player clicks the button to start the game.
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
        ///Main menu.
        GUIMenu menu_;
        ///Credits screen (null unless shown).
        Credits credits_;

    public:
        ///Emitted when the player clicks the button to start the game.
        mixin Signal!() gameStart;
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
         * Params:  parent  = GUI element to use as parent for all pong GUI elements.
         *          monitor = Monitor subsystem, used to initialize monitor GUI view.
         */
        this(GUIElement parent, MonitorManager monitor)
        {
            parent_ = parent;

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
                x            = "p_left";
                y            = "p_top + 136";
                itemWidth   = "144";
                itemHeight  = "24";
                itemSpacing = "8";
                addItem("Player vs AI", &gameStart.emit);
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

            menuContainer_.die();

            gameStart.disconnectAll();
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

    private:
        ///Show credits screen (and hide main menu).
        void creditsShow()
        {
            menuHide();
            credits_ = new Credits(parent_);
            credits_.closed.connect(&creditsHide);
            creditsStart.emit();
        }

        ///Hide credits screen (and show main menu).
        void creditsHide()
        {
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
       
        ///Used for memory monitoring.
        MemoryMonitorable memory_;

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

            writeln("Initializing Ice");
            scope(failure){writeln("Ice initialization failed");}

            singletonCtor();

            scope(failure)
            {
                clear(monitor_);
                clear(memory_);
                singletonDtor();
            }
            monitor_ = new MonitorManager();
            memory_  = new MemoryMonitorable();

            scope(failure){monitor_.removeMonitorable("Memory");}
            monitor_.addMonitorable(memory_, "Memory");

            scope(failure)
            {
                clear(platform_);
                platform_ = null;
            }
            platform_ = new SDLPlatform;

            scope(failure){clear(videoDriverContainer_);}
            initVideo();

            scope(failure){monitor_.removeMonitorable("Video");}
            monitor_.addMonitorable(videoDriver_, "Video");

            //initialize GUI
            scope(failure){clear(guiRoot_);}
            guiRoot_ = new GUIRoot(platform_);

            scope(failure){clear(gui_);}
            gui_ = new IceGUI(guiRoot_.root, monitor_);
            gui_.creditsStart.connect(&creditsStart);
            gui_.creditsEnd.connect(&creditsEnd);
            gui_.gameStart.connect(&gameStart);
            gui_.quit.connect(&exit);
            gui_.resetVideo.connect(&resetVideo);

            gameContainer_ = new GameContainer();

            //Update FPS every second.
            fpsCounter_ = EventCounter(1.0);
            fpsCounter_.update.connect(&fpsUpdate);
        }

        ///Destroy Ice and all subsystems.
        ~this()
        {
            writeln("Destroying ICE");
         
            //game might still be running if we're quitting
            //because the platform stopped to run
            if(game_ !is null)
            {
                game_.endGame();
                gameContainer_.destroy();
                game_ = null;
            }

            clear(fpsCounter_);

            monitor_.removeMonitorable("Memory");
            //video driver might be already destroyed in exceptional circumstances
            if(videoDriver_ !is null){monitor_.removeMonitorable("Video");}

            clear(gui_);
            clear(guiRoot_);
            clear(monitor_);

            //video driver might be already destroyed in exceptional circumstances
            if(videoDriver_ !is null)
            {
                videoDriverContainer_.destroy();
                clear(videoDriverContainer_);
                videoDriver_ = null;
            }

            clear(platform_);
            platform_ = null;

            clear(memory_);

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
                //Count this frame
                fpsCounter_.event();

                guiRoot_.update();

                videoDriver_.startFrame();
                if(game_ !is null)
                {
                    //update game state
                    if(!game_.run()){gameEnd();}
                    else{game_.draw(videoDriver_);}
                }
                guiRoot_.draw(videoDriver_);
                videoDriver_.endFrame();
            
                memory_.update();
            
                ++iterations;
            }
            writeln("FPS statistics:\n", fpsCounter_.statistics, "\n");
        }

    private:
        ///Initialize the video subsystem. Throws GameStartupException on failure.
        void initVideo()
        {
            videoDriverContainer_ = new VideoDriverContainer;
            videoDriver_ = videoDriverContainer_.produce!(SDLGLVideoDriver)
                            (800, 600, ColorFormat.RGBA_8, false, gameDir_);
            if(videoDriver_ is null)
            {
                throw new GameStartupException("Failed to initialize video driver.");
            }
            rescaleViewport();
        }

        ///Start game.
        void gameStart()
        {
            gui_.menuHide();
            platform_.key.disconnect(&keyHandler);
            game_ = gameContainer_.produce(platform_, monitor_, guiRoot_.root);
            game_.startGame();
        }

        ///End game.
        void gameEnd()
        {
            gameContainer_.destroy();
            game_ = null;
            platform_.key.connect(&keyHandler);
            gui_.menuShow();
        }

        ///Show credits screen.
        void creditsStart(){platform_.key.disconnect(&keyHandler);}

        ///Hide (destroy) credits screen.
        void creditsEnd(){platform_.key.connect(&keyHandler);}

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
                case Key.Return: gameStart(); break;
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
                case Key.K_1: videoDriver_.drawMode(DrawMode.RAMBuffers);  break;
                case Key.K_2: videoDriver_.drawMode(DrawMode.VRAMBuffers); break;
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

        ///Reset video mode.
        void resetVideo(){resetVideoDriver(800, 600, ColorFormat.RGBA_8);}

        /**
         * Reset video driver with specified video mode.
         *
         * Params:  width  = Window/screen width to use.
         *          height = Window/screen height to use.
         *          format = Color format of video mode.
         */
        void resetVideoDriver(const uint width, const uint height, const ColorFormat format)
        {
            monitor_.removeMonitorable("Video");

            videoDriverContainer_.destroy();
            scope(failure){videoDriver_ = null;}

            videoDriver_ = videoDriverContainer_.produce!SDLGLVideoDriver
                           (width, height, format, false, gameDir_);

            if(videoDriver_ is null)
            {
                writeln("Video driver reset failed.");
                exit();
                return;
            }

            rescaleViewport();

            monitor_.addMonitorable(videoDriver_, "Video");
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
