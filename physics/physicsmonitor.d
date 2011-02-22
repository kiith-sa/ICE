
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

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


///Statistics data sent by PhysicsEngine to physics monitors.
package struct Statistics
{
    ///Physics bodies at the moment.
    uint bodies = 0;
    ///Physics bodies with collision volumes at the moment.
    uint col_bodies = 0;
    ///Contact tests this frame.
    uint tests;
    ///Contacts detected this frame.
    uint contacts;
    ///Penetration resolution iterations this frame.
    uint penetration;
    ///Collision response iterations this frame.
    uint response;

    ///Reset the statistics gathered for the next frame.
    void zero(){tests = contacts = penetration = response = 0;}
}

///Graph showing values related to fine collision detection.
alias SimpleGraphMonitor!(PhysicsEngine, Statistics, 
                          "contacts", "penetration", "response") ContactMonitor;

///Graph showing values related to coarse collision detection.
alias SimpleGraphMonitor!(PhysicsEngine, Statistics, "tests") CoarseContactMonitor;

///Graph showing statistics about physics bodies.
alias SimpleGraphMonitor!(PhysicsEngine, Statistics, "bodies", "col_bodies") BodiesMonitor;

///PhysicsEngineMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("PhysicsEngine", 
                            ["Bodies", "Contacts", "Coarse"], 
                            ["BodiesMonitor", "ContactMonitor", "CoarseContactMonitor"]));
