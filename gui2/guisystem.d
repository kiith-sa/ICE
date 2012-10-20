
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// The main GUI class.
module gui2.guisystem;

import gui2.rootwidget;
import gui2.slotwidget;
import util.yaml;


//XXX ROOTSLOT WIDGET SHOULD HAVE FIXED LAYOUT
/// The main GUI class. Manages widgets, emits events, etc.
class GUISystem
{
    /// The root of the widget tree.
    SlotWidget rootSlot_;

public:
    /// Construct the GUISystem.
    this()
    {
        rootSlot_ = new SlotWidget(YAMLNode(), this);
    }

    /// Load a widget tree connectable to a SlotWidget from YAML.
    RootWidget loadWidgetTree(YAMLNode source)
    {
        assert(false, "TODO");
    }

    /// Get the root SlotWidget.
    @property SlotWidget rootSlot()
    {
        return rootSlot_;
    }
}
