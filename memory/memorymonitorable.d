
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module memory.memorymonitorable;


import memory.memory;
import monitor.monitormenu;
import monitor.monitorable;
import memory.memorymonitor;
import util.weaksingleton;
import util.signal;


//Ugly, but must be here due to circular dependencies.
///Used for monitoring manually allocated memory. 
final class MemoryMonitorable : Monitorable
{
    mixin WeakSingleton;
    private:
        //Statistics data for monitoring.
        Statistics statistics_;
    package:
        //Used to send statistics data to memory monitors.
        mixin Signal!(Statistics) send_statistics;
    public:
        ///Construct Memory.
        this(){singleton_ctor();}

        ///Destroy this Memory.
        void die(){singleton_dtor();}

        ///Update and send monitoring data to monitor.
        void update()
        {
            statistics_.manual_MiB = currently_allocated / (1024.0 * 1024.0);
            send_statistics.emit(statistics_);
        }

        MonitorMenu monitor_menu(){return new MemoryMonitorableMonitor(this);}
}
