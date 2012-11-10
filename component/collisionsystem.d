
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Manages collision detection of collidable entities.
module component.collisionsystem;


import std.algorithm;
import std.math;
import std.typecons;

import math.rect;
import math.vector2;
import containers.vector;

import component.collidablecomponent;
import component.entitysystem;
import component.physicscomponent;
import component.spatialsystem;
import component.system;
import component.volumecomponent;


/**
 * Manages collision detection of collidable entities.
 *
 * Only entities with a CollidableComponent (AND a VolumeComponent) detect collision.
 * However, collisions are detected with every entity with a VolumeComponent.
 *
 * This way a ship (which has a CollidableComponent) can collide with a projectile 
 * (which only has a VolumeComponent), but projectiles can't collide with each other.
 */
class CollisionSystem : System 
{
    private:
        ///Entity system whose data we're processing.
        EntitySystem entitySystem_;

        ///Spatial system used for coarse collision detection.
        SpatialSystem spatialSystem_;

        ///Colliders of a collidable are a vector of poiters to colliding entities.
        alias Vector!(Entity*) Colliders;

        /**
         * Stores a list of colliders for each collidable that has one or more colliders.
         *
         * Order of these lists does not matter; pointers colliders of each collidable are 
         * stored in the list, and a slice to that storage is passed to the collidable.
         * What is important is that the storage stays valid until the next update,
         * when it is clear.
         */
        Vector!Colliders collidersOfEntities_;

        /**
         * Number of used entries in collidersOfEntities_. 
         *
         * We don't decrease length of collidersOfEntities_ so that the memory 
         * allocated by collider lists does not get deallocated.
         */
        uint collidersUsed_;

    public:
        /**
         * Construct a CollisionSystem.
         *
         * Params:  entitySystem  = EntitySystem whose entities we're processing.
         *          spatialSystem = SpatialSystem to handle coarse collision detection.
         */
        this(EntitySystem entitySystem, SpatialSystem spatialSystem)
        {
            entitySystem_  = entitySystem;
            spatialSystem_ = spatialSystem;
            enum collidersPrealloc = 16;
            collidersOfEntities_.length = collidersPrealloc;
            foreach(c; 0 .. collidersPrealloc)
            {
                collidersOfEntities_[c].reserve(32);
            }
        }

        ///Destroy the collision system, freeing all memory used by collider lists.
        ~this()
        {
            foreach(ref colliders; collidersOfEntities_)
            {
                .clear(colliders);
            }
            .clear(collidersOfEntities_);
            collidersUsed_ = 0;
        }

        ///Detect collisions between collidables and entities with volumes.
        void update()
        {
            clear();

            foreach(ref Entity e,
                    ref PhysicsComponent physics,
                    ref VolumeComponent volume,
                    ref CollidableComponent collidable; 
                    entitySystem_)
            {
                //+ 1 is enough as Vector internally reallocates quadratically by itself.
                if(collidersUsed_ == collidersOfEntities_.length)
                {
                    collidersOfEntities_.length = collidersOfEntities_.length + 1;
                }

                Colliders* colliders = &collidersOfEntities_[collidersUsed_];
                foreach(ref Entity colliderEntity,
                        ref PhysicsComponent colliderPhysics,
                        ref VolumeComponent colliderVolume;
                        spatialSystem_.neighbors(physics, volume))
                {
                    if(e.id != colliderEntity.id &&
                       collides(physics, volume, colliderPhysics, colliderVolume))
                    {
                        (*colliders) ~= &colliderEntity;
                    }
                }

                //Only use the colliders list if there are any colliders.
                if(colliders.length > 0)
                {
                    collidable.colliders = (*colliders)[];
                    ++collidersUsed_;
                }
                else
                {
                    collidable.colliders = null;
                }
            }
        }

    private:
        ///Clear all collider lists when starting an update.
        void clear()
        {
            foreach(ref colliders; collidersOfEntities_[0 .. collidersUsed_])
            {
                colliders.length = 0;
            }
            collidersUsed_ = 0;
        }
}

private:

///Check for collision between two volumes at specified physics positions.
bool collides(ref PhysicsComponent physics1, ref VolumeComponent volume1,
              ref PhysicsComponent physics2, ref VolumeComponent volume2) pure nothrow
{
    if(volume1.type == VolumeComponent.Type.AABBox &&
       volume2.type == VolumeComponent.Type.AABBox)
    {
        //Combined half-widths/half-heights of the rectangles.
        const Vector2f combined = (volume1.aabbox.size + volume2.aabbox.size) * 0.5f;

        //Distance between centers of the rectangles.
        const Vector2f distance = (physics2.position + volume2.aabbox.center) - 
                                  (physics1.position + volume1.aabbox.center);
     
        //Calculate absolute distance coords
        //this is used to determine collision.
        const distanceAbs = Vector2f(abs(distance.x), abs(distance.y));

        //AABBoxes are intersecting if:
        //their x distance is less than their combined halfwidths
        //AND their y distance is less than their combined halfheights
        return distanceAbs.x < combined.x && distanceAbs.y < combined.y;
    }
    assert(false, "Unknown volume type combination or uninitialized volume/s");
}
