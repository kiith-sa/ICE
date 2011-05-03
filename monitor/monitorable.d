
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module monitor.monitorable;
@safe


import monitor.monitordata;


///Interace used by classes that can be monitored by the monitor subsystem.
interface Monitorable
{
    ///Get MonitorData to access submonitors of the monitorable.
    MonitorDataInterface monitor_data();
}
