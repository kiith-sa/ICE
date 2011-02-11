module spatial.spatialmanager;


import physics.physicsbody;
import monitor.monitorable;
import monitor.monitormenu;
import math.vector2;
import math.rectangle;
import util.iterator;


///Base class for spatial managers used e.g. for culling, coarse collision detecton
abstract class SpatialManager(T) : Monitorable
{
    public:
        ///Destroy the spatial manager.
        void die();

        /**
         * Add an object to the manager. 
         *
         * Volume of the object must not be null.
         *
         * Params:  object = Object to add.
         */
        void add_object(T object);

        /**
         * Remove an object from the manager.
         *
         * Object must not be moved after adding or last update,
         * otherwise a call to this method can result in undefined behavior.
         * Also, volume of the object is expected to be immutable (or, at least,
         * not changed since object was last updated/added)
         *
         * Params:  object = Object to remove.
         */
        void remove_object(T object);

        /**
         * Update an object in the manager.
         *
         * Volume of the object is expected to be immutable (or, at least,
         * not changed since object was last updated/added)
         *
         * Params:  object       = Object to update.
         *          old_position = Position of the object when it was last updated or added.
         */
        void update_object(T object, Vector2f old_position);

        ///Return an iterator iterating over groups of spatially close objects.
        Iterator!(T[]) iterator();

        MonitorMenu monitor_menu()
        {
            //This must be implemented due to what's apparently a compiler bug
            assert(false);
        }
        //Iterator!(T[]) iterator(Rectanglef limits);
}
