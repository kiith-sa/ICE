module monitor.monitor;


import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.monitormenu;
import monitor.submonitor;
import monitor.monitorable;


///Displays various debugging/profiling information about engine subsystems.
final class Monitor : GUIElement
{
    private:
        /*
         * Used to hold a callback to show a monitor menu of a monitorable.
         *
         * Should be replaced by a closure in D2
         */
        class MonitorableCallback
        {
            private:
                //The monitorable class.
                Monitorable monitorable_;
            public:
                //Construct a callback for specified monitorable.
                this(Monitorable monitorable){monitorable_ = monitorable;}

                //Show monitor menu of the monitorable.
                void show_menu(){menu(monitorable_.monitor_menu);}
        }

        //Main menu used to access menus of subsystems' monitors.
        GUIMenuHorizontal main_menu_;
        //Currently shown submenu(if any).
        MonitorMenu current_menu_;
        //Currently shown monitor.
        GUIElement current_monitor_ = null;
        //Callbacks to show monitor menus.
        MonitorableCallback[] callbacks;

    public:
        ///Return font size to be used by monitor widgets.
        static uint font_size(){return 8;}

    protected:
        /**
         * Construct a new monitor with specified parameters.
         * 
         * See_Also: GUIElement.this
         *
         * Params:  x            = X position math expression.
         *          y            = Y position math expression. 
         *          width        = Width math expression. 
         *          height       = Height math expression. 
         *          monitorables = Interfaces to classes to monitor, with names to use.
         */
        this(string x, string y, string width, string height, 
             MonitorableData[] monitorables)
        in
        {
            foreach(monitorable; monitorables)
            {
                assert(monitorable.monitorable !is null, "Can't monitor a null class");
            }
        }
        body
        {
            super(x, y, width, height);

            with(new GUIMenuHorizontalFactory)
            {
                x = "p_left";
                y = "p_top";
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
                item_font_size = font_size;
                foreach(monitorable; monitorables)
                {
                    auto callback = new MonitorableCallback(monitorable.monitorable);
                    add_item(monitorable.name, &callback.show_menu);
                    callbacks ~= callback;
                }
                main_menu_ = produce();
            }

            add_child(main_menu_);
        }
        override void update(){update_children();}

    private:
        //Replace main menu with specified monitor menu.
        void menu(MonitorMenu menu)
        in
        {
            assert(main_menu_.visible, "Trying to replace main menu but it's not visible");
        }
        body
        {
            main_menu_.hide();

            menu.back.connect(&show_main_menu);
            menu.set_monitor.connect(&monitor);

            current_menu_ = menu;
            add_child(menu.menu);
        }

        //Show main menu, removing currently shown submenu.
        void show_main_menu()
        in
        {
            assert(!main_menu_.visible,
                   "Trying to show monitor main menu even though it's shown already");
        }
        body
        {
            remove_child(current_menu_.menu);
            current_menu_.die();
            current_menu_ = null;
            main_menu_.show();
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
 *
 * Params:  add_monitorable = Add a class to be monitored, with specified name.
 */
final class MonitorFactory : GUIElementFactoryBase!(Monitor)
{
    private:
        MonitorableData[] monitorables_;

    public:
        void add_monitorable(string name, Monitorable monitorable)
        {
            monitorables_ ~= MonitorableData(name, monitorable);
        }

        Monitor produce(){return new Monitor(x_, y_, width_, height_, monitorables_);}
}

private:

//Data needed to add a monitorable to the monitor.
struct MonitorableData
{
    //Name to use to identify the monitorable.
    string name;
    //Monitorable itself.
    Monitorable monitorable;
}                                          
