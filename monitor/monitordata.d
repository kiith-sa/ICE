
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module monitor.monitordata;


import monitor.submonitor;
import containers.array;


//needs better naming
///Interface passed by Monitorables to the Monitor to access SubMonitors.
interface MonitorData
{
    ///Destroy the MonitorData.
    void die();

    ///Get names of submonitors available.
    string[] monitor_names();

    ///Start monitor with specified name.
    void start_monitor(string name);

    ///Stop monitor with specified name.
    void stop_monitor(string name);

    ///Access monitor with specified name. Should return const in D2.
    SubMonitor get_monitor(string name);
}


//needs better naming
///MonitorData implementation providing access to submonitors of monitorable of specified type.
final class MonitorManager(M) : MonitorData
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

        void die()
        {
            foreach(monitor; monitors_){monitor.die();}
            monitors_ = null;
            constructors_ = null;
        }

        string[] monitor_names(){return constructors_.keys;}

        void start_monitor(string name)
        {
            monitors_[name] = constructors_[name](monitored_);
        }

        void stop_monitor(string name)
        in
        {
            assert(monitors_.keys.contains(name), 
                   "Trying to stop a monitor that is not running");
        }
        body
        {
            monitors_[name].die();
            monitors_.remove(name);
        }

        SubMonitor get_monitor(string name)
        in
        {
            assert(monitors_.keys.contains(name), "Trying to access a nonexistent monitor");
        }
        body
        {
            return monitors_[name];
        }
}
