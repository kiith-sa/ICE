
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides visual representation on the screen for an entity.
module component.visualcomponent;


import color;
import containers.lazyarray;
import math.vector2;
import util.yaml;


/**
 * Component that provides visual representation on the screen for an entity.
 *
 * VisualComponent only has a name of a graphics resource, which is lazily 
 * loaded by VisualSystem.
 */
struct VisualComponent
{
    ///Index to visual data in a lazy array in VisualSystem.
    LazyArrayIndex dataIndex;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        dataIndex = LazyArrayIndex(yaml.as!string);
    }

    ///Construct manually.
    this(string resourceName) pure nothrow
    {
        dataIndex = LazyArrayIndex(resourceName);
    }
}

