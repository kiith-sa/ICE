
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Monitor viewing the grid spatial manager.
module spatial.gridmonitor;


import std.algorithm;
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
        GridSpatialManager!T monitored_;

        ///Object counts of cells in the grid.
        Array2D!uint objectCounts_;
        ///Objects in the "outer" cell of the GridSpatialManager (objects outside the grid).
        uint outerObjectCount_;

        ///Timer used to determine when to update data from the monitored manager.
        Timer updateTimer_;

        ///Size of the grid (both X and Y).
        const uint gridSize_;

    public:
        /**
         * Construct a GridMonitor.
         *
         * Params:  monitored = GridSpatialManager to monitor.
         */
        this(GridSpatialManager!T monitored)
        {
            super();

            monitored_     = monitored;
            gridSize_     = monitored_.gridSize;
            objectCounts_ = Array2D!uint(gridSize_, gridSize_);

            updateTimer_ = Timer(0.02);
        }

        ~this(){clear(objectCounts_);}

        @property override SubMonitorView view()
        {
            return new GridMonitorView!(typeof(this))(this);
        }

    package:
        ///Update monitored data.
        void update()
        {
            //Using timer to prevent updating every frame.
            if(updateTimer_.expired)
            {
                foreach(x; 0 .. gridSize_) foreach(y; 0 .. gridSize_)
                {
                    objectCounts_[x, y] = cast(uint)monitored_.grid_[x, y].objects.length;
                }
                outerObjectCount_ = cast(uint)monitored_.outer_.objects.length;
                updateTimer_.reset();
            }
        }

        ///Get number of objects outside the grid.
        @property uint outerObjectCount() const pure {return outerObjectCount_;}

        ///Get (x and y) grid size in cells.
        @property uint gridSize() const pure {return gridSize_;}

        ///Get a pointer to the array of object counts in the grid. 
        @property const(Array2D!uint*) objectCounts() const pure {return &objectCounts_;} 
}

///Grid monitor GUI view.
final package class GridMonitorView(GridMonitor) : SubMonitorView
{
    private:
        ///GridMonitor viewed.
        GridMonitor monitor_;

        ///Provides mouse zooming and panning.
        mixin MouseControl!1.1 mouse_;

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

            const bounds = main_.boundsGlobal();

            //convert bounds to float for drawing and slightly cut them to
            //prevent overdrawing border.
            const boundsMin = bounds.min.to!float + Vector2f(0.0f, 1.0f);
            const boundsMax = bounds.max.to!float + Vector2f(-1.0f, 0.0f); 

            //prevent drawing outside bounds.
            driver.scissor(Rectanglei(boundsMin.to!int, boundsMax.to!int));

            //draw background.
            driver.drawFilledRectangle(boundsMin, boundsMax, Color.black);
            //Color of the current cell
            Color color = Color.blue;
            color.a = cast(ubyte)min(255u, 32 * monitor_.outerObjectCount);

            //draw outer.
            driver.drawFilledRectangle(boundsMin, boundsMax, color);

            //grid size on screen.
            const gridSize = Vector2f(256.0f, 256.0f) * zoom_;
            const origin = bounds_.center.to!float - 0.5f * gridSize + offset_;

            //draw background for the grid.
            driver.drawFilledRectangle(origin, origin + gridSize, Color.black);

            const float cellSize = gridSize.x / monitor_.gridSize;

            //coords of the current cell.
            Vector2f cellMin = origin;
            Vector2f cellMax = cellMin + Vector2f(cellSize, cellSize);
            //draw the grid.
            foreach(x; 0 .. monitor_.gridSize_)
            {
                foreach(y; 0 .. monitor_.gridSize_)
                {
                    color.a = cast(ubyte)min(255u, 32 * (*monitor_.objectCounts)[x, y]); 
                    driver.drawFilledRectangle(cellMin, cellMax, color);

                    cellMin.y += cellSize;
                    cellMax.y += cellSize;
                }
                cellMin.y = origin.y;
                cellMax.y = cellMin.y + cellSize;
                cellMin.x += cellSize;
                cellMax.x += cellSize;
            }

            driver.disableScissor();
        }
}
