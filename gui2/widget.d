
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Base class for all widgets.
module gui2.widget;


import gui2.exceptions;
import gui2.layout;
import util.yaml;



/// Base class for all widgets.
abstract class Widget
{
private:
    /// Layout of the widget - determines widget size and position.
    Layout layout_;

public:
    /// Construct a Widget. Contains setup code shared between widget types.
    ///
    /// Params: yaml = YAML definition of the widget.
    ///
    /// Throws: WidgetInitException on failure.
    this(ref YAMLNode yaml)
    {
        assert(false, "TODO");
    }

package:
    /// Get widget layout - used by other widgets' layouts.
    @property Layout layout() pure nothrow {return layout_;}
}
