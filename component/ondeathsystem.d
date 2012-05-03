
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Allows callbacks when an entity (with a OnDeathComponent) dies.
module component.ondeathsystem;


import component.entitysystem;
import component.ondeathcomponent;
import component.system;


/**
 * Allows callbacks when an entity (with an OnDeathComponent) dies.
 *
 * Must be updated $(B after) all subsystems that might kill an entity.
 */
class OnDeathSystem : System 
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

    public:
        /**
         * Construct a CollisionResponseSystem.
         *
         * Params:  entitySystem  = EntitySystem whose entities we're processing.
         */
        this(EntitySystem entitySystem)
        {
            entitySystem_ = entitySystem;
        }

        ///Call onDeath callbacks of OnDeathComponents.
        void update()
        {
            foreach(ref Entity entity, OnDeathComponent onDeath; entitySystem_)
            {
                if(entity.killed){onDeath.onDeath(entity);}
            }
        }
}
