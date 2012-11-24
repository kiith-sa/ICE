
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Manages scoring, experience gain, and so on.
module component.scoresystem;


import component.entitysystem;
import component.healthcomponent;
import component.scorecomponent;
import component.system;


/// Manages scoring, experience gain, and so on.
class ScoreSystem : System 
{
    private:
        /// Entity system whose data we're processing.
        EntitySystem entitySystem_;

    public:
        /// Construct a ScoreSystem working on entities from specified EntitySystem.
        this(EntitySystem entitySystem)
        {
            entitySystem_  = entitySystem;
        }

        /// Update scores of entities that destroyed other entities.
        void update()
        {
            foreach(ref Entity e, ref HealthComponent health, ref ScoreComponent score; entitySystem_)
            {
                if(e.killed)
                {
                    updateStatisticsOfKiller(health, score);
                }
            }
        }

    private:
        /// Update statistics of the entity that killed the entity with specified components.
        void updateStatisticsOfKiller(ref HealthComponent health, ref ScoreComponent score)
        {
            // Update statistics of whoever killed us.

            EntityID id = health.mostRecentlyDamagedBy;
            Entity* damagedBy;

            // If damagedBy has an owner, get the owner, if the owner
            // has an owner, get that, etc.
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
                statistics.expGained += score.exp;
            }
        }
}

