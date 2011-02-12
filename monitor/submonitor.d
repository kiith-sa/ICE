
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

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

