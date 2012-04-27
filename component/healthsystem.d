

//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Manages entity health and destroys entities that have run out of health.
module component.healthsystem;


import component.entitysystem;
import component.healthcomponent;
import component.system;


///Manages entity health and destroys entities that have run out of health.
class HealthSystem : System 
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

    public:
        ///Construct a WeaponSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_  = entitySystem;
        }

        ///Destroy entities that have run out of health.
        void update()
        {
            foreach(ref Entity e, ref HealthComponent health; entitySystem_)
            {
                if(health.health == 0)
                {
                    updateStatisticsOfKiller(health);

                    e.kill();
                }
                health.damagedThisUpdate = false;
            }
        }

    private:
        ///Update statistics of the entity that killed the entity with specified HealthComponent.
        void updateStatisticsOfKiller(ref HealthComponent health)
        {
            //Update statistics of whoever killed us.
            if(health.damagedThisUpdate)
            {
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
}
