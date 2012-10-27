
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Fixed layout that never changes.
module gui2.fixedlayout;


import gui2.layout;
import gui2.widget;
import gui2.widgetutils;
import math.rect;
import math.vector2;
import util.yaml;


/// Fixed layout - bounds of the widget are set from the start and don't change.
///
/// Useful for e.g. the root widget.
class FixedLayout: Layout
{
public:
    /// Construct a FixedLayout from YAML.
    this(ref YAMLNode yaml)
    {
        bounds_.min = Vector2i(layoutInitProperty!int(yaml, "x"),
                               layoutInitProperty!int(yaml, "y"));
        bounds_.max = bounds_.min +
                      Vector2i(layoutInitProperty!int(yaml, "w"),
                               layoutInitProperty!int(yaml, "h"));
    }

    override void minimize(Widget[] children){};
    override void expand(Widget parent){};

package:
    /// Manually set size of the layout.
    ///
    /// This is used _only_ by GUISystem for layout of the root widget.
    ///
    /// Params: width  = New layout width.
    ///         height = New layout height.
    void setSize(const uint width, const uint height)
    {
        bounds_.max = bounds_.min + Vector2i(cast(int)width, cast(int)height);
    }
}
