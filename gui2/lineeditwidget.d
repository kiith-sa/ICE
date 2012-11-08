
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// One-line text editor widget.
module gui2.lineeditwidget;


import std.algorithm;
import std.array;
import std.uni;

import gui2.event;
import gui2.widget;
import gui2.widgetutils;
import math.vector2;
import platform.key;
import util.signal;
import util.yaml;
import video.videodriver;

/// One-line text editor widget.
class LineEditWidget: Widget
{
private:
    /// Entered text.
    string text_;

    /// Maximum number of characters that can be entered.
    uint maxCharacters_;

    /// Determines whether an entered character should be added to the text.
    bool delegate(dchar) characterFilter_;

public:
    /// Emitted when the user presses Enter.
    mixin Signal!(string) textEntered;

    /// Load a LineEditWidget from YAML.
    ///
    /// Do not call directly.
    this(ref YAMLNode yaml)
    {
        bool defaultFilter(dchar c)
        {
            return isGraphical(c);
        }
        characterFilter_ = &defaultFilter;
        maxCharacters_   = widgetInitPropertyOpt(yaml, "maxCharacters", 16);
        focusable_ = true;
        super(yaml);
    }

    /// Render the widget with specified video driver.
    override void render(VideoDriver video)
    {
        super.render(video);
        styleManager_.drawTextCentered(video, text_ ~ '_', layout_.bounds);
    }

    /// Get entered text.
    @property string text() const pure nothrow {return text_;}

    /// Set the function to determine whether an entered character should be added to the text.
    @property void characterFilter(bool delegate(dchar) rhs) pure nothrow 
    {
        characterFilter_ = rhs;
    }

    /// Set the maximum number of characters that can be entered.
    @property void maxCharacters(const uint chars) pure nothrow 
    {
        maxCharacters_ = chars;
        text_ = text_[0 .. min(text_.length, chars)];
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

    override void keyPressed(const Key key, const dchar unicode) 
    {
        if(key == Key.Return)
        {
            // Send the entered text and clear it.
            auto output = text_;
            text_ = "";
            textEntered.emit(output);
        }
        else if(key == Key.Backspace)
        {
            text_ = text_.empty ? text_ : text_[0 .. $ - 1];
        }
        else if(characterFilter_(unicode) && text_.length < maxCharacters_)
        {
            text_ ~= unicode;
        }
    }
}
