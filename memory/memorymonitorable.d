
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitorable used to view memory.
module memory.memorymonitorable;
@safe


import memory.memory;
import monitor.monitordata;
import monitor.submonitor;
import monitor.graphmonitor;
import monitor.monitorable;
import util.weaksingleton;
import util.signal;


/**
 * Used for monitoring manually allocated memory. 
 * 
 * Signal:
 *     package mixin Signal!(Statistics) send_statistics
 *
 *     Used to send statistics data to memory monitors.
 */
final class MemoryMonitorable : Monitorable
{
    mixin WeakSingleton;
    private:
        ///Monitoring data.
        Statistics statistics_;

    package:
        ///Used to send statistics data to memory monitors.
        mixin Signal!(Statistics) send_statistics;

    public:
        ///Construct a MemoryMonitorable.
        this(){singleton_ctor();}

        ///Destroy this MemoryMonitorable.
        ~this()
        {
            singleton_dtor();
            send_statistics.disconnect_all();
        }

        ///Update and send monitoring data to monitor.
        void update()
        {
            statistics_.manual_MiB = currently_allocated / (1024.0 * 1024.0);
            send_statistics.emit(statistics_);
        }

        MonitorDataInterface monitor_data()
        {
            SubMonitor function(MemoryMonitorable)[string] ctors_;
            ctors_["Usage"] = &new_graph_monitor!(MemoryMonitorable, Statistics, "manual_MiB");
            return new MonitorData!(MemoryMonitorable)(this, ctors_);
        }
}

///Statistics passed by MemoryMonitorable to memory monitors.
package struct Statistics
{
    ///Total manually allocated memory at the moment, in MiB.
    real manual_MiB;
}
