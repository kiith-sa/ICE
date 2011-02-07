module spatial.gridspatialmanager;


import spatial.spatialmanager;
import spatial.volume;
import spatial.volumeaabbox;
import spatial.volumecircle;
//used by unittest
import physics.physicsbody;
import math.math;
import math.vector2;
import math.rectangle;
import iterator;
import allocator;
import arrayutil;
import array2d;
import vector;


///Implementation of spatial manager storing objects in a simple square grid.
class GridSpatialManager(T) : SpatialManager!(T)
{
    invariant
    {
        assert(cell_size_ > 0.0f, "Grid spatial manager cell size must be greater than zero.");
        assert(grid_size_ > 0, "Grid spatial manager grid size must be greater than zero.");
    }

    private:
        //Grid cell struct.
        align(1) static struct Cell
        {
            //Objects in the cell.
            T[] objects;
        }

        //Origin of the grid (top-left corner).
        Vector2f origin_;
        //Size of a single cell (both x and y).
        float cell_size_;
        //Size of the grid in cells (both x and y).
        uint grid_size_;

        ///Cell representing the area outside the grid.
        Cell outer_;

        //Cells of the grid.
        Array2D!(Cell) grid_;

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
        }

        void die(){grid_.die();}

        void add_object(T object)
        in
        {
            assert(object.volume !is null, 
                   "Spatial manager can't manage objects with null volumes");
        }
        body
        {
            foreach(cell; cells(object.position, object.volume))
            {
                cell.objects ~= object;
            }
        }

        void remove_object(T object)
        in
        {
            assert(object.volume !is null, 
                   "Spatial manager can't manage objects with null volumes");
        }
        body
        {
            foreach(cell; cells(object.position, object.volume))
            {
                assert(cell.objects.contains(object, true),
                       "Trying to remove object from grid spatial manager that is not "
                       "present in expected cells.");
                cell.objects.remove(object, true);
            }
        }

        void update_object(T object, Vector2f old_position)
        in
        {
            assert(object.volume !is null, 
                   "Spatial manager can't manage objects with null volumes");
        }
        body
        {
            foreach(cell; cells(old_position, object.volume))
            {
                assert(cell.objects.contains(object, true),
                       "Trying to update object in grid spatial manager that is not "
                       "present in expected cells.");
                cell.objects.remove(object, true);
            }       
            add_object(object);
        }

        Iterator!(T[]) iterator(){return new ObjectIterator!(T)(this);}

    private:
        /*
         * Determine in which cells should specified volume be present.
         *
         * More cells than needed could be returned, but never less.
         * (all cells in which the volume is present will be returned.)
         *
         * Params:  position = Position of the volume.
         *          volume   = Volume to check.
         *
         * Returns: Array of cells in which the volume should be present.
         */
        Cell*[] cells(Vector2f position, Volume volume)
        {
            //determine volume type and use correct function based on that.
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

        /*
         * Determine in which cells should specified bounding box be present.
         *
         * Params:  position = Position of the box.
         *          box      = Bounding box to check.
         *
         * Returns: Array of cells in which the box should be present.
         */
        Cell*[] cells_aabbox(Vector2f position, VolumeAABBox box)
        {
            return cells_rectangle(position, box.rectangle);
        }

        /*
         * Determine in which cells should specified bounding circle be present.
         *
         * Params:  position = Position of the circle.
         *          circle   = Bounding circle to check.
         *
         * Returns: Array of cells in which the circle should be present.
         */
        Cell*[] cells_circle(Vector2f position, VolumeCircle circle)
        {
            //using rectangle test as it's faster and the overhead in
            //cells not significant.
            Vector2f offset = Vector2f(circle.radius, circle.radius);
            Rectanglef box = Rectanglef(-offset, offset);
            return cells_rectangle(position + circle.offset, box);
        }

        /*
         * Determine in which cells should specified rectangle be present.
         *
         * Params:  position = Position of the rectangle.
         *          rect     = Rectangle to check.
         *
         * Returns: Array of cells in which the rectangle should be present.
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
        unittest
        {
            auto zero = Vector2f(0.0f, 0.0f);
            auto manager = new GridSpatialManager!(PhysicsBody)(zero, 16.0f, 4);

            auto rectangle = Rectanglef(-15.0, -17.0, 15.0, 15.0);
            Cell*[] result = manager.cells_rectangle(zero, rectangle);
            assert(result.length == 6);
            
            rectangle = Rectanglef(-15.0, -15.0, 15.0, 33.0);
            result = manager.cells_rectangle(zero, rectangle);
            assert(result.length == 7);
            assert(result.contains(&manager.outer_, true));
        }
}


private:

//Iterator used to iterate over groups of spatially close objects in the grid spatial manager.
class ObjectIterator(T) : Iterator!(T[])
{
    private:
        //Manager to iterate over objects from.
        GridSpatialManager!(T) manager_;

        //We iterate over all the cells, outer, and end the iteration.

        //X coordinate of the next cell in the grid.
        uint cell_x_ = 0;
        //Y coordinate of the next cell in the grid.
        uint cell_y_ = 0;

        /*
         * Construct an ObjectIterator.
         *
         * Params:  manager = Manager to iterate over objects from.
         */
        this(GridSpatialManager!(T) manager){manager_ = manager;}

    public:
        override T[] next()
        in{assert(has_next(), "Trying to iterate out of bounds");}
        body
        {
            //We've finished the last column, i.e. only outer is left.
            if(cell_x_ == manager_.grid_size_)
            {
                //we set cell_y_ to grid size signifying end of the iteration.
                cell_y_ = manager_.grid_size_;
                return manager_.outer_.objects;
            }

            T[] output = manager_.grid_[cell_x_, cell_y_].objects;

            //Next cell.
            cell_y_++;

            //We've finished a column, start next column.
            if(cell_y_ == manager_.grid_size_)
            {
                cell_y_ = 0;
                cell_x_++;
            }

            return output;
        }

        override bool has_next()
        {
            //if both cell coords are grid_size_ (outside of grid), we've finished iterating.
            return !(cell_x_ == manager_.grid_size_ && 
                     cell_y_ == manager_.grid_size_);
        }
}
