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
import ice.guiswapper;
import util.yaml;


/// Credits dialog.
class Credits: SwappableGUI
{
    private:
        // Credits text.
        static immutable credits_ = 
            "TODO\n";

        // Root widget of the credits GUI.
        RootWidget creditsGUI_;

    public:
        /// Construct a Credits dialog.
        /// 
        /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
        ///         gameDir    = Game data directory.
        ///
        /// Throws: YAMLException on a YAML parsing error.
        ///         VFSException on a filesystem error.
        this(GUISystem guiSystem, VFSDir gameDir)
        {
            auto creditsGUIFile = gameDir.dir("gui").file("creditsGUI.yaml");
            creditsGUI_ = guiSystem.loadWidgetTree(loadYAML(creditsGUIFile));
            super(creditsGUI_);
            creditsGUI_.close!ButtonWidget.connect({swapGUI_("ice");});
        }
}
