
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Component that provides movement capability to an entity.
module component.enginecomponent;


import math.vector2;
import util.yaml;


///Component that provides movement capability to an entity.
struct EngineComponent
{
    private static bool DO_NOT_DESTROY_AT_ENTITY_DEATH;
    ///Maximum speed of the entity.
    float maxSpeed;
    ///Acceleration in units per second. Negative means instant acceleration,
    float acceleration = -1.0; 

    /**
     * Direction to apply acceleration in. 
     *
     * In entity space, not world space.
     *
     * Usually a unit directional or zero (not accelerating) vector.
     */
    Vector2f accelerationDirection = Vector2f(0.0f, 0.0f);

    ///Is acceleration instant?
    @property bool instantAcceleration() const pure nothrow
    {
        return acceleration < 0.0f;
    }

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        maxSpeed     = fromYAML!(float, "a >= 0.0f")(yaml["maxSpeed"], "maxSpeed");
        acceleration = yaml.containsKey("acceleration") 
                     ? fromYAML!float(yaml["acceleration"], "acceleration") 
                     : -1.0f;
    }

    /**
     * Construct manually.
     *
     * Note that if acceleration is set to a negative value, it is instant.
     */
    this(const float maxSpeed, const float acceleration) pure nothrow
    {
        this.maxSpeed     = maxSpeed;
        this.acceleration = acceleration;
    }
}

