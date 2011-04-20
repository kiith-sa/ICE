
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module monitor.monitor;


import std.string : join;

import util.weaksingleton;
import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.submonitor;
import monitor.monitorable;
import monitor.monitordata;
import containers.array;
import util.signal;
import util.action;


/**
 * Monitor subsystem.
 * 
 * Provides access to monitors of classes implementing the Monitorable 
 * interface, and can be viewed through MonitorView (GUI frontend).
 *
 * Signal:
 *
 *     package mixin Signal!() update_views
 *
 *     Used to update views viewing this monitor e.g. when a monitorable is added/removed.
 */
final class Monitor
{
    private:
        mixin WeakSingleton;

        ///Monitor data of each monitorable, indexed by name.
        MonitorData[string] monitored_;

        ///Monitor ID's of pinned monitors.
        MonitorID[] pinned_;

    public:
        ///Construct a Monitor.
        this(){singleton_ctor();}

        ///Destroy the Monitor.
        void die()
        in
        {
            assert(monitored_.length == 0, 
                   "All monitorables must be removed before destroying monitor. \n"
                   "Not removed: " ~ monitored_.keys.join(" "));
        }
        body{singleton_dtor();}


        /**
         * Add a monitorable.
         *
         * Params:  monitorable = Monitorable to add.
         *          name        = Name to use for the monitorable. Must be unique.
         */
        void add_monitorable(Monitorable monitorable, string name)
        in
        {
            assert(!monitored_.keys.contains(name), 
                    "Trying to add a monitorable with name that is already used");
        }
        body
        {
            monitored_[name] = monitorable.monitor_data;
            update_views.emit();
        }

        ///Remove monitorable with specified name.
        void remove_monitorable(string name)
        in
        {
            assert(monitored_.keys.contains(name), 
                   "Trying to remove a monitorable that is not present");
        }
        body
        {
            //unpin all pinned monitors
            pinned_.remove((ref MonitorID id){return id.monitored == name;});
            monitored_[name].die();
            monitored_.remove(name);
            update_views.emit();
        }

    package:
        ///Emitted when the view/s viewing this monitor need to be updated.
        mixin Signal!() update_views;

        ///Get names of monitored objects.
        string[] monitored_names(){return monitored_.keys;}

        ///Get names of monitors of the specified monitored object.
        string[] monitor_names(string monitored)
        in
        {
            assert(monitored_.keys.contains(monitored), 
                   "Trying to get monitor names of a monitorable that is not present");
        }
        body{return monitored_[monitored].monitor_names();}

        ///Start specified monitor (unless it's pinned).
        void start(MonitorID id)
        in
        {
            assert(monitored_.keys.contains(id.monitored), 
                   "Trying to start monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].start_monitor(id.monitor);}
        }

        ///Stop specified monitor (unless it's pinned).
        void stop(MonitorID id)
        in
        {
            assert(monitored_.keys.contains(id.monitored), 
                   "trying to stop monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].stop_monitor(id.monitor);}
        }

        ///Get specified monitor. Should return const in D2.
        SubMonitor get(MonitorID id)
        in
        {
            assert(monitored_.keys.contains(id.monitored), 
                   "trying to get monitor of a monitorable that is not present");
        }
        body{return monitored_[id.monitored].get_monitor(id.monitor);}

        ///Pin specified monitor. Pinned monitors can't be stopped or started.
        void pin(MonitorID id)
        in
        {
            assert(!pinned(id), "Trying to pin a monitor that is already pinned");
            assert(monitored_.keys.contains(id.monitored), 
                   "Trying to pin monitor of a monitorable that is not present");
        }
        body{pinned_ ~= id;}

        ///Unpin specified monitor. Pinned monitors can't be stopped or started.
        void unpin(MonitorID id)
        in{assert(pinned(id), "Trying to unpin a monitor that is not pinned");}
        body{pinned_.remove(id);}

        ///Is a submonitor pinned?
        bool pinned(MonitorID id){return pinned_.contains(id);}
}

///GUI view of the monitor subsystem.
final class MonitorView : GUIElement
{
    private:
        ///Monitor we're viewing.
        Monitor monitor_;

        ///Menu used to select monitored objects or submonitors to view.
        GUIMenu menu_ = null;
        ///Currently shown submonitor view.
        SubMonitorView current_view_;

        ///Name of the monitored object currently shown by the menu (null if none).
        string current_monitored_;

        ///ID of currently viewed submonitor (contents as null if none).
        MonitorID current_monitor_;

    public:
        ///Return font size for monitor widgets to use.
        static uint font_size(){return 8;}

        override void die()
        {
            monitor_.update_views.disconnect(&regenerate);
            super.die();
        }

    protected:
        /**
         * Construct a MonitorView.
         *
         * Params:  params  = Parameters for GUIElement constructor.
         *          monitor = Monitor to view.
         */
        this(GUIElementParams params, Monitor monitor)
        {          
            super(params);

            monitor_ = monitor;
            monitor.update_views.connect(&regenerate);
            regenerate();
        }

    private:
        ///Destroy and regenerate menu of the view.
        void regenerate()
        {
            //destroy menu, if any
            if(menu_ !is null)
            {
                remove_child(menu_);
                menu_.die();
                menu_ = null;
            }

            //current monitored might have been removed by the monitor, so check for that
            string[] monitored_names = monitor_.monitored_names;
            if(!monitored_names.contains(current_monitored_))
            {
                if(current_monitor_.monitored == current_monitored_)
                {
                    //must do this here, set_monitor would try to stop nonexistent monitor
                    current_monitor_.set_null();
                    //will also destroy the view
                    set_monitor(current_monitor_);
                }
                current_monitored_ = null;
            }

            //generate the menu
            with(new GUIMenuHorizontalFactory)
            {
                x = "p_left";
                y = "p_top";
                item_width = "44";
                item_height = "14";
                item_spacing = "4";
                item_font_size = font_size;

                //hide will set null monitor
                MonitorID id;
                id.set_null();
                add_item("Hide", new Action!(MonitorID)(&set_monitor, id));

                //if we're at top level, add menu items, callbacks for each monitorable
                if(current_monitored_ is null)
                {
                    foreach(monitored; monitor_.monitored_names)
                    {
                        add_item(monitored, new Action!(string)(&set_monitored, monitored));
                    }
                }
                //add menu items, callbacks for each submonitor and a back button.
                else
                {
                    add_item("Back", new Action!(string)(&set_monitored, null));
                    foreach(monitor; monitor_.monitor_names(current_monitored_))
                    {
                        id = MonitorID(current_monitored_, monitor);
                        add_item(monitor, new Action!(MonitorID)(&set_monitor, id));
                    }
                }

                menu_ = produce();
            }

            add_child(menu_);
        }

        ///Set specified monitored object.
        void set_monitored(string monitored)
        {
            current_monitored_ = monitored;
            regenerate();
        }

        ///Set specified submonitor.
        void set_monitor(MonitorID id)
        {
            //will be stopped if not pinned
            if(!current_monitor_.is_null){monitor_.stop(current_monitor_);}
            if(current_view_ !is null)
            {
                current_view_.toggle_pinned.disconnect(&toggle_pinned);
                current_view_.die();
                current_view_ = null;
            }

            current_monitor_ = id;

            //if null monitor is set, we don't need to start it.
            if(id.is_null){return;}

            monitor_.start(id);
            current_view_ = monitor_.get(id).view;
            add_child(current_view_);
            current_view_.toggle_pinned.connect(&toggle_pinned);
            current_view_.set_pinned(monitor_.pinned(current_monitor_));
        }

        ///Pin/unpin currently viewed monitor.
        void toggle_pinned()
        {
            if(!monitor_.pinned(current_monitor_)){monitor_.pin(current_monitor_);}
            else{monitor_.unpin(current_monitor_);}
        }
}

///Struct identifying a submonitor.
private struct MonitorID
{
    ///Name of the monitored object the submonitor belongs to.
    string monitored;
    ///Name of the submonitor.
    string monitor;

    ///Set this submonitor to "null" (no submonitor).
    void set_null(){monitored = monitor = null;}
    ///Is the submonitor "null"?
    bool is_null(){return monitored is null;}
}

///Factory producing MonitorViews.
final class MonitorViewFactory : GUIElementFactoryBase!(MonitorView)
{
    private:
        ///Monitor to be viewed by produced view/s.
        Monitor monitor_;

    public:
        ///Construct a MonitorViewFactory with specified monitor.
        this(Monitor monitor){monitor_ = monitor;}

        override MonitorView produce()
        {
            return new MonitorView(gui_element_params, monitor_);
        }
}
