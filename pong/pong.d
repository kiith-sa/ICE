//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Main pong program class.
module pong.pong;


import std.algorithm;
import std.conv;
import std.stdio;
import std.string;

import dgamevfs._;

import ice.exceptions;
import pong.game;
import pong.credits;
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
 * Class holding all GUI used by Pong (main menu, etc.).
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
class PongGUI
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
         * Construct PongGUI with specified parameters.
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

        ///Destroy the PongGUI.
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

class Pong
{
    mixin WeakSingleton;
    private:
        alias std.conv.to to;

        ///FPS counter.
        EventCounter fpsCounter_;
        ///Continue running?
        bool continue_ = true;

        ///Platform used for user input.
        Platform platform_;

        ///Root directory of the game's virtual file system.
        VFSDir gameDir_;

        ///Container managing video driver and its dependencies.
        VideoDriverContainer videoDriverContainer_;
        ///Video driver.
        VideoDriver videoDriver_;

        ///Root of the GUI.
        GUIRoot guiRoot_;
        
        ///Pong GUI.
        PongGUI gui_;
       
        ///Used for memory monitoring.
        MemoryMonitorable memory_;

        ///Container managing game and its dependencies.
        GameContainer gameContainer_;
        ///Game.
        Game game_;

        ///Monitor subsystem, providing debugging and profiling info.
        MonitorManager monitor_;

    public:
        /**
         * Initialize Pong.
         *
         * Params:  gameDir = Root directory of the game's virtual file system.
         *
         * Throws GameStartupException on an expected, correctly handled failure.
         */
        this(VFSDir gameDir)
        {
            gameDir_ = gameDir;

            writeln("Initializing Pong");
            scope(failure){writeln("Pong initialization failed");}

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
            gui_ = new PongGUI(guiRoot_.root, monitor_);
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

        ///Destroy Pong and all subsystems.
        ~this()
        {
            writeln("Destroying Pong");
         
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

        ///Update Pong.
        void run()
        {                           
            ulong iterations = 0;

            scope(failure)
            {
                writeln("Failure in Pong main loop, iteration ", iterations);
            }

            platform_.key.connect(&keyHandlerGlobal);
            platform_.key.connect(&keyHandler);

            while(platform_.run() && continue_)
            {
                //Count this frame
                fpsCounter_.event();

                const bool gameRun = game_ !is null && game_.run();
                if(game_ !is null && !gameRun){gameEnd();}

                //update game state
                guiRoot_.update();

                videoDriver_.startFrame();

                if(gameRun){game_.draw(videoDriver_);}

                guiRoot_.draw(videoDriver_);
                videoDriver_.endFrame();
            
                memory_.update();
            
                iterations++;
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
        }

        ///Start game.
        void gameStart()
        {
            gui_.menuHide();
            platform_.key.disconnect(&keyHandler);
            game_ = gameContainer_.produce(platform_, monitor_, guiRoot_.root);
            game_.intro();
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
                case Key.K_1: videoDriver_.drawMode(DrawMode.Immediate);   break;
                case Key.K_2: videoDriver_.drawMode(DrawMode.RAMBuffers);  break;
                case Key.K_3: videoDriver_.drawMode(DrawMode.VRAMBuffers); break;
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
        void resetVideoDriver(in uint width, in uint height, in ColorFormat format)
        {
            //game area
            const Rectf area = game_.gameArea;

            monitor_.removeMonitorable("Video");

            videoDriverContainer_.destroy();
            scope(failure){(videoDriver_ = null);}

            videoDriver_ = videoDriverContainer_.produce!(SDLGLVideoDriver)
                           (width, height, format, false, gameDir_);
            if(videoDriver_ is null)
            {
                writeln("Video driver reset failed.");
                exit();
                return;
            }

            //Zoom according to the new video mode.
            const real wMult = width / area.width;
            const real hMult = height / area.height;
            const real zoom = min(wMult, hMult);

            //Center game area on screen.
            Vector2d offset;
            offset.x = area.min.x + (wMult / zoom - 1.0) * 0.5 * area.width * -1.0; 
            offset.y = area.min.y + (hMult / zoom - 1.0) * 0.5 * area.height * -1.0;

            videoDriver_.zoom(zoom);
            videoDriver_.viewOffset(offset);
            guiRoot_.realign(videoDriver_);
            monitor_.addMonitorable(videoDriver_, "Video");
        }

        ///Save screenshot (to data/main/screenshots).
        void saveScreenshot()
        {
            Image screenshot;

            videoDriver_.screenshot(screenshot);

            try
            {
                ensureDirectoryUser("main::screenshots");

                //save screenshot with increasing suffix number.
                for(uint s = 0; s < 100000; s++)
                {
                    string fileName = format("main::screenshots/screenshot_%05d.png", s);
                    if(!fileExistsUser(fileName))
                    {
                        writeImage(screenshot, fileName);
                        return;
                    }
                }
                writeln("Screenshot saving error: too many screenshots");
            }
            catch(FileIOException e){writeln("Screenshot saving error: " ~ e.msg);}
            catch(ImageFileException e){writeln("Screenshot saving error: " ~ e.msg);}
        }
}
