
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module gui2.stylemanager;


import math.rect;
import math.vector2;
import video.videodriver;

/// Base class for style managers.
///
/// A style manager manages styles of a widget (e.g. default, mouseOver, etc.).
///
/// Each StyleManager implementation implements its own drawing logic and
/// supports different kinds of styles.
///
/// Each StyleManager must define a "Style" struct with a constructor taking 
/// a YAML mapping with style parameters and a string - style name. Keeping
/// this struct separate will allow styles to be switched.
abstract class StyleManager
{
public:
    /// Draw the widget rectangle; both its background and border.
    ///
    /// Params: video = VideoDriver to draw with.
    ///         area  = Area taken by the widget in screen space.
    void drawWidgetRectangle(VideoDriver video, ref const Recti area);

    /// Draw text using the style.
    ///
    /// Params: driver   = VideoDriver to draw with.
    ///         text     = Text to draw.
    ///         position = Position to draw the text at.
    void drawText(VideoDriver driver, const string text, const Vector2i position);
}
