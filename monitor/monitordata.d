
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Interface providing access to submonitors (returned by a monitorable).
module monitor.monitordata;
@safe


import std.algorithm;

import monitor.submonitor;


//needs better naming
///Interface passed by Monitorables to the MonitorManager to access SubMonitors.
interface MonitorDataInterface
{
    ///Get names of submonitors available.
    @property const(string[]) monitor_names() const;

    ///Start monitor with specified name.
    void start_monitor(in string name);

    ///Stop monitor with specified name.
    void stop_monitor(in string name);

    ///Access monitor with specified name.
    SubMonitor get_monitor(in string name);
}


//needs better naming
///MonitorData implementation providing access to submonitors of monitorable of specified type.
final class MonitorData(M) : MonitorDataInterface
{
    private:
        ///"Constructor" functions to get submonitors from.
        SubMonitor function(M)[string] constructors_;

        ///Currently running submonitors.
        SubMonitor[string] monitors_;

        ///Monitored object.
        M monitored_;

    public:
        /**
         * Construct a MonitorManager providing access to monitors monitoring specified object.
         * 
         * Params:  monitored    = Monitored object.
         *          constructors = "Constructor" functions to get submonitors from.
         */
        this(M monitored, SubMonitor function(M)[string] constructors)
        {
            monitored_ = monitored;
            constructors_ = constructors;
        }

        ~this()
        {
            foreach(monitor; monitors_){clear(monitor);}
            monitors_ = null;
            constructors_ = null;
        }

        @property const(string[]) monitor_names() const {return constructors_.keys;}

        void start_monitor(in string name)
        {
            monitors_[name] = constructors_[name](monitored_);
        }

        void stop_monitor(in string name)
        in
        {
            assert(canFind(monitors_.keys, name), 
                   "Trying to stop a monitor that is not running");
        }
        body
        {
            clear(monitors_[name]);
            monitors_.remove(name);
        }

        SubMonitor get_monitor(in string name)
        in
        {
            assert(canFind(monitors_.keys, name), "Trying to access a nonexistent monitor");
        }
        body
        {
            return monitors_[name];
        }
}
