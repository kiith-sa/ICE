
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component providing physics support to an entity.
module component.physicscomponent;


import std.exception;

import math.vector2;
import util.yaml;


///Component providing physics support to an entity.
struct PhysicsComponent
{
    ///Position in world space.
    Vector2f position;

    //default rotation facing down (Vector2f(0.0, 1.0).angle() - can't be used in CTFE)
    ///Rotation in world space, in radians.
    float rotation = 0.0f;

    ///Velocity in world space.
    Vector2f velocity;

    /**
     * If true, position will be set in absolute coordinates after spawning
     * (instead of relative to the spawner).
     */
    bool spawnAbsolutePosition = false;

    /**
     * If true, rotation will be set in absolute angle after spawning
     * (instead of relative to the spawner).
     */
    bool spawnAbsoluteRotation = false;

    /**
     * If true, velocity will be set in absolute coordinates after spawning
     * (instead of relative to the spawner).
     */
    bool spawnAbsoluteVelocity = false;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode node)
    {
        position = node.containsKey("position") 
                 ? fromYAML!Vector2f(node["position"], "position")
                 : Vector2f(0.0f, 0.0f);
        rotation = node.containsKey("rotation") 
                 ? fromYAML!float(node["rotation"], "rotation")
                 : 0.0f;
        const hasVelocity = node.containsKey("velocity");
        const hasSpeed    = node.containsKey("speed");
        enforce(!hasSpeed || !hasVelocity,
                new YAMLException("PhysicsComponent can't specify both speed "
                                  "and velocity - one is syntactic sugar for "
                                  "the other."));
        velocity = hasVelocity ? fromYAML!Vector2f(node["velocity"], "velocity") :
                   hasSpeed    ? angleToVector(rotation) *
                                 fromYAML!float(node["speed"], "speed")
                               : Vector2f(0.0f, 0.0f);

        if(node.containsKey("spawnAbsolute")) 
        {
            foreach(string parameter; node["spawnAbsolute"]) switch(parameter)
            {
                case "position": spawnAbsolutePosition = true; break;
                case "rotation": spawnAbsoluteRotation = true; break;
                case "velocity": spawnAbsoluteVelocity = true; break;
                default:
                    throw new YAMLException("Unknown spawnAbsolute parameter: " ~ parameter);
            }
        }
    }

    ///Construct manually.
    this(Vector2f pos, float rot, Vector2f velocity)
    {
        position      = pos;
        rotation      = rot;
        this.velocity = velocity;
    }

    /**
     * Set this component as relative to specified component.
     *
     * E.g if position of rhs is (1, 0), and position of this component is 
     * (2, 0), the resulting position is (3, 0) (assuming no rotation).
     *
     * I.e. this component was at (1, 0) relative to rhs, and now it is (3, 0)
     * - in global coordinates.
     *
     * Note that if spawnAbsolutePosition is true, position will be set in 
     * absolute coordinates. Similarly for spawnAbsoluteRotation and 
     * spawnAbsoluteVelocity.
     */
    void setRelativeTo(ref PhysicsComponent rhs)
    {
        if(!spawnAbsoluteRotation){rotation += rhs.rotation;}
        if(!spawnAbsolutePosition){position = rhs.position + position.rotated(rhs.rotation);}
        if(!spawnAbsoluteVelocity){velocity = rhs.velocity + velocity.rotated(rhs.rotation);}
    }
}


