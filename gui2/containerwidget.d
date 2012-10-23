
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// A simple container widget.
module gui2.containerwidget;


import gui2.guisystem;
import gui2.widget;
import util.yaml;

/// A simple container widget.
///
/// Currently, this has no functionality - it's only used to group/lay out 
/// child widgets.
class ContainerWidget: Widget
{
    /// Construct a ContainerWidget from YAML.
    ///
    /// Never call directly.
    this(ref YAMLNode yaml)
    {
        super(yaml);
    }
}
