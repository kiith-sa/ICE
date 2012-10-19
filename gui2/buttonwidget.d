
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Simple clickable button widget.
module gui2.buttonwidget;


import gui2.widget;
import gui2.widgetutils;
import util.signal;
import util.yaml;


/// Simple clickable button widget.
class ButtonWidget: Widget
{
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
        text_ = parseProperty!(string, "text", typeof(this))(yaml);
        super(yaml);
    }

    /// Get button text.
    @property string text() const pure nothrow {return text_;}

    /// Set button text.
    @property void text(string rhs) pure nothrow {text_ = rhs;}
}
