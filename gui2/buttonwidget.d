
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Simple clickable button widget.
module gui2.buttonwidget;


import gui2.guisystem;
import gui2.layout;
import gui2.stylemanager;
import gui2.widget;
import gui2.widgetutils;
import util.signal;
import util.yaml;
import video.videodriver;


/// Simple clickable button widget.
class ButtonWidget: Widget
{
private:
    /// Button text.
    string text_;

public:
    /// Emitted when this button is pressed.
    mixin Signal!() pressed;

    /// Load a ButtonWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        text_ = widgetInitProperty!string(yaml, "text");
        focusable_ = true;
        super(yaml);
    }

    /// Render the widget with specified video driver.
    override void render(VideoDriver video)
    {
        super.render(video);
        styleManager_.drawTextCentered(video, text_, layout_.bounds);
    }

    /// Get button text.
    @property string text() const pure nothrow {return text_;}

    /// Set button text.
    @property void text(string rhs) pure nothrow {text_ = rhs;}
}
