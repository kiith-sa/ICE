

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
                if(health.health == 0){e.kill();}
            }
        }
}
