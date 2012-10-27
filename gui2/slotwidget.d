
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// A widget acting as a pluggable slot in a widget tree.
module gui2.slotwidget;


import gui2.guisystem;
import gui2.widget;
import gui2.rootwidget;
import util.yaml;


/// A widget that can contain a RootWidget.
///
/// A SlotWidget is a slot in the widget tree where different 
/// widget trees might be inserted.
class SlotWidget : Widget
{
private:
    /// Connected widget, if any.
    RootWidget connectedWidget_;

public:
    /// Load a SlotWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        super(yaml);
    }

    /// Is the SlotWidget free (i.e. no RootWidget is connected) ?
    @property bool free() const pure nothrow {return connectedWidget_ is null;}

    /// Connect a RootWidget.
    void connect(RootWidget child)
    {
        assert(connectedWidget_ is null, "There is already a connected RootWidget");
        connectedWidget_ = child;
        addChild(child);
        guiSystem_.updateLayout();
        // Must be done after updating the layout so we get correct widget bounds.
        connectedWidget_.checkMouseEnteredTree();
    }

    /// Disconnect a RootWidget. The RootWidget passed must be the connected RootWidget.
    void disconnect(RootWidget child)
    {
        assert(connectedWidget_ is child, "The widget to disconnect does not match");
        connectedWidget_.mouseLeftTree();
        removeChild(connectedWidget_);
        connectedWidget_ = null;
        guiSystem_.updateLayout();
    }
}
