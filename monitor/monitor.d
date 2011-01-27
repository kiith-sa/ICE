module monitor.monitor;


import physics.physicsengine;
import video.videodriver;
import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.monitormenu;
import monitor.submonitor;

import std.stdio;


///Displays various debugging/profiling information about engine subsystems.
final class Monitor : GUIElement
{
    private:
        //Main menu used to access menus of subsystems' monitors.
        GUIMenu main_menu_;
        //Currently shown menu (can be the main menu or a subsystem monitor menu).
        GUIMenu current_menu_;
        GUIElement current_monitor_ = null;

    public:

        ///Return font size to be used by monitor widgets.
        static uint font_size(){return 8;}

    protected:
        /**
         * Construct a new monitor with specified parameters.
         * 
         * See_Also: GUIElement.this
         *
         * Params:  x      = X position math expression.
         *          y      = Y position math expression. 
         *          width  = Width math expression. 
         *          height = Height math expression. 
         */
        this(string x, string y, string width, string height)
        {
            super("16", "16", "192 + w_right / 4", "168 + w_bottom / 6");

            with(new GUIMenuFactory)
            {
                x = "p_left";
                y = "p_top";
                orientation = MenuOrientation.Horizontal;
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
                item_font_size = font_size;
                add_item("Video", &video);
                add_item("Physics", &physics);
                main_menu_ = produce();
            }

            current_menu_ = main_menu_;
            add_child(main_menu_);
        }
        override void update(){update_children();}

    private:
        //Display video driver monitor.
        void video(){menu(VideoDriver.get.monitor_menu);}

        //Display physics engine monitor.
        void physics(){menu(PhysicsEngine.get.monitor_menu);}

        //Replace main menu with specified monitor menu.
        void menu(MonitorMenu menu)
        {
            if(current_menu_ is main_menu_){main_menu_.hide();}

            menu.back.connect(&show_main_menu);
            menu.set_monitor.connect(&monitor);

            current_menu_ = menu;
            add_child(current_menu_);
        }

        //Show main menu, removing currently shown submenu.
        void show_main_menu()
        in
        {
            assert(main_menu_ != current_menu_ && !main_menu_.visible,
                   "Trying to show monitor main menu even though it's shown already");
        }
        body
        {
            writefln("show_main_menu");
            remove_child(current_menu_);
            current_menu_.die();
            main_menu_.show();
            current_menu_ = main_menu_;
            writefln("show_main_menu end");
        }

        //Show given monitor, replacing any monitor previously shown.
        void monitor(SubMonitor monitor)
        {
            if(current_monitor_ !is null)
            {
                remove_child(current_monitor_);
                current_monitor_.die();
            }

            current_monitor_ = monitor;
            add_child(current_monitor_);
        }
}

/**
 * Factory used for monitor construction.
 *
 * See_Also: GUIElementFactoryBase
 */
final class MonitorFactory : GUIElementFactoryBase!(Monitor)
{
    public Monitor produce(){return new Monitor(x_, y_, width_, height_);}
}
