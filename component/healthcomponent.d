
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Makes an entity have limited health and die when that health is reduced to zero.
module component.healthcomponent;


import math.math;
import util.yaml;


///Makes an entity have limited health and die when that health is reduced to zero.
struct HealthComponent
{
    ///Maximum health.
    uint maxHealth;

    ///Current health.
    uint health;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        health = maxHealth = yaml.as!uint;
    }

    ///Apply damage (or healing, if negative).
    void applyDamage(const int damage)
    {
        health = clamp(0, cast(int)health - damage, cast(int)maxHealth);
    }
}

