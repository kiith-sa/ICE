
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Simple static label widget.
module gui2.labelwidget;


import std.typecons;

import gui2.event;
import gui2.guisystem;
import gui2.layout;
import gui2.stylemanager;
import gui2.widget;
import gui2.widgetutils;
import math.vector2;
import platform.key;
import util.signal;
import util.yaml;
import video.videodriver;


/// Simple label widget.
class LabelWidget: Widget
{
private:
    /// Label text.
    string text_;

public:
    /// Load a LabelWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        text_ = widgetInitProperty!string(yaml, "text");
        focusable_ = false;
        super(yaml);
    }

    override void render(VideoDriver video)
    {
        super.render(video);
        styleManager_.drawTextCentered(video, text_, layout_.bounds);
    }

    /// Get label text.
    @property string text() const pure nothrow {return text_;}

    /// Set label text.
    @property void text(string rhs) pure nothrow {text_ = rhs;}
}
