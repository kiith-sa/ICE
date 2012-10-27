
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module gui2.stylemanager;


import math.rect;
import math.vector2;
import video.videodriver;

/// Horizontal alignments.
enum AlignX
{
    /// Align to the left.
    Left,
    /// Align to center.
    Center,
    /// Align to the right.
    Right
}

/// Vertical alignments.
enum AlignY
{
    /// Align to top.
    Top,
    /// Align to center.
    Center,
    /// Align to bottom.
    Bottom
}

/// Base class for style managers.
///
/// A style manager manages styles of a widget (e.g. default, mouseOver, etc.).
///
/// Each StyleManager implementation implements its own drawing logic and
/// supports different kinds of styles.
abstract class StyleManager
{
public:
    /// Set style with specified name.
    ///
    /// Params: name = Name of style to set. If there is no style with specified 
    ///                name, the default style is set.
    ///                "" (empty string) is the name of the default style.
    void setStyle(string name);

    /// Draw the widget rectangle; both its background and border.
    ///
    /// Params: video = VideoDriver to draw with.
    ///         area  = Area taken by the widget in screen space.
    void drawWidgetRectangle(VideoDriver video, ref const Recti area);

    /// Draw text using the style.
    ///
    /// Params: video    = VideoDriver to draw with.
    ///         text     = Text to draw.
    ///         position = Position to draw the text at.
    void drawText(VideoDriver video, const string text, const Vector2i position);

    /// Draw text aligned within an area.
    ///
    /// Params: video  = VideoDriver to draw with.
    ///         text   = Text to draw.
    ///         area   = Area in which to align the text.
    ///         alignX = X alignment of the text.
    ///         alignY = Y alignment of the text.
    ///
    /// This is just a convenience function for simple, single-line text drawing.
    /// More advanced text drawing (e.g. a page) should be implemented in a 
    /// separate TextRenderer class or struct, wrapping a StyleManager.
    /// That class should be in this module for direct access to protected 
    /// functions.
    void drawTextAligned(VideoDriver video, const string text, ref const Recti area,
                         const AlignX alignX, const AlignY alignY)
    {
        const size = getTextSize(video, text);

        Vector2i offset;

        const min = area.min;
        const max = area.max;
        final switch(alignX)
        {
            case AlignX.Left:   offset.x = area.min.x; break;
            case AlignX.Center: offset.x = area.min.x + (area.width - size.x) / 2; break;
            case AlignX.Right:  offset.x = area.max.x - size.x; break;
        }
        final switch(alignY)
        {
            case AlignY.Top:    offset.y = area.min.y; break;
            case AlignY.Center: offset.y = area.min.y + (area.height - size.y) / 2; break;
            case AlignY.Bottom: offset.y = area.max.y - size.y; break;
        }

        drawText(video, text, offset);
    }

    /// Draw text centered in an area.
    ///
    /// Convenience function callind drawTextAligned with both horizontal and
    /// vertical alignment set to center.
    ///
    /// SeeAlso: drawTextAligned
    final void drawTextCentered(VideoDriver video, const string text, ref const Recti area)
    {
        drawTextAligned(video, text, area, AlignX.Center, AlignY.Center);
    }

protected:
    /// Get the size of specified text when drawn on the screen.
    Vector2u getTextSize(VideoDriver video, const string text);
}
