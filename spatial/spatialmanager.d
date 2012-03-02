
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for spatial managers.
module spatial.spatialmanager;
@safe

import monitor.monitorable;
import math.vector2;
import math.rectangle;
import util.iterable;


/**
 * Base class for spatial managers used for culling, coarse collision detecton, etc.
 *
 * Template parameter T is the type of managed objects. These must have
 * a "position" data member or accessor returning their position as Vector2f
 * and a "volume" data member or accessor to get volume of the object.
 *
 * Also, every object needs to have a non-null volume, SpatialManager can't handle
 * objects with null volumes.
 */
abstract class SpatialManager(T) : Monitorable
{
    public:
        ///Destroy the manager.
        ~this(){};

        /**
         * Add an object.
         *
         * Params:  object = Object to add. Must have a volume.
         */
        void add_object(T object);

        /**
         * Remove an object.
         *
         * Object must not be moved after adding or last update,
         * otherwise this method results in undefined behavior.
         * Also, volume of the object is expected to be immutable (or, at least,
         * not changed since object was last updated/added).
         *
         * Params:  object = Object to remove. Must have a volume. 
         */
        void remove_object(T object);

        /**
         * Update an object in the manager.
         *
         * Volume of the object is expected to be immutable (or at least
         * not changed since the object was last updated/added).
         *
         * Params:  object       = Object to update.
         *          old_position = Position of the object last time when it was updated or added.
         */
        void update_object(T object, in Vector2f old_position);

        ///Return an iterator iterating over groups of spatially close objects.
        @property Iterable!(T[]) iterable();
}
