
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Spatial manager based on a simple grid.
module spatial.gridspatialmanager;


import std.algorithm;

import spatial.spatialmanager;
import spatial.volume;
import spatial.volumeaabbox;
import spatial.volumecircle;
import spatial.gridmonitor;
//used by unittest
import physics.physicsbody;
import monitor.monitordata;
import monitor.submonitor;
import math.math;
import math.vector2;
import math.rect;
import util.iterable;
import memory.memory;
import containers.array2d;
import containers.vector;


///Implementation of spatial manager storing objects in a simple square grid.
class GridSpatialManager(T) : SpatialManager!T
{
    invariant()
    {
        assert(cellSize_ > 0.0f, "Cell size must be greater than zero.");
        assert(gridSize_ > 0, "Grid size must be greater than zero.");
    }

    package:
        ///Grid cell.
        align(4) static struct Cell
        {
            ///Objects in the cell.
            Vector!T objects;
        }

        ///Cells of the grid.
        Array2D!Cell grid_;
        ///Cell representing the area outside the grid.
        Cell outer_;

    private:
        ///Iterable used to iterate over groups of spatially close objects (cells).
        class ObjectIterable(T) : Iterable!(T[])
        {
            this() pure {}

            ///Used by foreach
            public @trusted override int opApply(int delegate(ref T[]) dg)
            {
                int result = 0;

                T[] array;
                foreach(ref cell; grid_)
                {
                    array = cell.objects.ptrUnsafe[0 .. cell.objects.length];
                    result = dg(array);
                    if(result){break;}
                }

                array = outer_.objects.ptrUnsafe[0 .. outer_.objects.length];
                result = dg(array);
                return result;
            }
        }

        ///Origin of the grid (top-left corner) in world space.
        const Vector2f origin_;
        ///Size of a single cell (both x and y).
        const float cellSize_;
        ///Size of the grid in cells (both x and y).
        const uint gridSize_;

    public:
        /**
         * Construct a grid spatial manager with specified parameters.
         *
         * Params:  center    = Center of the grid in world space.
         *          cellSize = Size of a grid cell (both x and y).
         *          gridSize = Size of the grid in cells (both x and y).
         */
        this(const Vector2f center, const float cellSize, const uint gridSize)
        {
            cellSize_ = cellSize;
            gridSize_ = gridSize;

            float halfSize_ = cellSize_ * gridSize_ * 0.5;
            origin_ = center - Vector2f(halfSize_, halfSize_);

            grid_ = Array2D!Cell(gridSize_, gridSize_);

            foreach(ref cell; grid_){cell = Cell();}
            outer_ = Cell();
        }

        override void addObject(T object)
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

        override void removeObject(T object)
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

        override void clearObjects()
        {
            foreach(ref cell; grid_)
            {
                clear(cell.objects);
            }
            clear(outer_.objects);
        }

        override void updateObject(T object, const Vector2f oldPosition)
        {
            assert(object.volume !is null, "Can't manage objects with null volumes");
            
            foreach(cell; cells(oldPosition, object.volume))
            {
                assert(cell.objects.contains(object, true),
                       "Trying to update object in grid spatial manager that is not "
                       "present in expected cells.");
                cell.objects.remove(object, true);
            }       
            addObject(object);
        }

        @property override Iterable!(T[]) iterable() pure {return new ObjectIterable!T;}

        ///Get grid size (both X and Y) in cells.
        @property uint gridSize() const pure {return gridSize_;}

        @property MonitorDataInterface monitorData()
        {
            SubMonitor function(GridSpatialManager!T)[string] ctors_;
            ctors_["Grid"] = function SubMonitor(GridSpatialManager!T m)
                                                 {return new GridMonitor!T(m);};
            return new MonitorData!(GridSpatialManager!T)(this, ctors_);
        }

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
        Cell*[] cells(const Vector2f position, const Volume volume)
        {
            //determine volume type and use correct method based on that.
            if(volume.classinfo is VolumeAABBox.classinfo)
            {
                return cellsAabbox(position, cast(VolumeAABBox)volume);
            }
            else if(volume.classinfo is VolumeCircle.classinfo)
            {
                return cellsCircle(position, cast(VolumeCircle)volume);
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
        Cell*[] cellsAabbox(const Vector2f position, const VolumeAABBox box)
        {
            return cellsRect(position, box.rectangle);
        }

        /**
         * Get all cells a bounding circle is present in.
         *
         * Params:  position = Position of the circle in world space.
         *          circle   = Bounding circle to check.
         *
         * Returns: Array of cells in which the circle is present.
         */
        Cell*[] cellsCircle(const Vector2f position, const VolumeCircle circle)
        {
            //using rectangle test as it's faster and the overhead in
            //cells not significant.
            const offset = Vector2f(circle.radius, circle.radius);
            const box    = Rectf(-offset, offset);
            return cellsRect(position + circle.offset, box);
        }

        /**
         * Get all cells a bounding circle is present in.
         *
         * Params:  position = Position of the rectangle in world space.
         *          rect     = Rect to check.
         *
         * Returns: Array of cells in which the rectangle is present.
         */
        Cell*[] cellsRect(const Vector2f position, const ref Rectf rect)
        {
            //translate relative to the grid.
            const Rectf translated = rect + (position - origin_);

            const float mult = 1.0f / cellSize_;

            Cell*[] result;
            //get minimum and maximum cells containing the rectangle.
            int cellXMin = floor!int(translated.min.x * mult);
            int cellXMax = floor!int(translated.max.x * mult);
            int cellYMin = floor!int(translated.min.y * mult);
            int cellYMax = floor!int(translated.max.y * mult);

            //if outside the grid, add outer.
            if(cellXMin < 0 || cellYMin < 0 || 
               cellXMax >= gridSize_ || cellYMax >= gridSize_)
            {
                result ~= &outer_;
            }

            //now that we have outer (if needed) we can clamp to grid.
            cellXMin = clamp(cellXMin, 0, cast(int)gridSize_ - 1);
            cellYMin = clamp(cellYMin, 0, cast(int)gridSize_ - 1);
            cellXMax = 1 + clamp(cellXMax, 0, cast(int)gridSize_ - 1);
            cellYMax = 1 + clamp(cellYMax, 0, cast(int)gridSize_ - 1);

            //iterate over the cells that contain the rectangle and add all of them.
            foreach(x; cellXMin .. cellXMax) foreach(y; cellYMin .. cellYMax)
            {
                result ~= &grid_[x,y];
            }
            return result;
        }
        ///Unittest for cellsRect.
        unittest
        {
            auto zero = Vector2f(0.0f, 0.0f);
            auto manager = new GridSpatialManager!PhysicsBody(zero, 16.0f, 4);
            scope(exit){clear(manager);}

            auto rectangle = Rectf(-15.0, -17.0, 15.0, 15.0);
            Cell*[] result = manager.cellsRect(zero, rectangle);
            assert(result.length == 6);
            
            rectangle = Rectf(-15.0, -15.0, 15.0, 33.0);
            result = manager.cellsRect(zero, rectangle);
            assert(result.length == 7);
            assert(canFind!"a is b"(result, &manager.outer_));
        }
}
