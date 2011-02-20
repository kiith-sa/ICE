
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module spatial.gridspatialmanager;


import spatial.spatialmanager;
import spatial.volume;
import spatial.volumeaabbox;
import spatial.volumecircle;
import spatial.gridmonitor;
//used by unittest
import physics.physicsbody;
import monitor.monitormenu;
import math.math;
import math.vector2;
import math.rectangle;
import util.iterator;
import memory.memory;
import containers.array;
import containers.array2d;
import containers.vector;


///Implementation of spatial manager storing objects in a simple square grid.
class GridSpatialManager(T) : SpatialManager!(T)
{
    invariant
    {
        assert(cell_size_ > 0.0f, "Cell size must be greater than zero.");
        assert(grid_size_ > 0, "Grid size must be greater than zero.");
    }

    package:
        ///Grid cell.
        align(1) static struct Cell
        {
            ///Objects in the cell.
            Vector!(T) objects;

            ///Construct a cell.
            static Cell opCall()
            {
                Cell cell;
                cell.objects = Vector!(T)();
                return cell;
            }

            ///Destroy the cell.
            void die(){objects.die();}
        }

        ///Cells of the grid.
        Array2D!(Cell) grid_;
        ///Cell representing the area outside the grid.
        Cell outer_;

    private:
        ///Iterator used to iterate over groups of spatially close objects (cells).
        class ObjectIterator(T) : Iterator!(T[])
        {
            public:
                ///Used by foreach
                int opApply(int delegate(ref T[]) dg)
                {
                    int result = 0;

                    T[] array;
                    foreach(ref cell; grid_)
                    {
                        array = cell.objects.array;
                        result = dg(array);
                        if(result){break;}
                    }
                    array = outer_.objects.array;
                    result = dg(array);

                    return result;
                }
        }

        ///Origin of the grid (top-left corner) in world space.
        Vector2f origin_;
        ///Size of a single cell (both x and y).
        float cell_size_;
        ///Size of the grid in cells (both x and y).
        uint grid_size_;

    public:
        /**
         * Construct a grid spatial manager with specified parameters.
         *
         * Params:  center    = Center of the grid in world space.
         *          cell_size = Size of a grid cell (both x and y).
         *          grid_size = Size of the grid in cells (both x and y).
         */
        this(Vector2f center, float cell_size, uint grid_size)
        {
            cell_size_ = cell_size;
            grid_size_ = grid_size;

            float half_size_ = cell_size_ * grid_size_ * 0.5;
            origin_ = center - Vector2f(half_size_, half_size_);

            grid_ = Array2D!(Cell)(grid_size_, grid_size_);

            foreach(ref cell; grid_){cell = Cell();}
            outer_ = Cell();
        }

        override void die()
        {
            outer_.die();
            grid_.die();
        }

        override void add_object(T object)
        {
            assert(object.volume !is null, "Can't manage objects with null volumes");
            
            foreach(cell; cells(object.position, object.volume))
            {
                assert(!cell.objects.contains(object, true),
                       "Trying to add an object to a cell where it already is in the "
                       "grid spatial manager.");
                cell.objects ~= object;
            }
        }

        override void remove_object(T object)
        {
            assert(object.volume !is null, "Can't manage objects with null volumes");
            
            foreach(cell; cells(object.position, object.volume))
            {
                assert(cell.objects.contains(object, true),
                       "Trying to remove object from grid spatial manager that is not "
                       "present in expected cells.");
                cell.objects.remove(object, true);
            }
        }

        override void update_object(T object, Vector2f old_position)
        {
            assert(object.volume !is null, "Can't manage objects with null volumes");
            
            foreach(cell; cells(old_position, object.volume))
            {
                assert(cell.objects.contains(object, true),
                       "Trying to update object in grid spatial manager that is not "
                       "present in expected cells.");
                cell.objects.remove(object, true);
            }       
            add_object(object);
        }

        override Iterator!(T[]) iterator(){return new ObjectIterator!(T);}

        final override MonitorMenu monitor_menu()
        {
            return new GridSpatialManagerMonitor!(T)(this);
        }

        ///Get grid size (both X and Y) in cells.
        uint grid_size(){return grid_size_;}

    private:
        /**
         * Get all cells a volume is present in.
         *
         * More cells than needed might be returned, but all cells in which the volume
         * is present will be returned.
         *
         * Params:  position = Position of the volume in world space.
         *          volume   = Volume to check.
         *
         * Returns: Array of cells in which the volume is present.
         */
        Cell*[] cells(Vector2f position, Volume volume)
        {
            //determine volume type and use correct method based on that.
            if(volume.classinfo is VolumeAABBox.classinfo)
            {
                return cells_aabbox(position, cast(VolumeAABBox)volume);
            }
            else if(volume.classinfo is VolumeCircle.classinfo)
            {
                return cells_circle(position, cast(VolumeCircle)volume);
            }
            else{assert(false, "Unsupported volume type in GridSpatialManager");}
        }

        /**
         * Get all cells an axis aligned bounding box is present in.
         *
         * Params:  position = Position of the box in world space.
         *          box      = Bounding box to check.
         *
         * Returns: Array of cells in which the box is present.
         */
        Cell*[] cells_aabbox(Vector2f position, VolumeAABBox box)
        {
            return cells_rectangle(position, box.rectangle);
        }

        /**
         * Get all cells a bounding circle is present in.
         *
         * Params:  position = Position of the circle in world space.
         *          circle   = Bounding circle to check.
         *
         * Returns: Array of cells in which the circle is present.
         */
        Cell*[] cells_circle(Vector2f position, VolumeCircle circle)
        {
            //using rectangle test as it's faster and the overhead in
            //cells not significant.
            Vector2f offset = Vector2f(circle.radius, circle.radius);
            Rectanglef box = Rectanglef(-offset, offset);
            return cells_rectangle(position + circle.offset, box);
        }

        /**
         * Get all cells a bounding circle is present in.
         *
         * Params:  position = Position of the rectangle in world space.
         *          rect     = Rectangle to check.
         *
         * Returns: Array of cells in which the rectangle is present.
         */
        Cell*[] cells_rectangle(Vector2f position, ref Rectanglef rect)
        {
            alias math.math.min min;
            alias math.math.max max;

            //translate relative to the grid.
            Rectanglef translated = rect + (position - origin_);

            float mult = 1.0f / cell_size_;

            Cell*[] result;
            //get minimum and maximum cells containing the rectangle.
            int cell_x_min = floor_s32(translated.min.x * mult);
            int cell_x_max = floor_s32(translated.max.x * mult);
            int cell_y_min = floor_s32(translated.min.y * mult);
            int cell_y_max = floor_s32(translated.max.y * mult);

            //if outside the grid, add outer.
            if(cell_x_min < 0 || cell_y_min < 0 || 
               cell_x_max >= grid_size_ || cell_y_max >= grid_size_)
            {
                result ~= &outer_;
            }

            //now that we have outer (if needed) we can clamp to grid.
            cell_x_min = clamp(cell_x_min, 0, cast(int)grid_size_ - 1);
            cell_y_min = clamp(cell_y_min, 0, cast(int)grid_size_ - 1);
            cell_x_max = clamp(cell_x_max, 0, cast(int)grid_size_ - 1);
            cell_y_max = clamp(cell_y_max, 0, cast(int)grid_size_ - 1);

            //iterate over the cells that contain the rectangle and add all of them.
            for(uint x = cell_x_min; x <= cell_x_max; x++)
            {
                for(uint y = cell_y_min; y <= cell_y_max; y++)
                {
                    result ~= grid_.ptr(x,y);
                }
            }
            return result;
        }
        ///Unittest for cells_rectangle.
        unittest
        {
            auto zero = Vector2f(0.0f, 0.0f);
            auto manager = new GridSpatialManager!(PhysicsBody)(zero, 16.0f, 4);
            scope(exit){manager.die();}

            auto rectangle = Rectanglef(-15.0, -17.0, 15.0, 15.0);
            Cell*[] result = manager.cells_rectangle(zero, rectangle);
            assert(result.length == 6);
            
            rectangle = Rectanglef(-15.0, -15.0, 15.0, 33.0);
            result = manager.cells_rectangle(zero, rectangle);
            assert(result.length == 7);
            assert(result.contains(&manager.outer_, true));
        }
}
