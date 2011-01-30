module monitor.monitorable;


import monitor.monitormenu;


///Classes implementing this interface are monitorable by the monitor.
interface Monitorable
{
    ///Return monitor menu of the monitorable class.
    MonitorMenu monitor_menu();
}
