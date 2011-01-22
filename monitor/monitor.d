module monitor.monitor;


import physics.physicsengine;
import video.videodriver;
import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.monitormenu;


///Displays various debugging/profiling information about engine subsystems.
final class Monitor : GUIElement
{
    private:
        //Main menu used to access menus of subsystems' monitors.
        GUIMenu main_menu_;
        //Currently shown menu (can be the main menu or a subsystem monitor menu).
        GUIMenu current_menu_;
        GUIElement current_monitor_ = null;
        Timer update_timer_;

    public:
        ///Construct a new monitor with specified parameters.
        this()
        {
            super();

            main_menu_ = current_menu_ = new GUIMenu;
            with(main_menu_)
            {
                position_x = "p_left";
                position_y = "p_top";
                orientation = MenuOrientation.Horizontal;

                add_item("Video", &video);
                add_item("Physics", &physics);

                item_font_size = 8;
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
            }
            add_child(main_menu_);

            update_timer_ = Timer(0.5);
        }

        ///Return font size to be used by monitor widgets.
        static uint font_size(){return 8;}

    protected:
        override void update()
        {
            if(update_timer_.expired())
            {
                update_children();
                update_timer_.reset();
            }
        }

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
            remove_child(current_menu_);
            current_menu_.die();
            main_menu_.show();
            current_menu_ = main_menu_;
        }

        //Show given monitor, replacing any monitor previously shown.
        void monitor(GUIElement monitor)
        {
            if(current_monitor_ !is null)
            {
                remove_child(current_monitor_);
                current_monitor_.die();
            }

            current_monitor_ = monitor;
            with(current_monitor_)
            {
                position_x = "p_left + 4";
                position_y = "p_top + 22";
                width = "p_right - p_left - 8";
                height = "p_bottom - p_top - 26";
            }
            add_child(current_monitor_);
        }
}
