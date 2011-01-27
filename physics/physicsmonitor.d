module physics.physicsmonitor;

import physics.physicsengine;
import gui.guielement;
import gui.guimenu;
import gui.guilinegraph;
import graphdata;
import monitor.monitor;
import monitor.monitormenu;
import monitor.graphmonitor;
import color;


///Used to gather statistics data to be sent by PhysicsEngine to physics monitors.
package struct Statistics
{
    //Physics bodies at the moment.
    uint bodies = 0;
    //Physics bodies with collision volumes at the moment.
    uint col_bodies = 0;
    //Contract tests this frame.
    uint tests;
    //Contacts detected this frame.
    uint contacts;
    //Penetration resolution iterations this frame.
    uint penetration;
    //Collision response iterations this frame.
    uint response;

    //Reset the statistics gathered for the next frame.
    void zero(){tests = contacts = penetration = response = 0;}
}

///Graph showing values related to fine collision detection.
final package class ContactMonitor : GraphMonitor
{
    public:
        ///Construct a ContactMonitor.
        this(PhysicsEngine monitored)
        {
            mixin(generate_graph_monitor_ctor("contacts", "penetration", "response"));
        }

    private:
        //Callback called by PhysicsMonitor once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("contacts", "penetration", "response"));
}

///Graph showing values related to coarse collision detection.
final package class CoarseContactMonitor : GraphMonitor
{
    public:
        ///Construct a CoarseContactMonitor.
        this(PhysicsEngine monitored){mixin(generate_graph_monitor_ctor("tests"));}

    private:
        //Callback called by PhysicsMonitor once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("tests"));
}

///Graph showing statistics about physics bodies.
final package class BodiesMonitor : GraphMonitor
{
    public:
        ///Construct a BodiesMonitor.
        this(PhysicsEngine monitored)
        {
            mixin(generate_graph_monitor_ctor("bodies", "col_bodies"));
        }

    private:
        //Callback called by PhysicsMonitor once per frame to update monitored statistics.
        mixin(generate_graph_fetch_statistics("bodies", "col_bodies"));
}

///PhysicsEngineMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("PhysicsEngine", 
                            ["Bodies", "Contacts", "Coarse"], 
                            ["BodiesMonitor", "ContactMonitor", "CoarseContactMonitor"]));
