
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Manages entity health and destroys entities that have run out of health.
module component.healthsystem;


import std.algorithm;

import component.entitysystem;
import component.healthcomponent;
import component.system;

import time.gametime;


///Manages entity health and destroys entities that have run out of health.
class HealthSystem : System 
{
private:
    /// Entity system whose data we're processing.
    EntitySystem entitySystem_;

    /// Game time subsystem, used for any regeneration (e.g. shield reload).
    GameTime gameTime_;

public:
    /// Construct a HealthSystem working on entities from specified EntitySystem and GameTime.
    this(EntitySystem entitySystem, GameTime gameTime)
    {
        entitySystem_  = entitySystem;
        gameTime_      = gameTime;
    }

    /// Destroy entities that have run out of health.
    void update()
    {
        foreach(ref Entity e, ref HealthComponent health; entitySystem_)
        {
            // Reload any shields.
            if(health.hasShield)
            {
                health.shield = 
                    min(health.maxShield, 
                        health.shield + health.shieldReloadRate * gameTime_.timeStep);
            }
            if(health.health == 0)
            {
                updateStatisticsOfKiller(health);

                e.kill();
            }
            health.damagedThisUpdate = false;
        }
    }

private:
    /// Update statistics of the entity that killed the entity with specified HealthComponent.
    void updateStatisticsOfKiller(ref HealthComponent health)
    {
        if(!health.damagedThisUpdate) {return;}

        //Update statistics of whoever killed us.
        EntityID id = health.mostRecentlyDamagedBy;
        Entity* damagedBy;

        //If damagedBy has an owner, get the owner, if the owner
        //has an owner, get that, etc.
        for(;;)
        {
            damagedBy = entitySystem_.entityWithID(id);
            //The entity was destroyed.
            if(damagedBy is null){return;}
            auto owner = damagedBy.owner;
            if(owner is null){break;}
            id = owner.ownerID;
        }

        auto statistics = damagedBy.statistics;
        if(statistics !is null)
        {
            ++statistics.entitiesKilled;
        }
    }
}
