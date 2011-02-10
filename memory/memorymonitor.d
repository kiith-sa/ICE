module memory.memorymonitor;


import memory.memory;
import gui.guilinegraph;
import gui.guimenu;
import monitor.graphmonitor;
import monitor.monitormenu;
import graphdata;
import color;


//Statistics passed by Memory to memory monitors.
package struct Statistics
{
    //Total manually allocated memory at the moment, in MiB.
    real manual_MiB;
}

//Graph showing statistics about memory usage.
final package class UsageMonitor : GraphMonitor
{
    public:
        //Construct a UsageMonitor.
        this(Memory monitored)
        {
            mixin(generate_graph_monitor_ctor("manual_MiB"));
        }

    private:
        //Callback called by Memory once per update to update monitored statistics.
        mixin(generate_graph_fetch_statistics("manual_MiB"));
}

//MemoryMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("Memory", 
                            ["Usage"], 
                            ["UsageMonitor"]));
