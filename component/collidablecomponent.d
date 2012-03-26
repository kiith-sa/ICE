
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Makes an entity able to collide with other entities.
module component.collidablecomponent;


import std.exception;

import util.yaml;

import component.entitysystem;


/**
 * Makes an entity able to collide with other entities.
 *
 * An entity with CollidableComponent collides with anything that has a volume, 
 * regardless of whether it has its own CollidableComponent or not.
 */
struct CollidableComponent 
{
    private:
        /**
         * IDs of entities that collided with this entity last CollisionSystem update.
         *
         * This is a slice into FixedArray storage.
         */
        Entity*[] colliders_ = null;

    public:
        ///Construct an axis aligned bounding box from a rectangle.
        this(ref YAMLNode yaml)
        {
            enforce(yaml.isNull,
                    new YAMLException("CollidableComponent currently supports no YAML data"));
        }

        ///Get IDs of all entities that collided with this entity last CollisionSystem update.
        @property Entity*[] colliders() pure nothrow 
        in
        {
            assert(colliders_ !is null, 
                   "Trying to get colliders of an entity that has no colliders, "
                   "or before CollisionSystem update.");
        }
        body{return colliders_;}

        ///Set colliders of this entity.
        @property void colliders(Entity*[] rhs) pure nothrow {colliders_ = rhs;}

        ///Did this entity collide with anything last CollisionSystem update?
        @property bool hasColliders() const pure nothrow {return colliders_ !is null;}
}
