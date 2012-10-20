
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Base class for widget layoyts.
module gui2.layout;


import gui2.widget;
import math.rect;

/// Manages layout of a widget and its children.
/// 
/// When a widget is resized, its children need to be resized and repositioned 
/// accordingly. Implementations of Layout handle this in various ways.
abstract class Layout
{
protected:
    // Extents of the widget.
    Recti bounds_;

public:
    /// Minimize a widget's layout, determining its minimal bounds.
    ///
    /// minimize() is called for all widget layouts before expand().
    /// 
    /// Called for deepest children first, then for their parents, etc, until
    /// the root is reached. Children are already minimized when minimize() is 
    /// called.
    void minimize(Widget[] children);

    /// Expand a widget's layout, determining definitive sizes and positions of its children.
    /// 
    /// First called for root, then its children, etc; the parent 
    /// is already expanded when expand() is called.
    void expand(Widget parent);

    /// Get the bounds of the layout (rectangle of the widget) in screen space.
    @property ref const(Recti) bounds() const pure nothrow {return bounds_;}

protected:
    /// Allows layouts to access layouts of passed widgets.
    static Layout getLayout(Widget widget)
    {
        return widget.layout;
    }
}
