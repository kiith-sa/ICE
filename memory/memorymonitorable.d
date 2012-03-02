
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitorable used to view memory.
module memory.memorymonitorable;


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
 *     package mixin Signal!(Statistics) sendStatistics
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
        mixin Signal!Statistics sendStatistics;

    public:
        ///Construct a MemoryMonitorable.
        this(){singletonCtor();}

        ///Destroy this MemoryMonitorable.
        ~this()
        {
            singletonDtor();
            sendStatistics.disconnectAll();
        }

        ///Update and send monitoring data to monitor.
        void update()
        {
            statistics_.manualMiB = currentlyAllocated / (1024.0 * 1024.0);
            sendStatistics.emit(statistics_);
        }

        MonitorDataInterface monitorData()
        {
            SubMonitor function(MemoryMonitorable)[string] ctors_;
            ctors_["Usage"] = &newGraphMonitor!(MemoryMonitorable, Statistics, "manualMiB");
            return new MonitorData!MemoryMonitorable(this, ctors_);
        }
}

///Statistics passed by MemoryMonitorable to memory monitors.
package struct Statistics
{
    ///Total manually allocated memory at the moment, in MiB.
    real manualMiB;
}
