
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module gui2.widget;


import util.yaml;


/// Base class for all widgets.
abstract class Widget
{
public:
    /// Construct a Widget. Contains setup code shared between widget types.
    ///
    /// Params: yaml = YAML definition of the widget.
    this(ref YAMLNode yaml)
    {
        assert(false, "TODO");
    }
}
