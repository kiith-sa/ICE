
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module spatial.gridmonitor;


import std.math;

import spatial.gridspatialmanager;
import gui.guielement;
import gui.guimenu;
import gui.guimousecontrollable;
import monitor.monitormenu;
import monitor.submonitor;
import video.videodriver;
import math.math;
import math.vector2;
import math.rectangle;
import containers.array2d;
import time.timer;
import color;


///Monitor displaying a graphical representation of the grid of GridSpatialManager.
final package class GridMonitor(T) : SubMonitor
{
    private:
        //Monitored GridSpatialManager.
        GridSpatialManager!(T) monitored_;

        //GUI element used to view the grid.
        class GridView : GUIElement
        {
            invariant
            {
                assert(zoom_mult_ >= 1.0, "GridView zoom multiplier must be greater than 1");
                assert(zoom_ >= 0.0, "GridView zoom must be greater than 0");
            }

            private:
                //Current view offset,
                Vector2f offset_;
                //Zoom multiplier corresponding to one zoom level.
                real zoom_mult_ = 1.1;
                //Current zoom. 
                real zoom_ = 1.0;

            public:
                this()
                {
                    super(GUIElementParams("p_left + 2", "p_top + 2", 
                                           "p_width - 4", "p_height - 4", 
                                           false));

                    //provides zooming/panning functionality
                    auto mouse_control = new GUIMouseControllable;
                    mouse_control.zoom.connect(&zoom);
                    mouse_control.pan.connect(&pan);
                    mouse_control.reset_view.connect(&reset_view);

                    add_child(mouse_control);
                }

            protected:
                override void draw(VideoDriver driver)
                {
                    if(!visible_){return;}
                    super.draw(driver);

                    //convert bounds to float for drawing and slightly cut them to
                    //prevent overdrawing border.
                    Vector2f bounds_min = to!(float)(bounds_.min) + Vector2f(0.0f, 1.0f);
                    Vector2f bounds_max = to!(float)(bounds_.max) + Vector2f(-1.0f, 0.0f); 

                    //prevent drawing outside bounds.
                    driver.scissor(Rectanglei(to!(int)(bounds_min), to!(int)(bounds_max)));

                    //draw background.
                    driver.draw_filled_rectangle(bounds_min, bounds_max, Color.black);
                    //Color of the current cell
                    Color color = Color.blue;
                    color.a = cast(ubyte)min(255u, 32 * outer_object_count_);

                    //draw outer.
                    driver.draw_filled_rectangle(bounds_min, bounds_max, color);

                    //grid size on screen.
                    Vector2f grid_size = Vector2f(256.0f, 256.0f) * zoom_;
                    Vector2f origin = to!(float)(bounds_.center) - 0.5f * grid_size + offset_;

                    //draw background for the grid.
                    driver.draw_filled_rectangle(origin, origin + grid_size, Color.black);

                    float cell_size = grid_size.x / grid_size_;

                    //coords of the current cell.
                    Vector2f cell_min = origin;
                    Vector2f cell_max = cell_min + Vector2f(cell_size, cell_size);
                    //draw the grid.
                    for(uint x = 0; x < grid_size_; x++)
                    {
                        for(uint y = 0; y < grid_size_; y++)
                        {
                            color.a = cast(ubyte)min(255u, 32 * object_counts_[x, y]); 
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

            private:
                //Zoom by specified number of levels.
                void zoom(float relative){zoom_ = zoom_ * pow(zoom_mult_, relative);}

                //Pan view with specified offset.
                void pan(Vector2f relative){offset_ += relative;}

                //Restore default view.
                void reset_view()
                {
                    zoom_ = 1.0;
                    offset_ = Vector2f(0.0f, 0.0f);
                }
        }

        //2D array storing object counts of cells in the grid.
        Array2D!(uint) object_counts_;
        //Object count in the "outer" cell of the GridSpatialManager (objects outside the grid).
        uint outer_object_count_;

        //Widget displaying the grid.
        GridView view_;
        //Timer used to determine when to update data from the monitored manager..
        Timer update_timer_;

        //Size of the grid (both X and Y).
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

            view_ = new GridView;
            add_child(view_);

            grid_size_ = monitored_.grid_size;
            object_counts_ = Array2D!(uint)(grid_size_, grid_size_);

            update_timer_ = Timer(0.02);
        }

        override void die()
        {
            super.die();
            object_counts_.die();
        }

    protected:
        override void update()
        {
            super.update();

            //if it's time to update, get object counts from the manager's grid.
            if(update_timer_.expired)
            {
                for(uint x = 0; x < grid_size_; x++)
                {
                    for(uint y = 0; y < grid_size_; y++)
                    {
                        object_counts_[x, y] = monitored_.grid_[x, y].objects.length;
                    }
                }
                outer_object_count_ = monitored_.outer_.objects.length;
                update_timer_.reset();
            }
        }
}

///GridSpatialManagerMonitor class - a MonitorMenu implementation is generated here.
mixin(generate_monitor_menu("GridSpatialManager$T", 
                            ["Grid"], 
                            ["GridMonitor"]));
