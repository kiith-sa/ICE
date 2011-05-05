
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module monitor.monitormanager;
@safe


import std.array;
import std.algorithm;

import util.weaksingleton;
import gui.guielement;
import gui.guimenu;
import math.vector2;
import math.math;
import time.timer;
import monitor.submonitor;
import monitor.monitorable;
import monitor.monitordata;
import util.signal;
import workarounds;


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
final class MonitorManager
{
    private:
        mixin WeakSingleton;

        ///Monitor data of each monitorable, indexed by name.
        MonitorDataInterface[string] monitored_;

        ///Monitor ID's of pinned monitors.
        MonitorID[] pinned_;

    public:
        ///Construct a MonitorManager.
        this(){singleton_ctor();}

        ///Destroy the MonitorManager.
        void die()
        in
        {
            assert(monitored_.length == 0, 
                   "All monitorables must be removed before destroying monitor. \n"
                   "Not removed: " ~ join(monitored_.keys, " "));
        }
        body{singleton_dtor();}

        /**
         * Add a monitorable.
         *
         * Params:  monitorable = Monitorable to add.
         *          name        = Name to use for the monitorable. Must be unique.
         */
        void add_monitorable(Monitorable monitorable, in string name)
        in
        {
            assert(!canFind(monitored_.keys, name),
                   "Trying to add a monitorable with name that is already used");
        }
        body
        {
            monitored_[name] = monitorable.monitor_data;
            update_views.emit();
        }

        ///Remove monitorable with specified name.
        void remove_monitorable(in string name)
        in
        {
            assert(canFind(monitored_.keys, name), 
                   "Trying to remove a monitorable that is not present");
        }
        body
        {
            //unpin all pinned monitors
            workarounds.remove(pinned_, (ref MonitorID id){return id.monitored == name;});
            monitored_[name].die();
            monitored_.remove(name);
            update_views.emit();
        }

    package:
        ///Emitted when the view/s viewing this monitor need to be updated.
        mixin Signal!() update_views;

        ///Get names of monitored objects.
        @property const(string[]) monitored_names() const {return monitored_.keys;}

        ///Get names of monitors of the specified monitored object.
        @property const(string[]) monitor_names(in string monitored) const
        in
        {
            assert(canFind(monitored_.keys, monitored), 
                   "Trying to get monitor names of a monitorable that is not present");
        }
        body
        {
            return monitored_[monitored].monitor_names();
        }

        ///Start specified monitor (unless it's pinned).
        void start(in MonitorID id)
        in
        {
            assert(canFind(monitored_.keys, id.monitored),
                   "Trying to start monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].start_monitor(id.monitor);}
        }

        ///Stop specified monitor (unless it's pinned).
        void stop(in MonitorID id)
        in
        {
            assert(canFind(monitored_.keys, id.monitored),
                   "trying to stop monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].stop_monitor(id.monitor);}
        }

        ///Get specified submonitor.
        SubMonitor get(in MonitorID id)
        in
        {
            assert(canFind(monitored_.keys, id.monitored),
                   "trying to get monitor of a monitorable that is not present");
        }
        body{return monitored_[id.monitored].get_monitor(id.monitor);}

        ///Pin specified monitor. Pinned monitors can't be stopped or started.
        void pin(in MonitorID id)
        in
        {
            assert(!pinned(id), "Trying to pin a monitor that is already pinned");
            assert(canFind(monitored_.keys, id.monitored),
                   "Trying to pin monitor of a monitorable that is not present");
        }
        body{pinned_ ~= id;}

        ///Unpin specified monitor. Pinned monitors can't be stopped or started.
        void unpin(MonitorID id)
        in{assert(pinned(id), "Trying to unpin a monitor that is not pinned");}
        body
        {
            workarounds.remove(pinned_, id);
        }

        ///Is a submonitor pinned?
        bool pinned(in MonitorID id){return pinned_.canFind(id);}
}


///GUI view of the monitor subsystem.
final class MonitorView : GUIElement
{
    private:
        ///MonitorManager we're viewing.
        MonitorManager monitor_;

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
         *          monitor = MonitorManager to view.
         */
        this(in GUIElementParams params, MonitorManager monitor)
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
            //copying due to phobos not yet working correctly with const/immutable
            string[] monitored_names = monitor_.monitored_names.dup;
            if(!monitored_names.canFind(current_monitored_))
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
                add_item("Hide", {set_monitor(id);});

                //if we're at top level, add menu items, callbacks for each monitorable
                if(current_monitored_ is null)
                {
                    //used to avoid a compiler bug with closures, seems to be #2043
                    void add_monitored_button(in string monitored)
                    {
                        add_item(monitored, {set_monitored(monitored);});
                    }
                    foreach(monitored; monitor_.monitored_names)
                    {
                        add_monitored_button(monitored);
                    }
                }
                //add menu items, callbacks for each submonitor and a back button.
                else
                {
                    //used to avoid a compiler bug with closures, seems to be #2043
                    void add_monitor_button(in string monitored, in string monitor)
                    {
                        add_item(monitor, {set_monitor(MonitorID(monitored, monitor));});
                    }
                    add_item("Back", {set_monitored(null);});
                    foreach(monitor; monitor_.monitor_names(current_monitored_))
                    {
                        add_monitor_button(current_monitored_, monitor);
                    }
                }

                menu_ = produce();
            }

            add_child(menu_);
        }


        ///Set specified monitored object.
        void set_monitored(in string monitored)
        {
            current_monitored_ = monitored;
            regenerate();
        }

        ///Set specified submonitor.
        void set_monitor(in MonitorID id)
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
    @property bool is_null() const {return monitored is null;}
}

///Factory producing MonitorViews.
final class MonitorViewFactory : GUIElementFactoryBase!(MonitorView)
{
    private:
        ///MonitorManager to be viewed by produced view/s.
        MonitorManager monitor_;

    public:
        ///Construct a MonitorViewFactory with specified monitor.
        this(MonitorManager monitor){monitor_ = monitor;}

        override MonitorView produce()
        {
            return new MonitorView(gui_element_params, monitor_);
        }
}
