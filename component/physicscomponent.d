
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component providing physics support to an entity.
module component.physicscomponent;


import math.vector2;
import util.yaml;


///Component providing physics support to an entity.
align(4) struct PhysicsComponent
{
    ///Position in world space.
    Vector2f position;

    //default rotation facing down (Vector2f(0.0, 1.0).angle() - can't be used in CTFE)
    ///Rotation in world space, in radians.
    float rotation = 0.0f;

    ///Velocity in world space.
    Vector2f velocity;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode node)
    {
        position = fromYAML!Vector2f(node["position"], "position");
        rotation = fromYAML!float   (node["rotation"], "rotation");
        velocity = fromYAML!Vector2f(node["velocity"], "velocity");
    }

    ///Construct manually.
    this(Vector2f pos, float rot, Vector2f velocity)
    {
        position      = pos;
        rotation      = rot;
        this.velocity = velocity;
    }
}


