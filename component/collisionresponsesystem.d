//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Manages collision response of collidable entities.
module component.collisionresponsesystem;


import math.vector2;

import component.collidablecomponent;
import component.entitysystem;
import component.physicscomponent;
import component.system;
import component.volumecomponent;


/**
 * Manages collision response of collidable entities.
 *
 * Only entities with a CollidableComponent (AND a VolumeComponent) cam respond
 * to a collision.
 */
class CollisionResponseSystem : System 
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
            entitySystem_  = entitySystem;
        }

        ///Respond to collisions between collidables.
        void update()
        {
            foreach(ref Entity e,
                    ref PhysicsComponent physics,
                    ref VolumeComponent volume,
                    ref CollidableComponent collidable; 
                    entitySystem_)
            {
                if(collidable.hasColliders) foreach(collider; collidable.colliders)
                {
                    auto otherCollidable = collider.collidable;
                    if(otherCollidable is null){continue;}

                    //We've collided with something collidable (e.g. other ship)
                    //so - reverse velocity (cheap solution, but works for now).

                    physics.velocity = -physics.velocity;
                    break;
                }
            }
        }
}
