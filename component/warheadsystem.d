
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Applies warheads of entities that collided with Collidables.
module component.warheadsystem;


import component.collidablecomponent;
import component.entitysystem;
import component.healthcomponent;
import component.physicscomponent;
import component.system;
import component.warheadcomponent;


/**
 * Applies warheads of entities that collided with Collidables.
 *
 * Any collidable that has a HealthComponent checks all its colliders.
 * If the collider has a Warhead, the warhead's effect is
 * applied to the collidable (e.g. damage affects HealthComponent).
 *
 * Possibly, HealthComponent might not be required to allow warheads
 * affecting entities without health.
 */
class WarheadSystem : System 
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

        ///Apply warhead's damage.
        void update()
        {
            //For each collidable with health:
            foreach(ref Entity e,
                    ref PhysicsComponent physics,
                    ref CollidableComponent collidable,
                    ref HealthComponent health; 
                    entitySystem_)
            {
                if(!collidable.hasColliders){continue;}

                //For each collider:
                foreach(collider; collidable.colliders)
                {
                    //If our collidable is the owner of the collider, ignore it.
                    //I.e. a ship can't hit itself)
                    auto owner   = collider.owner;
                    if(owner !is null && owner.ownerID == e.id){continue;}

                    //If the collider has no warhead, ignore it.
                    auto warhead = collider.warhead;
                    if(warhead is null){continue;}

                    //Apply damage of the collider, and destroy it.
                    health.applyDamage(warhead.damage);
                    if(warhead.killsEntity){collider.kill();}
                }
            }
        }
}
