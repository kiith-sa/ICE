
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module spatial.gridmonitor;


import std.math;

import spatial.gridspatialmanager;
import gui.guimousecontrollable;
import monitor.submonitor;
import video.videodriver;
import math.math;
import math.vector2;
import math.rectangle;
import containers.array2d;
import time.timer;
import color;


///Monitor monitoring object counts in cells of a GridSpatialManager grid.
final package class GridMonitor(T) : SubMonitor
{
    private:
        ///Monitored GridSpatialManager.
        GridSpatialManager!(T) monitored_;

        ///Object counts of cells in the grid.
        Array2D!(uint) object_counts_;
        ///Objects in the "outer" cell of the GridSpatialManager (objects outside the grid).
        uint outer_object_count_;

        ///Timer used to determine when to update data from the monitored manager.
        Timer update_timer_;

        ///Size of the grid (both X and Y).
        uint grid_size_;

    public:
        /**
         * Construct a GridMonitor.
         *
         * Params:  monitored = GridSpatialManager to monitor.
         */
        this(GridSpatialManager!(T) monitored)
        {
            super();

            monitored_ = monitored;
            grid_size_ = monitored_.grid_size;
            object_counts_ = Array2D!(uint)(grid_size_, grid_size_);

            update_timer_ = Timer(0.02);
        }

        override void die()
        {
            super.die();
            object_counts_.die();
        }

        override SubMonitorView view(){return new GridMonitorView!(typeof(this))(this);}

    package:
        ///Update monitored data.
        void update()
        {
            //Using timer to prevent updating every frame.
            if(update_timer_.expired)
            {
                for(uint x = 0; x < grid_size_; x++)
                {
                    for(uint y = 0; y < grid_size_; y++)
                    {
                        object_counts_[x, y] = cast(uint)monitored_.grid_[x, y].objects.length;
                    }
                }
                outer_object_count_ = cast(uint)monitored_.outer_.objects.length;
                update_timer_.reset();
            }
        }

        ///Get number of objects outside the grid.
        uint outer_object_count(){return outer_object_count_;}

        ///Get (x and y) grid size in cells.
        uint grid_size(){return grid_size_;}

        ///Get a pointer to the array of object counts in the grid. 
        Array2D!(uint)* object_counts(){return &object_counts_;} 
}

///Grid monitor GUI view.
final package class GridMonitorView(GridMonitor) : SubMonitorView
{
    private:
        ///GridMonitor viewed.
        GridMonitor monitor_;

        ///Provides mouse zooming and panning.
        mixin MouseControl!(1.1) mouse_;

    public:
        ///Construct a GridView viewing specified GridMonitor.
        this(GridMonitor monitor)
        {
            super();
            monitor_ = monitor;
            mouse_.init();
        }

    protected:
        override void draw(VideoDriver driver)
        {
            monitor_.update();

            if(!visible_){return;}
            super.draw(driver);

            auto bounds = main_.bounds_global();

            //convert bounds to float for drawing and slightly cut them to
            //prevent overdrawing border.
            Vector2f bounds_min = to!(float)(bounds.min) + Vector2f(0.0f, 1.0f);
            Vector2f bounds_max = to!(float)(bounds.max) + Vector2f(-1.0f, 0.0f); 

            //prevent drawing outside bounds.
            driver.scissor(Rectanglei(to!(int)(bounds_min), to!(int)(bounds_max)));

            //draw background.
            driver.draw_filled_rectangle(bounds_min, bounds_max, Color.black);
            //Color of the current cell
            Color color = Color.blue;
            color.a = cast(ubyte)min(255u, 32 * monitor_.outer_object_count);

            //draw outer.
            driver.draw_filled_rectangle(bounds_min, bounds_max, color);

            //grid size on screen.
            Vector2f grid_size = Vector2f(256.0f, 256.0f) * zoom_;
            Vector2f origin = to!(float)(bounds_.center) - 0.5f * grid_size + offset_;

            //draw background for the grid.
            driver.draw_filled_rectangle(origin, origin + grid_size, Color.black);

            float cell_size = grid_size.x / monitor_.grid_size;

            //coords of the current cell.
            Vector2f cell_min = origin;
            Vector2f cell_max = cell_min + Vector2f(cell_size, cell_size);
            //draw the grid.
            for(uint x = 0; x < monitor_.grid_size; x++)
            {
                for(uint y = 0; y < monitor_.grid_size; y++)
                {
                    color.a = cast(ubyte)min(255u, 32 * (*monitor_.object_counts)[x, y]); 
                    driver.draw_filled_rectangle(cell_min, cell_max, color);

                    cell_min.y += cell_size;
                    cell_max.y += cell_size;
                }
                cell_min.y = origin.y;
                cell_max.y = cell_min.y + cell_size;
                cell_min.x += cell_size;
                cell_max.x += cell_size;
            }

            driver.disable_scissor();
        }
}
