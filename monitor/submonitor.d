module monitor.submonitor;


import gui.guielement;


///Base class for all submonitors used by Monitor.
abstract class SubMonitor : GUIElement
{
    public:
        this()
        {
            super("p_left + 4", "p_top + 22", 
                  "p_right - p_left - 8", "p_bottom - p_top - 26");
        }
}

