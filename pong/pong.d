//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Main pong program class.
module pong.pong;
@safe


import std.algorithm;
import std.conv;
import std.stdio;
import std.string;

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
import math.rectangle;
import util.signal;
import util.weaksingleton;
import color;
import image;


/** 
 * Class holding all GUI used by Pong (main menu, etc.).
 *
 * Signal:
 *     public mixin Signal!() game_start
 *
 *     Emitted when the player clicks the button to start the game.
 *
 * Signal:
 *     public mixin Signal!() credits_start
 *
 *     Emitted when the credits screen is opened. 
 *
 * Signal:
 *     public mixin Signal!() credits_end
 *
 *     Emitted when the credits screen is closed. 
 *
 * Signal:
 *     public mixin Signal!() quit
 *
 *     Emitted when the player clicks the button to quit. 
 *
 * Signal:
 *     public mixin Signal!() reset_video
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
        GUIElement menu_container_;
        ///Main menu.
        GUIMenu menu_;
        ///Credits screen (null unless shown).
        Credits credits_;

    public:
        ///Emitted when the player clicks the button to start the game.
        mixin Signal!() game_start;
        ///Emitted when the credits screen is opened.
        mixin Signal!() credits_start;
        ///Emitted when the credits screen is closed.
        mixin Signal!() credits_end;
        ///Emitted when the player clicks the button to quit.
        mixin Signal!() quit;
        ///Emitted when the player clicks the button to reset video mode.
        mixin Signal!() reset_video;

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
                x = "16";
                y = "16";
                width ="192 + w_right / 4";
                height ="168 + w_bottom / 6";
                this.monitor_ = produce();
            }
            parent_.add_child(monitor_);
            monitor_.hide();

            with(new GUIElementFactory)
            {
                x = "p_right - 176";
                y = "16";
                width = "160";
                height = "p_bottom - 32";
                menu_container_ = produce();
            }
            parent_.add_child(menu_container_);

            with(new GUIMenuVerticalFactory)
            {
                x = "p_left";
                y = "p_top + 136";
                item_width = "144";
                item_height = "24";
                item_spacing = "8";
                add_item("Player vs AI", &game_start.emit);
                add_item("Credits", &credits_show);
                add_item("Quit", &quit.emit);
                add_item("(DEBUG) Reset video", &reset_video.emit);
                menu_ = produce();
            }
            menu_container_.add_child(menu_);
        }

        ///Destroy the PongGUI.
        ~this()
        {
            monitor_.die();

            if(credits_ !is null){clear(credits_);}

            menu_container_.die();

            game_start.disconnect_all();
            credits_start.disconnect_all();
            credits_end.disconnect_all();
            quit.disconnect_all();
            reset_video.disconnect_all();
        }

        ///Get the monitor widget.
        @property const(MonitorView) monitor() const {return monitor_;}

        ///Toggle monitor display.
        void monitor_toggle()
        {
            if(monitor_.visible){monitor_.hide();}
            else{monitor_.show();}
        }

        ///Show main menu.
        void menu_show(){menu_container_.show();};

        ///Hide main menu.
        void menu_hide(){menu_container_.hide();};

    private:
        ///Show credits screen (and hide main menu).
        void credits_show()
        {
            menu_hide();
            credits_ = new Credits(parent_);
            credits_.closed.connect(&credits_hide);
            credits_start.emit();
        }

        ///Hide credits screen (and show main menu).
        void credits_hide()
        {
            clear(credits_);
            credits_ = null;
            menu_show();
            credits_end.emit();
        }
}

class Pong
{
    mixin WeakSingleton;
    private:
        alias std.conv.to to;

        ///FPS counter.
        EventCounter fps_counter_;
        ///Continue running?
        bool continue_ = true;

        ///Platform used for user input.
        Platform platform_;

        ///Container managing video driver and its dependencies.
        VideoDriverContainer video_driver_container_;
        ///Video driver.
        VideoDriver video_driver_;

        ///Root of the GUI.
        GUIRoot gui_root_;
        
        ///Pong GUI.
        PongGUI gui_;
       
        ///Used for memory monitoring.
        MemoryMonitorable memory_;

        ///Container managing game and its dependencies.
        GameContainer game_container_;
        ///Game.
        Game game_;

        ///Monitor subsystem, providing debugging and profiling info.
        MonitorManager monitor_;

    public:
        ///Initialize Pong.
        this()
        {
            writeln("Initializing Pong");
            scope(failure){writeln("Pong initialization failed");}

            singleton_ctor();

            scope(failure)
            {
                clear(monitor_);
                clear(memory_);
                singleton_dtor();
            }
            monitor_ = new MonitorManager();
            memory_ = new MemoryMonitorable;

            scope(failure){monitor_.remove_monitorable("Memory");}
            monitor_.add_monitorable(memory_, "Memory");

            scope(failure)
            {
                clear(platform_);
                platform_ = null;
            }
            platform_ = new SDLPlatform;

            scope(failure)
            {
                clear(video_driver_container_);
            }
            video_driver_container_ = new VideoDriverContainer;
            video_driver_ = video_driver_container_.produce!(SDLGLVideoDriver)
                            (800, 600, ColorFormat.RGBA_8, false);
            scope(failure){monitor_.remove_monitorable("Video");}
            monitor_.add_monitorable(video_driver_, "Video");

            //initialize GUI
            scope(failure){clear(gui_root_);}
            gui_root_ = new GUIRoot(platform_);

            scope(failure){clear(gui_);}
            gui_ = new PongGUI(gui_root_.root, monitor_);
            gui_.credits_start.connect(&credits_start);
            gui_.credits_end.connect(&credits_end);
            gui_.game_start.connect(&game_start);
            gui_.quit.connect(&exit);
            gui_.reset_video.connect(&reset_video);

            game_container_ = new GameContainer();

            //Update FPS every second.
            fps_counter_ = EventCounter(1.0);
            fps_counter_.update.connect(&fps_update);
        }

        ///Destroy Pong and all subsystems.
        ~this()
        {
            writeln("Destroying Pong");
         
            //game might still be running if we're quitting
            //because the platform stopped to run
            if(game_ !is null)
            {
                game_.end_game();
                game_container_.destroy();
                game_ = null;
            }

            clear(fps_counter_);

            monitor_.remove_monitorable("Memory");
            //video driver might be already destroyed in exceptional circumstances
            if(video_driver_ !is null){monitor_.remove_monitorable("Video");}

            clear(gui_);
            clear(gui_root_);
            clear(monitor_);

            //video driver might be already destroyed in exceptional circumstances
            if(video_driver_ !is null)
            {
                video_driver_container_.destroy();
                clear(video_driver_container_);
                video_driver_ = null;
            }

            clear(platform_);
            platform_ = null;

            clear(memory_);

            singleton_dtor();
        }

        ///Update Pong.
        void run()
        {                           
            ulong iterations = 0;

            scope(failure)
            {
                writeln("Failure in Pong main loop, iteration ", iterations);
            }

            platform_.key.connect(&key_handler_global);
            platform_.key.connect(&key_handler);

            while(platform_.run() && continue_)
            {
                //Count this frame
                fps_counter_.event();

                const bool game_run = game_ !is null && game_.run();
                if(game_ !is null && !game_run){game_end();}

                //update game state
                gui_root_.update();

                video_driver_.start_frame();

                if(game_run){game_.draw(video_driver_);}

                gui_root_.draw(video_driver_);
                video_driver_.end_frame();
            
                memory_.update();
            
                iterations++;
            }
            writeln("FPS statistics:\n", fps_counter_.statistics, "\n");
        }

    private:
        ///Start game.
        void game_start()
        {
            gui_.menu_hide();
            platform_.key.disconnect(&key_handler);
            game_ = game_container_.produce(platform_, monitor_, gui_root_.root);
            game_.intro();
        }

        ///End game.
        void game_end()
        {
            game_container_.destroy();
            game_ = null;
            platform_.key.connect(&key_handler);
            gui_.menu_show();
        }

        ///Show credits screen.
        void credits_start(){platform_.key.disconnect(&key_handler);}

        ///Hide (destroy) credits screen.
        void credits_end(){platform_.key.connect(&key_handler);}

        ///Exit Pong.
        void exit(){continue_ = false;}

        /**
         * Process keyboard input.
         *
         * Params:  state   = State of the key.
         *          key     = Keyboard key.
         *          unicode = Unicode value of the key.
         */
        void key_handler(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {                   
                switch(key)
                {
                    case Key.Escape:
                        exit();
                        break;
                    case Key.Return:
                        game_start();
                        break;
                    default:
                        break;
                }
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
        void key_handler_global(KeyState state, Key key, dchar unicode)
        {
            if(state == KeyState.Pressed)
            {
                switch(key)
                {
                    case Key.K_1:
                        video_driver_.draw_mode(DrawMode.Immediate);
                        break;
                    case Key.K_2:
                        video_driver_.draw_mode(DrawMode.RAMBuffers);
                        break;
                    case Key.K_3:
                        video_driver_.draw_mode(DrawMode.VRAMBuffers);
                        break;
                    case Key.F10:
                        gui_.monitor_toggle();
                        break;
                    case Key.Scrollock:
                        save_screenshot();
                        break;
                    default:
                        break;
                }
            }
        }

        ///Update FPS display.
        void fps_update(real fps)
        {
            platform_.window_caption = "FPS: " ~ to!string(fps);
        }

        ///Reset video mode.
        void reset_video(){reset_video_driver(800, 600, ColorFormat.RGBA_8);}

        /**
         * Reset video driver with specified video mode.
         *
         * Params:  width  = Window/screen width to use.
         *          height = Window/screen height to use.
         *          format = Color format of video mode.
         */
        void reset_video_driver(in uint width, in uint height, in ColorFormat format)
        {

            //game area
            const Rectanglef area = game_.game_area;

            monitor_.remove_monitorable("Video");

            video_driver_container_.destroy();
            scope(failure){(video_driver_ = null);}
            try
            {
                video_driver_ = video_driver_container_.produce!(SDLGLVideoDriver)
                                (width, height, format, false);
            }
            catch(VideoDriverException e)
            {
                writeln("Video driver reset failed:", e.msg);
                exit();
                return;
            }

            //Zoom according to the new video mode.
            const real w_mult = width / area.width;
            const real h_mult = height / area.height;
            const real zoom = min(w_mult, h_mult);

            //Center game area on screen.
            Vector2d offset;
            offset.x = area.min.x + (w_mult / zoom - 1.0) * 0.5 * area.width * -1.0; 
            offset.y = area.min.y + (h_mult / zoom - 1.0) * 0.5 * area.height * -1.0;

            video_driver_.zoom(zoom);
            video_driver_.view_offset(offset);
            gui_root_.realign(video_driver_);
            monitor_.add_monitorable(video_driver_, "Video");
        }

        ///Save screenshot (to data/main/screenshots).
        void save_screenshot()
        {
            Image screenshot;

            video_driver_.screenshot(screenshot);

            try
            {
                ensure_directory_user("main::screenshots");

                //save screenshot with increasing suffix number.
                for(uint s = 0; s < 100000; s++)
                {
                    string file_name = format("main::screenshots/screenshot_%05d.png", s);
                    if(!file_exists_user(file_name))
                    {
                        write_image(screenshot, file_name);
                        return;
                    }
                }
                writeln("Screenshot saving error: too many screenshots");
            }
            catch(FileIOException e){writeln("Screenshot saving error: " ~ e.msg);}
            catch(ImageFileException e){writeln("Screenshot saving error: " ~ e.msg);}
        }
}
