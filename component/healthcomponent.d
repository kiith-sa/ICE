
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Makes an entity have limited health and die when that health is reduced to zero.
module component.healthcomponent;


import component.entitysystem;

import math.math;
import util.yaml;


///Makes an entity have limited health and die when that health is reduced to zero.
struct HealthComponent
{
    ///Maximum health.
    uint maxHealth;

    ///Current health.
    uint health;

    ///ID of the last entity we've been damaged by.
    EntityID mostRecentlyDamagedBy;

    ///Have we've been damaged during this update?
    bool damagedThisUpdate = false;

    ///Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        health = maxHealth = yaml.as!uint;
    }

    ///Apply damage (or healing, if negative).
    void applyDamage(const EntityID damagedBy, const int damage)
    {
        mostRecentlyDamagedBy = damagedBy;
        damagedThisUpdate = true;
        health = clamp(0, cast(int)health - damage, cast(int)maxHealth);
    }
}

