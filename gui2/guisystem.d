
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// The main GUI class.
module gui2.guisystem;

import gui2.event;
import gui2.rootwidget;
import gui2.slotwidget;
import math.vector2;
import util.yaml;
import video.videodriver;


/// The main GUI class. Manages widgets, emits events, etc.
class GUISystem
{
    /// The root of the widget tree.
    SlotWidget rootSlot_;

public:
    /// Construct the GUISystem.
    ///
    /// Params: width  = Window width.
    ///         height = Window height.
    this(uint width, uint height)
    {
        rootSlot_ = new SlotWidget(YAMLNode(["x", "y", "w", "h"],
                                            [0, 0, width, height]), this);
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

    /// Render the GUI.
    void render(VideoDriver video)
    {
        static RenderEvent renderEvent;
        if(null is renderEvent){renderEvent = new RenderEvent();}

        // Save view zoom and offset.
        const zoom   = video.zoom;
        const offset = video.viewOffset; 

        // Set no zoom and zero offset for GUI drawing.
        video.zoom       = 1.0;
        video.viewOffset = Vector2d(0.0, 0.0);

        renderEvent.videoDriver = video;
        rootSlot_.handleEvent(renderEvent);

        // Restore zoom and offset.
        video.zoom       = zoom;
        video.viewOffset = offset;
    }

package:
    /// Update layout of all widgets (e.g. after a new RootWidget is connected).
    void updateLayout()
    {
        // Reusing the same instances every time to avoid unnecessary allocation.
        static MinimizeEvent minimizeEvent;
        static ExpandEvent expandEvent;
        if(null is minimizeEvent){minimizeEvent = new MinimizeEvent();}
        if(null is expandEvent)  {expandEvent   = new ExpandEvent();}
        rootSlot_.handleEvent(minimizeEvent);
        rootSlot_.handleEvent(expandEvent);
    }
}
