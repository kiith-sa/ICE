
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Simple clickable button widget.
module gui2.buttonwidget;


import std.typecons;

import gui2.event;
import gui2.guisystem;
import gui2.labelwidget;
import gui2.layout;
import gui2.stylemanager;
import gui2.widget;
import gui2.widgetutils;
import math.vector2;
import platform.key;
import util.signal;
import util.yaml;
import video.videodriver;


/// Simple clickable button widget.
class ButtonWidget: LabelWidget
{
public:
    /// Emitted when this button is pressed.
    mixin Signal!() pressed;

    /// Load a ButtonWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        super(yaml);
        focusable_ = true;
        addEventHandler!MouseKeyEvent(&detectActive);
    }

protected:
    override void gotFocus()
    {
        styleManager_.setStyle("focused");
    }

    override void lostFocus()
    {
        styleManager_.setStyle("");
    }

    override void clicked(const Vector2u position, const MouseKey key)
    {
        if(key == MouseKey.Left)
        {
            pressed.emit();
        }
    }

private:
    /// Event handler that detects whether the button is active (mouse pressed above it).
    Flag!"DoneSinking" detectActive(MouseKeyEvent event)
    {
        if(event.status == Event.Status.Sinking && 
           guiSystem_.focusedWidget is this)
        {
            if(event.state == KeyState.Pressed)
            {
                styleManager_.setStyle("active");
            }
            else if(event.state == KeyState.Released)
            {
                // Widget is focused - we test that above 
                // (if it wasn't focused, style would be 
                // already changed back to default in lostFocus())
                styleManager_.setStyle("focused");
            }
        }
        return No.DoneSinking;
    }
}
