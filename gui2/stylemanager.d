
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module gui2.stylemanager;


import math.rect;
import math.vector2;
import util.resourcemanager;
import video.texture;
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
protected:
    /// Reference to the texture manager.
    ///
    /// Textures might be unloaded if the video driver is replaced,
    /// so they should always be accessed through this manager.
    ResourceManager!Texture textureManager_;

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

    /// Draw a progress "bar".
    ///
    /// Different styles might draw progress differently (horizontal or vertical
    /// bar, circle, cake, etc).
    ///
    /// Params:  video    = VideoDriver to draw with.
    ///          progress = Progress between 0 and 1.
    ///          area     = Area taken by the progress "bar".
    void drawProgress(VideoDriver video, const float progress, ref const Recti area);

    /// Draw text using the style.
    ///
    /// Only bounds of the widget are specified; the style decides font, alignment,
    /// and other parameters of the text.
    ///
    /// Params: video = VideoDriver to draw with.
    ///         text  = Text to draw.
    ///         area  = Area taken up by the widget.
    void drawText(VideoDriver video, const string text, ref const Recti area);

package:
    // Set the texture manager to load textures with.
    @property void textureManager(ResourceManager!Texture rhs) pure nothrow 
    {
        textureManager_ = rhs;
    }
}
