
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Makes an entity have limited health and die when that health is reduced to zero.
module component.healthcomponent;


import std.algorithm;

import component.entitysystem;

import math.math;
import util.yaml;


///Makes an entity have limited health and die when that health is reduced to zero.
struct HealthComponent
{
    /// Maximum health.
    uint maxHealth;

    /// Current health.
    uint health;

    /// Maximum shield.
    uint maxShield;

    /// Current shield. Float for gradual reloading.
    float shield;

    /// How much the shield regenerates per second.
    uint shieldReloadRate;

    /// ID of the last entity we've been damaged by.
    EntityID mostRecentlyDamagedBy;

    /// Have we've been damaged during this update?
    bool damagedThisUpdate = false;

    /// Load from a YAML node. Throws YAMLException on error.
    this(ref YAMLNode yaml)
    {
        if(yaml.isScalar)
        {
            health = maxHealth = yaml.as!uint;
        }
        else
        {
            health = maxHealth = yaml["health"].as!uint;
            shield = maxShield = 
                yaml.containsKey("shield") ? yaml["shield"].as!uint : 0;
            shieldReloadRate = yaml.containsKey("shieldReloadRate") 
                             ? yaml["shieldReloadRate"].as!uint : 50;
        }
    }

    /// Apply damage (or healing, if negative).
    void applyDamage(const EntityID damagedBy, const int damage)
    {
        mostRecentlyDamagedBy = damagedBy;
        damagedThisUpdate = true;
        if(hasShield)
        {
            // Healing doesn't apply to the shield.
            if(damage < 0)
            {
                health = min(maxHealth, health - damage);
                return;
            }

            const shieldInt = cast(int)shield;
            // If this is negative, the attack damages health.
            int shieldLeft = shieldInt - damage;
            shield = max(shieldLeft, 0);
            if(shieldLeft >= 0) {return;}
            // Apply the damage shield couldn't avoid.
            // Must cast to int to avoid underflow when adding a negative to uint.
            health = max(0, cast(int)health + shieldLeft);
            return;
        }
        health = clamp(0, cast(int)health - damage, cast(int)maxHealth);
    }

    /// Does the entity with this component have a shield?
    @property bool hasShield() const pure nothrow {return maxShield > 0;}
}

