//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Swaps GUI subtrees connected to a single SlotWidget.
module ice.guiswapper;


import gui2.rootwidget; 
import gui2.slotwidget; 

/// Swaps GUI subtrees connected to a single SlotWidget.
///
/// Used to organize the ICE main menu.
class GUISwapper
{
private:
    /// Slot widget to which the subtrees are being connected.
    SlotWidget parentSlot_;

    /// GUI subtrees indexed by name.
    SwappableGUI[string] guiByName_;

    /// Root widget of the currently connected subtree (null if none).
    RootWidget currentRoot;

public:
    /// Construct a GUISwapper connecting GUI subtrees to specified SlotWidget.
    this(SlotWidget parentSlot)
    {
        parentSlot_ = parentSlot;
    }

    /// Add a swappable GUI with specified name.
    void addGUI(SwappableGUI gui, const string name)
    {
        assert((name in guiByName_) is null,
               "There is already a swappable GUI with name " ~ name);
        void swapGUI(string swapName)
        {
            parentSlot_.disconnect(gui.rootWidget_);
            if(swapName is null){return;}
            setGUI(swapName);
        }
        gui.swapGUI_ = &swapGUI;
        guiByName_[name] = gui;
    }

    /// Forcibly connect GUI with specified name.
    ///
    /// Can only be used when no GUI is connected, or to disconnect(null) a
    /// connected GUI.
    void setGUI(string name)
    {
        if(name is null)
        {
            if(currentRoot !is null)
            {
                parentSlot_.disconnect(currentRoot);
            }
            currentRoot = null;
            return;
        }
        auto replacement = name in guiByName_;
        assert(replacement !is null, "There is no swappable GUI with name " ~ name);
        currentRoot = replacement.rootWidget_;
        parentSlot_.connect(replacement.rootWidget_);
    }
}

/// Parent class for swappable GUI subtrees.
abstract class SwappableGUI
{
private:
    /// Root widget of the subtree.
    RootWidget rootWidget_;

protected:
    /// Swaps this GUI (connected at call) with GUI specified by a name string.
    void delegate(string) swapGUI_;

public:
    /// Initialize a SwappableGUI with a root widget.
    this(RootWidget rootWidget)
    {
        void dummy(string){}
        swapGUI_ = &dummy;
        rootWidget_ = rootWidget;
    }
}
