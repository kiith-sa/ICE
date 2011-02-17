
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module memory.memorymonitor;


import memory.memorymonitorable;
import monitor.monitormenu;
import monitor.graphmonitor;
import gui.guimenu;
import gui.guilinegraph;
import graphdata;
import color;


///Statistics passed by MemoryMonitorable to memory monitors.
package struct Statistics
{
    ///Total manually allocated memory at the moment, in MiB.
    real manual_MiB;
}

///Graph showing statistics about memory usage.
final package class UsageMonitor : GraphMonitor
{
    public:
        ///Construct a UsageMonitor.
        this(MemoryMonitorable monitored)
        {
            mixin(generate_graph_monitor_ctor("manual_MiB"));
        }

    private:
        ///Callback called by Memory once per update to update monitored statistics.
        mixin(generate_graph_fetch_statistics("manual_MiB"));
}

///MemoryMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("MemoryMonitorable", 
                            ["Usage"], 
                            ["UsageMonitor"]));
