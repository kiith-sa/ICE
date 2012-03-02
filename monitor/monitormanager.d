
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitor subsystem.
module monitor.monitormanager;


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


/**
 * Monitor subsystem.
 * 
 * Provides access to monitors of classes implementing the Monitorable 
 * interface, and can be viewed through MonitorView (GUI frontend).
 *
 * Signal:
 *
 *     package mixin Signal!() updateViews
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
        this(){singletonCtor();}

        ///Destroy the MonitorManager.
        ~this()
        in
        {
            assert(monitored_.length == 0, 
                   "All monitorables must be removed before destroying monitor. \n"
                   "Not removed: " ~ join(monitored_.keys, " "));
        }
        body{singletonDtor();}

        /**
         * Add a monitorable.
         *
         * Params:  monitorable = Monitorable to add.
         *          name        = Name to use for the monitorable. Must be unique.
         */
        void addMonitorable(Monitorable monitorable, const string name)
        in
        {
            assert((name in monitored_ ) is null,
                   "Trying to add a monitorable with name that is already used");
        }
        body
        {
            monitored_[name] = monitorable.monitorData;
            updateViews.emit();
        }

        ///Remove monitorable with specified name.
        void removeMonitorable(const string name)
        in
        {
            assert((name in monitored_ ) !is null,
                   "Trying to remove a monitorable that is not present");
        }
        body
        {
            //unpin all pinned monitors
            pinned_ = remove!((ref MonitorID id){return id.monitored == name;})(pinned_);
            monitored_[name].die();
            monitored_.remove(name);
            updateViews.emit();
        }

    package:
        ///Emitted when the view/s viewing this monitor need to be updated.
        mixin Signal!() updateViews;

        ///Get names of monitored objects.
        @property const(string[]) monitoredNames() const {return monitored_.keys;}

        ///Get names of monitors of the specified monitored object.
        @property const(string[]) monitorNames(const string monitored) const
        in
        {
            assert((monitored in monitored_ ) !is null,
                   "Trying to get monitor names of a monitorable that is not present");
        }
        body
        {
            return monitored_[monitored].monitorNames();
        }

        ///Start specified monitor (unless it's pinned).
        void start(const MonitorID id)
        in
        {
            assert((id.monitored in monitored_ ) !is null,
                   "Trying to start monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].startMonitor(id.monitor);}
        }

        ///Stop specified monitor (unless it's pinned).
        void stop(const MonitorID id)
        in
        {
            assert((id.monitored in monitored_ ) !is null,
                   "Trying to stop monitor of a monitorable that is not present");
        }
        body
        {
            if(!pinned(id)){monitored_[id.monitored].stopMonitor(id.monitor);}
        }

        ///Get specified submonitor.
        SubMonitor get(const MonitorID id)
        in
        {
            assert((id.monitored in monitored_ ) !is null,
                   "Trying to get monitor of a monitorable that is not present");
        }
        body{return monitored_[id.monitored].getMonitor(id.monitor);}

        ///Pin specified monitor. Pinned monitors can't be stopped or started.
        void pin(const MonitorID id) pure
        in
        {
            assert(!pinned(id), "Trying to pin a monitor that is already pinned");
            assert((id.monitored in monitored_ ) !is null,
                   "Trying to pin monitor of a monitorable that is not present");
        }
        body{pinned_ ~= id;}

        ///Unpin specified monitor. Pinned monitors can't be stopped or started.
        void unpin(MonitorID id)
        in{assert(pinned(id), "Trying to unpin a monitor that is not pinned");}
        body
        {
            pinned_ = remove!((ref MonitorID a){return a == id;})(pinned_);
        }

        ///Is a submonitor pinned?
        bool pinned(const MonitorID id) pure {return pinned_.canFind(id);}
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
        SubMonitorView currentView_;

        ///Name of the monitored object currently shown by the menu (null if none).
        string currentMonitored_;

        ///ID of currently viewed submonitor (contents as null if none).
        MonitorID currentMonitor_;

    public:
        ///Return font size for monitor widgets to use.
        static uint fontSize() pure {return 8;}

        ~this(){monitor_.updateViews.disconnect(&regenerate);}

    protected:
        /**
         * Construct a MonitorView.
         *
         * Params:  params  = Parameters for GUIElement constructor.
         *          monitor = MonitorManager to view.
         */
        this(const GUIElementParams params, MonitorManager monitor)
        {          
            super(params);

            monitor_ = monitor;
            monitor.updateViews.connect(&regenerate);
            regenerate();
        }

    private:
        ///Destroy and regenerate menu of the view.
        void regenerate()
        {
            //destroy menu, if any
            if(menu_ !is null)
            {
                removeChild(menu_);
                menu_.die();
                menu_ = null;
            }

            //current monitored might have been removed by the monitor, so check for that
            //copying due to phobos not yet working correctly with const/immutable
            string[] monitoredNames = monitor_.monitoredNames.dup;
            if(!monitoredNames.canFind(currentMonitored_))
            {
                if(currentMonitor_.monitored == currentMonitored_)
                {
                    //must do this here, setMonitor would try to stop nonexistent monitor
                    currentMonitor_.setNull();
                    //will also destroy the view
                    setMonitor(currentMonitor_);
                }
                currentMonitored_ = null;
            }

            //generate the menu
            with(new GUIMenuHorizontalFactory)
            {
                x              = "p_left";
                y              = "p_top";
                itemWidth     = "44";
                itemHeight    = "14";
                itemSpacing   = "4";
                itemFontSize = fontSize;

                //hide will set null monitor
                MonitorID id;
                id.setNull();
                addItem("Hide", {setMonitor(id);});

                //if we're at top level, add menu items, callbacks for each monitorable
                if(currentMonitored_ is null)
                {
                    //used to avoid a compiler bug with closures, seems to be #2043
                    void addMonitoredButton(const string monitored)
                    {
                        addItem(monitored, {setMonitored(monitored);});
                    }
                    foreach(monitored; monitor_.monitoredNames)
                    {
                        addMonitoredButton(monitored);
                    }
                }
                //add menu items, callbacks for each submonitor and a back button.
                else
                {
                    //used to avoid a compiler bug with closures, seems to be #2043
                    void addMonitorButton(const string monitored, const string monitor)
                    {
                        addItem(monitor, {setMonitor(MonitorID(monitored, monitor));});
                    }
                    addItem("Back", {setMonitored(null);});
                    foreach(monitor; monitor_.monitorNames(currentMonitored_))
                    {
                        addMonitorButton(currentMonitored_, monitor);
                    }
                }

                menu_ = produce();
            }

            addChild(menu_);
        }


        ///Set specified monitored object.
        void setMonitored(const string monitored)
        {
            currentMonitored_ = monitored;
            regenerate();
        }

        ///Set specified submonitor.
        void setMonitor(const MonitorID id)
        {
            //will be stopped if not pinned
            if(!currentMonitor_.isNull){monitor_.stop(currentMonitor_);}
            if(currentView_ !is null)
            {
                currentView_.togglePinned.disconnect(&togglePinned);
                currentView_.die();
                currentView_ = null;
            }

            currentMonitor_ = id;

            //if null monitor is set, we don't need to start it.
            if(id.isNull){return;}

            monitor_.start(id);
            currentView_ = monitor_.get(id).view;
            addChild(currentView_);
            currentView_.togglePinned.connect(&togglePinned);
            currentView_.setPinned(monitor_.pinned(currentMonitor_));
        }

        ///Pin/unpin currently viewed monitor.
        void togglePinned()
        {
            if(!monitor_.pinned(currentMonitor_)){monitor_.pin(currentMonitor_);}
            else{monitor_.unpin(currentMonitor_);}
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
    void setNull() pure {monitored = monitor = null;}
    ///Is the submonitor "null"?
    @property bool isNull() const pure {return monitored is null;}
}

///Factory producing MonitorViews.
final class MonitorViewFactory : GUIElementFactoryBase!MonitorView
{
    private:
        ///MonitorManager to be viewed by produced view/s.
        MonitorManager monitor_;

    public:
        ///Construct a MonitorViewFactory with specified monitor.
        this(MonitorManager monitor){monitor_ = monitor;}

        override MonitorView produce()
        {
            return new MonitorView(guiElementParams, monitor_);
        }
}
