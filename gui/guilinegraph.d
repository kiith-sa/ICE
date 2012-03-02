
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Line graph (like system monitor) widget.
module gui.guilinegraph;


import std.algorithm;
import std.array;
import std.math;
import std.conv;
import std.range;

import video.videodriver;
import math.math;
import math.vector2;
import gui.guielement;
import graphdata;
import time.time;
import time.timer;
import containers.vector;
import util.factory;     
import color;


/**
 * Line graph widget, showing graphs for multiple changing values system monitor style.
 *
 * The graph data is managed by a GraphData instance, GUILineGraph only handles display.
 */
final class GUILineGraph : GUIElement
{
    invariant()
    {
        assert(dataPointTime_ > 0.0, "Graph data point time period must be more than 0");
        assert(scaleX_ > 0.0, "Graph X scale must be more than 0");
        assert(scaleY_ > 0.0, "Graph Y scale must be more than 0");
    }

    private:
        alias std.conv.to to;

        ///Stores data used to display graph of one value.
        static class GraphDisplay
        {
            ///Is this graph visible?.
            bool visible = true;
            ///Color of the graph.
            Color color;
            ///Vertices of the line strip used to display the graph, in screen space.
            Vector!Vector2f lineStrip;

            ///Construct a GraphDisplay.
            this(){lineStrip.reserve(8);}
        }

        ///Horizontal line on the graph, shown for visual comparison with graph values.
        static struct Line
        {
            ///Info text of the line (i.e. number represented by the line).
            string text;
            ///Color of the line and its text.
            Color color;
            ///Y coordinate the line is at, in screen space.
            float y;
        }

        ///Graph data we're displaying.
        GraphData data_;
        ///Graph mode (average per measurement or sums over time). 
        GraphMode mode_ = GraphMode.Average;

        /**
         * Time offset of the graph view, used for scrolling.
         *
         * This is time since start of graph to time of the leftmost data point of graph.
         */
        float timeOffset_ = 0.0;
        ///Distance between two data points on X axis.
        float scaleX_ = 2.0;
        ///Distance between values differing by 1, e.g. 1.0 and 0.0 on Y axis.
        float scaleY_ = 0.1;
        ///If true, the graph automatically scrolls as new data is added.
        bool autoScroll_ = true;
        ///If true, graph is automatically scaled on Y axis according to the highest value.
        bool autoScale_ = true;

        ///Display data for graph of each value.
        GraphDisplay[] graphics_;
        ///Horizontal lines on the graph, shown for visual comparison with graph values.
        Line[] lines_;
        ///Font size used for numbers describing values represented by the lines.
        uint fontSize_ = 8;

        ///Seconds between two data points displayed on the graph.
        real dataPointTime_ = 1.0;
        ///Timer used to time graph display updates.
        Timer displayTimer_;

    public:
        ///Get color of graph with specified index.
        @property Color graphColor(size_t idx) const
        {
            return graphics_[idx].color;
        }

        ///Set time difference between two graph data points in seconds.
        @property void dataPointTime(real time)
        {
            aligned_ = false;
            //limiting to prevent absurd values
            dataPointTime_ = clamp(time, data_.timeResolution, 64.0L);
        }
        ///Get time between two graph data points.
        @property real dataPointTime() const {return dataPointTime_;}

        ///Toggle visibility of graph of specified value.
        void toggleGraphVisibility(in size_t value)
        {
            graphics_[value].visible = !graphics_[value].visible;
        }

        ///If true, Y axis of the graph will be scaled automatically according to highest value.
        @property void autoScale(in bool scale){aligned_ = false; autoScale_ = scale;}

        ///If true, the graph will automatically scroll to show newest data.
        @property void autoScroll(in bool scroll){aligned_ = false; autoScroll_ = scroll;}

        ///Set time offset of the graph. Used for manual scrolling.
        @property void timeOffset(in float offset)
        {
            aligned_ = false; 
            //limiting to prevent absurd values
            timeOffset_ = clamp(cast(real)offset, 0.0L, age());
        }

        /**
         * Manually scroll the graph horizontally.
         *
         * Disables automatic scrolling.
         *
         * Params:  offset = Screen space offset relative the start of graph.
         */
        void scroll(in float offset)
        {
            autoScroll = false;

            //convert time offset to screen space, modify it and convert back to time.
            const conv         = dataPointTime_ / scaleX;
            const spaceOffset = timeOffset_ / conv + offset;
            timeOffset(spaceOffset * conv);
        }

        ///Get X scale of the graph.
        @property float scaleX() const {return scaleX_;}
        ///Set X scale of the graph. Used for manual zooming.
        @property void scaleX(float scaleX)
        {
            aligned_ = false; 
            scaleX_ = clamp(scaleX, 0.01f, 200.0f);
        }

        ///Get Y scale of the graph. 
        @property float scaleY() const {return scaleY_;}
        ///Set Y scale of the graph. Used for manual zooming.
        @property void scaleY(float scaleY)
        {
            aligned_ = false; 
            scaleY_ = clamp(scaleY, 0.0005f, 10.0f);
        }

        ///Set font size of the graph.
        @property void fontSize(in uint size){fontSize_ = size;}

        ///Set graph mode (data points are average per measurement or sums over time).
        @property void graphMode(in GraphMode mode){mode_ = mode;}

        ~this()
        {
            foreach(display; graphics_){clear(display);}
            clear(graphics_);
            clear(lines_);
        }

    protected:
        /**
         * Construct a GUILineGraph.
         *
         * Params:  params = Parameters for GUIElement constructor.
         *          colors = Colors of graphs displayed.
         *          data   = Reference to GraphData to display.
         *                   GUILineGraph just displays the GraphData, it doesn't manage it.
         */
        this(in GUIElementParams params, in Color[] colors, GraphData data)
        {
            super(params);

            data_ = data;
            resetTimer(getTime());
            foreach(color; colors)
            {
                graphics_ ~= new GraphDisplay;
                graphics_[$ - 1].color = color;
            }
        }

        override void update()
        {
            super.update();

            const time = getTime();
            //time to update display
            if(displayTimer_.expired(time))
            {
                updateView();
                resetTimer(time);
            }
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            super.draw(driver);

            foreach(graph; 0 .. data_.graphs.length){drawGraph(driver, graph);}
            drawInfo(driver);
        }

        override void realign(VideoDriver driver)
        {
            super.realign(driver);
            updateView();
        }

    private:
        ///Resets update timer according to data point time, starting at specified time.
        void resetTimer(in real time)
        {
            //limiting to prevent absurd values (and lag)
            displayTimer_ = Timer(clamp(dataPointTime_, 0.125L, 8.0L), time);
        }

        ///Returns age of this graph in seconds at last display timer reset.
        @property real age() const {return displayTimer_.start - data_.startTime;}

        ///Update graph display data such as graph line strips.
        void updateView()
        {
            if(autoScroll_){timeOffset_ = age();}

            real maximum;
            const dataPoints = getDataPointsAndMaximum(maximum);

            if(autoScale_ && !equals(maximum, 0.0L))
            {
                //only use 80% of total height.
                scaleY = (bounds_.height * 0.8) / maximum;
            }

            updateLines();

            //generate line strips for each graph
            foreach(idx, points, graphics; 
                    lockstep(iota(data_.graphs.length), dataPoints, graphics_))
            {
                //clear the strip
                graphics.lineStrip.length = 0;
                if(data_.graphs[idx].empty){continue;}

                float x = bounds_.max.x - scaleX_ * (points.length - 1);
                const float y = bounds_.max.y;

                //Skip data points if too many.
                const skip = max(1, points.length / (bounds_.width * 4));

                foreach(point; stride(points, skip))
                {
                    graphics.lineStrip ~= Vector2f(x, y - point * scaleY);
                    x += scaleX_ * skip;
                }
            }
        }

        /*
         * Gets data points to draw from graph of each value, and a maximum of all data points.
         * 
         * Officially the worst named method in this project.
         * Used by updateView.
         *
         * Params:  maximum = Maximum of all data points will be written here.
         *
         * Returns: Data points of every graph in an associative array indexed by graph name.
         */
        const(real[][]) getDataPointsAndMaximum(out real maximum)
        {
            //calculate the time window we want to get data points for
            //why +3 : get a few more points so the graph is always full if there's enough data
            const timeWidth = (bounds_.width / scaleX_ + 3) * dataPointTime_;
            const endTime   = data_.startTime + timeOffset_;
            const startTime = endTime - timeWidth;

            maximum = 0.0;
            const(real)[][] dataPoints;

            //getting all data points and the maximum
            foreach(idx; 0 .. data_.graphs.length)
            {
                auto points = data_.graphs[idx].dataPoints(startTime, endTime, 
                                                            dataPointTime_, mode_); 
                dataPoints ~= points;
                if(points.length <= 1){continue;}
                maximum = max(maximum, reduce!max(points));
            }

            return dataPoints;
        }

        ///Update the horizontal lines of the graph.
        void updateLines()
        {
            lines_.length = 0;

            const real graphHeight = bounds_.height / scaleY_;
            uint spacing = max(1, cast(uint)pow(10.0L, cast(uint)log10(graphHeight)));
            //always have at least two horizontal lines.
            if(graphHeight / spacing < 2){spacing /= 2;}

            uint lineHeight = 0;

            Line line;
            do
            {
                line.y     = bounds_.max.y - scaleY_ * lineHeight;
                line.text  = to!string(lineHeight);
                line.color = rgba!"FF8000C0";
                lines_ ~= line;

                lineHeight += spacing;
            }
            while(lineHeight <= graphHeight);
        }

        /**
         * Draw specified graph.
         *
         * Params:  driver = Video driver to draw with.
         *          idx    = Index of the graph to draw.
         */
        void drawGraph(VideoDriver driver, in size_t idx) const
        {
            const graphics = graphics_[idx];

            if(!graphics.visible || graphics.lineStrip.length <= 1){return;}

            //Use scissor test to only draw within bounds of the graph.
            driver.scissor(bounds_);
            driver.lineAA    = true;
            driver.lineWidth = 0.65;

            driver.drawLineStrip((graphics.lineStrip)[], graphics.color);

            driver.lineWidth = 1;                  
            driver.lineAA    = false;
            driver.disableScissor();
        }

        /**
         * Draw graph related information, e.g. the horizontal lines and data point time.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void drawInfo(VideoDriver driver) const
        {
            immutable dataTimeColor  = rgba!"FF0000C0";
            immutable dataTimeOffset = Vector2i(-32, 4);

            Vector2f start, end;
            start.x = bounds_.min.x;
            end.x   = bounds_.max.x;

            Vector2i textStart;
            textStart.x = bounds_.min.x;

            driver.font      = "default";
            driver.fontSize = 8;
            driver.scissor(bounds_);

            //lines
            foreach(ref line; lines_)
            {
                start.y = end.y = line.y;
                textStart.y = cast(int)line.y;
                driver.drawLine(start, end, line.color, line.color);
                driver.drawText(textStart, line.text, line.color);
            }

            //data point time
            driver.drawText(bounds_.maxMin() + dataTimeOffset,
                             to!string(dataPointTime_) ~ "s", dataTimeColor);

            driver.disableScissor();
        }
}

/**
 * Factory used for line graph construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  graphColors = Colors of graphs (length must be equal to number of graphs.)
 */
final class GUILineGraphFactory : GUIElementFactoryBase!GUILineGraph
{
    private:
        ///Palette of colors used by generated graph monitor code.
        static Color[] palette = [rgb!"FF0000", rgb!"00FF00", rgb!"0000FF",
                                  rgb!"FFFF00", rgb!"00FFFF", rgb!"FF00FF",
                                  rgb!"800000", rgb!"008000", rgb!"000080",
                                  rgb!"808000", rgb!"008080", rgb!"800080"];

        ///GraphData to display.
        GraphData data_;

        ///Color of graph for each value.
        Color[] graphColors_;

    public:
        ///Construct a factory to produce a GUILineGraph displaying specified GraphData.
        this(GraphData data)
        {
            data_ = data;
            if(data_.graphs.length > palette.length)
            {
                foreach(c; 0 .. data_.graphs.length){graphColors_ ~= Color.randomRGB();}
                return;
            }
            graphColors_ = palette[0 .. data_.graphs.length];
        }

        void graphColors(Color[] colors)
        in
        {
            assert(colors.length == data_.graphs.length);
        }
        body
        {
            graphColors_ = colors;
        }

        ///Produce a GUILineGraph with parameters of the factory.
        override GUILineGraph produce()
        body{return new GUILineGraph(guiElementParams, graphColors_, data_);}
}
