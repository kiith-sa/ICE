module monitor.monitor;


import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.monitormenu;
import monitor.submonitor;
import monitor.monitorable;
import arrayutil;


///Displays various debugging/profiling information about engine subsystems.
final class Monitor : GUIElement
{
    private:
        /*
         * Used to hold a callback to show a monitor menu of a monitorable.
         *
         * Should be replaced by a closure in D2.
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
                void show_menu(){menu(monitorable_);}
        }

        //Main menu used to access menus of subsystems' monitors.
        GUIMenuHorizontal main_menu_;
        //Currently shown submenu(if any).
        MonitorMenu current_menu_;
        //Monitorable to which the current monitor menu belongs.
        Monitorable current_menu_monitorable_;
        //Currently shown monitor.
        GUIElement current_monitor_;
        //Monitorable to which the current monitor belongs.
        Monitorable current_monitor_monitorable_;
        //Callbacks to show monitor menus.
        MonitorableCallback[] callbacks_;
        //Data about monitorables used to regenerate the main menu.
        MonitorableData[] monitorables_;

    public:
        ///Return font size to be used by monitor widgets.
        static uint font_size(){return 8;}

        /**
         * Add a monitorable with specified name.
         *
         * A menu item for the monitorable will appear with specified name,
         * providing access to monitor menu of the monitorable.
         *
         * Params:  name        = String to use the name of the monitorable (as menu item text)
         *          monitorable = Monitorable to add.
         */
        void add_monitorable(string name, Monitorable monitorable)
        in
        {
            assert(monitorables_.find(
                   (ref MonitorableData c){return c.monitorable is monitorable;})
                   == -1,
                   "Trying to add a monitorable that is already monitored by the monitor.");
        }
        body                                                     
        {
            monitorables_ ~= MonitorableData(name, monitorable);
            regenerate();
        }

        /**
         * Remove specified monitorable.
         *
         * Menu item for the monitorable wil be removed, and if its menu or any
         * of its monitors are active, they'll be disabled.
         *
         * Params:  monitorable = Monitorable to remove.
         */
        void remove_monitorable(Monitorable monitorable)
        in
        {
            assert(monitorables_.find(
                   (ref MonitorableData c){return c.monitorable is monitorable;})
                   != -1,
                   "Trying to remove a monitorable that is not monitored by the monitor.");
        }
        body                                                     
        {
            monitorables_.remove((ref MonitorableData c)
                                 {return c.monitorable is monitorable;});

            //disable any widgets that work with the monitorable we're removing
            if(monitorable is current_menu_monitorable_){show_main_menu();}
            if(monitorable is current_monitor_monitorable_){disable_monitor();}
            regenerate();
        }

    protected:
        /**
         * Construct a new monitor with specified parameters.
         * 
         * See_Also: GUIElement.this
         *
         * Params:  params = Parameters for GUIElement constructor.
         *          monitorables = Interfaces to classes to monitor, with names to use.
         */
        this(GUIElementParams params, MonitorableData[] monitorables)
        in
        {
            foreach(monitorable; monitorables)
            {
                assert(monitorable.monitorable !is null, "Can't monitor a null class");
            }
        }
        body
        {
            super(params);

            monitorables_ = monitorables;
            regenerate();
        }

        override void update(){update_children();}

    private:
        ///Generate the main menu, callbacks from monitorables.
        void regenerate()
        {
            bool visible = true;

            //If we already have a main menu, get rid of it.
            if(main_menu_ !is null)
            {
                //Save the visibility of the main menu, so it doesn't suddenly get
                //shown when we're already showing another menu.
                visible = main_menu_.visible;
                remove_child(main_menu_);
                main_menu_.die();
            }

            callbacks_ = null;

            //Generate main menu.
            with(new GUIMenuHorizontalFactory)
            {
                x = "p_left";
                y = "p_top";
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
                item_font_size = font_size;
                //Button to disable the current monitor.
                add_item("Disable", &disable_monitor);

                //Add menu items, callbacks for each monitorable
                foreach(monitorable; monitorables_)
                {
                    auto callback = new MonitorableCallback(monitorable.monitorable);
                    add_item(monitorable.name, &callback.show_menu);
                    callbacks_ ~= callback;
                }

                main_menu_ = produce();
            }
            if(!visible){main_menu_.hide();}
            add_child(main_menu_);
        }

        //Replace main menu with monitor menu of specified monitorable.
        void menu(Monitorable monitorable)
        in
        {
            assert(main_menu_.visible, "Trying to replace main menu but it's not visible");
        }
        body
        {
            main_menu_.hide();

            auto menu = monitorable.monitor_menu;
            menu.back.connect(&show_main_menu);
            menu.set_monitor.connect(&monitor);

            current_menu_ = menu;
            current_menu_monitorable_ = monitorable;
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
            current_menu_monitorable_ = null;
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
            //Remember the monitorable to which this monitor belongs.
            current_monitor_monitorable_ = current_menu_monitorable_;
            add_child(current_monitor_);
        }

        //Disable the current monitor.
        void disable_monitor()
        {
            if(current_monitor_ is null){return;}
            remove_child(current_monitor_);
            current_monitor_.die();
            current_monitor_ = null;
            current_monitor_monitorable_ = null;
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

        Monitor produce(){return new Monitor(gui_element_params, monitorables_);}
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
