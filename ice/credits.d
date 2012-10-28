//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Credits dialog.
module ice.credits;


import dgamevfs._;

import gui2.buttonwidget;
import gui2.guisystem;
import gui2.rootwidget;
import gui2.slotwidget;
import platform.platform;
import util.signal;
import util.yaml;


/// Credits dialog.
/// 
/// Signal:
///     public mixin Signal!() closed
/// 
///     Emitted when this credits dialog is closed.
/// 
class Credits
{
    private:
        // Credits text.
        static immutable credits_ = 
            "TODO\n";

        // Parent slot widget the credits GUI is connected to.
        SlotWidget parentSlot_;

        // Root widget of the credits GUI.
        RootWidget creditsGUI_;

    public:
        /// Emitted when this credits dialog is closed.
        mixin Signal!() closed;

        /// Construct a Credits dialog.
        /// 
        /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
        ///         parentSlot = Parent slot widget to connect the credits dialog to.
        ///         gameDir    = Game data directoru.
        this(GUISystem guiSystem, SlotWidget parentSlot, VFSDir gameDir)
        {
            parentSlot_ = parentSlot;
            auto creditsGUIFile = gameDir.dir("gui").file("creditsGUI.yaml");
            creditsGUI_ = guiSystem.loadWidgetTree(loadYAML(creditsGUIFile));
            creditsGUI_.close!ButtonWidget.connect(&closed.emit);
        }

        // Show the credits dialog. Any RootWidget connected to parent slot must be disconnected first.
        void show()
        {
            parentSlot_.connect(creditsGUI_);
        }

        // Hide the credits dialog.
        void hide()
        {
            parentSlot_.disconnect(creditsGUI_);
        }
}
