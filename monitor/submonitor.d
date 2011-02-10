module monitor.submonitor;


import gui.guielement;


///Base class for all submonitors used by Monitor.
abstract class SubMonitor : GUIElement
{
    public:
        this()
        {
            super(GUIElementParams("p_left + 4", "p_top + 22", 
                                   "p_width - 8", "p_height - 26",
                                   true));
        }
}

