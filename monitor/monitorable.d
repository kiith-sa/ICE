
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module monitor.monitorable;


import monitor.monitormenu;


///Classes implementing this interface are monitorable by the monitor.
interface Monitorable
{
    ///Return monitor menu of the monitorable class.
    MonitorMenu monitor_menu();
}
