
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides visual representation on the screen for an entity.
module component.visualcomponent;


import std.container;

import color;
import containers.fixedarray;
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
    /// Index pointing to visual data.
    alias LazyArrayIndex!(VisualData) VisualIndex;

    /// Index to visual data in a lazy array in VisualSystem.
    VisualIndex dataIndex;

    /// Is placeholder visual data being used? (Did loading fail?)
    bool placeholder;

    /// Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        dataIndex = VisualIndex(yaml.as!string);
    }

    /// Construct manually.
    this(string resourceName) pure nothrow
    {
        dataIndex = VisualIndex(resourceName);
    }
}

package:

///Visual data referenced by a VisualComponent.
struct VisualData
{
    ///Type of visual data used.
    enum Type 
    {
        Lines
    }
    Type type = Type.Lines;

    /// Vertex with a position and a color. 
    /// 
    /// Used for line start/end.
    struct ColoredVertex
    {
        /// Position of the vertex.
        Vector2f position;
        /// Color of the vertex.
        Color color;

        /// Construct a ColoredVertex.
        this(const Vector2f position, const Color color) @safe pure nothrow
        {
            this.position = position;
            this.color = color;
        }
    }
    union
    {
        ///Visual data stored for the Lines type.
        struct
        {
            ///TODO As soon as custom allocators are supported, we should use one 
            ///here to track memory usage. It's not certain that RAII works in
            ///all cases and there might be leaks.

            ///Vertices (in pairs).
            Array!ColoredVertex vertices;
            ///Line widths (each for a pair of vertices)
            Array!float widths;
        }
    }
}
