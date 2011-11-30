
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Line graph (like system monitor) widget.
module gui.guilinegraph;
@safe


import std.algorithm;
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
        assert(data_point_time_ > 0.0, "Graph data point time period must be more than 0");
        assert(scale_x_ > 0.0, "Graph X scale must be more than 0");
        assert(scale_y_ > 0.0, "Graph Y scale must be more than 0");
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
            Vector!Vector2f line_strip;

            ///Construct a GraphDisplay.
            this(){line_strip.reserve(8);}
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
        float time_offset_ = 0.0;
        ///Distance between two data points on X axis.
        float scale_x_ = 2.0;
        ///Distance between values differing by 1, e.g. 1.0 and 0.0 on Y axis.
        float scale_y_ = 0.1;
        ///If true, the graph automatically scrolls as new data is added.
        bool auto_scroll_ = true;
        ///If true, graph is automatically scaled on Y axis according to the highest value.
        bool auto_scale_ = true;

        ///Display data for graph of each value.
        GraphDisplay[] graphics_;
        ///Horizontal lines on the graph, shown for visual comparison with graph values.
        Line[] lines_;
        ///Font size used for numbers describing values represented by the lines.
        uint font_size_ = 8;

        ///Seconds between two data points displayed on the graph.
        real data_point_time_ = 1.0;
        ///Timer used to time graph display updates.
        Timer display_timer_;

    public:
        ///Get color of graph with specified index.
        @property Color graph_color(size_t idx) const
        {
            return graphics_[idx].color;
        }

        ///Set time difference between two graph data points in seconds.
        @property void data_point_time(real time)
        {
            aligned_ = false;
            //limiting to prevent absurd values
            data_point_time_ = clamp(time, data_.time_resolution, 64.0L);
        }
        ///Get time between two graph data points.
        @property real data_point_time() const {return data_point_time_;}

        ///Toggle visibility of graph of specified value.
        void toggle_graph_visibility(in size_t value)
        {
            graphics_[value].visible = !graphics_[value].visible;
        }

        ///If true, Y axis of the graph will be scaled automatically according to highest value.
        @property void auto_scale(in bool scale){aligned_ = false; auto_scale_ = scale;}

        ///If true, the graph will automatically scroll to show newest data.
        @property void auto_scroll(in bool scroll){aligned_ = false; auto_scroll_ = scroll;}

        ///Set time offset of the graph. Used for manual scrolling.
        @property void time_offset(in float offset)
        {
            aligned_ = false; 
            //limiting to prevent absurd values
            time_offset_ = clamp(cast(real)offset, 0.0L, age());
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
            auto_scroll = false;

            //convert time offset to screen space, modify it and convert back to time.
            const conv         = data_point_time_ / scale_x;
            const space_offset = time_offset_ / conv + offset;
            time_offset(space_offset * conv);
        }

        ///Get X scale of the graph.
        @property float scale_x() const {return scale_x_;}
        ///Set X scale of the graph. Used for manual zooming.
        @property void scale_x(float scale_x)
        {
            aligned_ = false; 
            scale_x_ = clamp(scale_x, 0.01f, 200.0f);
        }

        ///Get Y scale of the graph. 
        @property float scale_y() const {return scale_y_;}
        ///Set Y scale of the graph. Used for manual zooming.
        @property void scale_y(float scale_y)
        {
            aligned_ = false; 
            scale_y_ = clamp(scale_y, 0.0005f, 10.0f);
        }

        ///Set font size of the graph.
        @property void font_size(in uint size){font_size_ = size;}

        ///Set graph mode (data points are average per measurement or sums over time).
        @property void graph_mode(in GraphMode mode){mode_ = mode;}

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
            reset_timer(get_time());
            foreach(color; colors)
            {
                graphics_ ~= new GraphDisplay;
                graphics_[$ - 1].color = color;
            }
        }

        override void update()
        {
            super.update();

            const time = get_time();
            //time to update display
            if(display_timer_.expired(time))
            {
                update_view();
                reset_timer(time);
            }
        }

        override void draw(VideoDriver driver)
        {
            if(!visible_){return;}

            super.draw(driver);

            foreach(graph; 0 .. data_.graph_count){draw_graph(driver, graph);}
            draw_info(driver);
        }

        override void realign(VideoDriver driver)
        {
            super.realign(driver);
            update_view();
        }

    private:
        ///Resets update timer according to data point time, starting at specified time.
        void reset_timer(in real time)
        {
            //limiting to prevent absurd values (and lag)
            display_timer_ = Timer(clamp(data_point_time_, 0.125L, 8.0L), time);
        }

        ///Returns age of this graph in seconds at last display timer reset.
        @property real age() const {return display_timer_.start - data_.start_time;}

        ///Update graph display data such as graph line strips.
        void update_view()
        {
            if(auto_scroll_){time_offset_ = age();}

            real maximum;
            const data_points = get_data_points_and_maximum(maximum);

            if(auto_scale_ && !equals(maximum, 0.0L))
            {
                //only use 80% of total height.
                scale_y = (bounds_.height * 0.8) / maximum;
            }

            update_lines();

            //generate line strips for each graph
            foreach(idx, points, graphics; 
                    lockstep(iota(data_.graph_count), data_points, graphics_))
            {
                //clear the strip
                graphics.line_strip.length = 0;
                if(data_.empty(idx)){continue;}

                float x = bounds_.max.x - scale_x_ * (points.length - 1);
                x += data_.delay(idx) * scale_x_;
                const float y = bounds_.max.y;

                foreach(point; points)
                {
                    graphics.line_strip ~= Vector2f(x, y - point * scale_y);
                    x += scale_x_;
                }
            }
        }

        /*
         * Gets data points to draw from graph of each value, and a maximum of all data points.
         * 
         * Officially the worst named method in this project.
         * Used by update_view.
         *
         * Params:  maximum = Maximum of all data points will be written here.
         *
         * Returns: Data points of every graph in an associative array indexed by graph name.
         */
        const(real[][]) get_data_points_and_maximum(out real maximum)
        {
            //calculate the time window we want to get data points for
            //why +3 : get a few more points so the graph is always full if there's enough data
            const time_width = (bounds_.width / scale_x_ + 3) * data_point_time_;
            const end_time   = data_.start_time + time_offset_;
            const start_time = end_time - time_width;

            maximum = 0.0;
            const(real)[][] data_points;

            //getting all data points and the maximum
            foreach(idx; 0 .. data_.graph_count)
            {
                auto points = data_.data_points(idx, start_time, end_time, data_point_time_, mode_); 
                data_points ~= points;
                if(points.length <= 1){continue;}
                maximum = max(maximum, reduce!max(points));
            }

            return data_points;
        }

        ///Update the horizontal lines of the graph.
        void update_lines()
        {
            lines_.length = 0;

            const real graph_height = bounds_.height / scale_y_;
            uint spacing = max(1, cast(uint)pow(10.0L, cast(uint)log10(graph_height)));
            //always have at least two horizontal lines.
            if(graph_height / spacing < 2){spacing /= 2;}

            uint line_height = 0;

            Line line;
            do
            {
                line.y     = bounds_.max.y - scale_y_ * line_height;
                line.text  = to!string(line_height);
                line.color = Color(255, 128, 0, 192);
                lines_ ~= line;

                line_height += spacing;
            }
            while(line_height <= graph_height);
        }

        /**
         * Draw specified graph.
         *
         * Params:  driver = Video driver to draw with.
         *          idx    = Index of the graph to draw.
         */
        void draw_graph(VideoDriver driver, in size_t idx) const
        {
            const graphics = graphics_[idx];

            if(!graphics.visible || graphics.line_strip.length <= 1){return;}

            //Use scissor test to only draw within bounds of the graph.
            driver.scissor(bounds_);
            driver.line_aa    = true;
            driver.line_width = 0.65;

            driver.draw_line_strip((graphics.line_strip)[], graphics.color);

            driver.line_width = 1;                  
            driver.line_aa    = false;
            driver.disable_scissor();
        }

        /**
         * Draw graph related information, e.g. the horizontal lines and data point time.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw_info(VideoDriver driver) const
        {
            immutable data_time_color  = Color(255, 0, 0, 192);
            immutable data_time_offset = Vector2i(-32, 4);

            Vector2f start, end;
            start.x = bounds_.min.x;
            end.x   = bounds_.max.x;

            Vector2i text_start;
            text_start.x = bounds_.min.x;

            driver.font      = "default";
            driver.font_size = 8;
            driver.scissor(bounds_);

            //lines
            foreach(ref line; lines_)
            {
                start.y = end.y = line.y;
                text_start.y = cast(int)line.y;
                driver.draw_line(start, end, line.color, line.color);
                driver.draw_text(text_start, line.text, line.color);
            }

            //data point time
            driver.draw_text(bounds_.max_min() + data_time_offset,
                             to!string(data_point_time_) ~ "s", data_time_color);

            driver.disable_scissor();
        }
}

/**
 * Factory used for line graph construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  graph_colors = Colors of graphs (length must be equal to number of graphs.)
 */
final class GUILineGraphFactory : GUIElementFactoryBase!GUILineGraph
{
    private:
        ///Palette of colors used by generated graph monitor code.
        static Color[] palette = [Color.red,
                                  Color.green,
                                  Color.blue,
                                  Color.yellow,
                                  Color.cyan,
                                  Color.magenta,
                                  Color.burgundy,
                                  Color(0, 128, 0, 255),
                                  Color(0, 0, 128, 255),
                                  Color.forest_green,
                                  Color(0, 128, 128, 255),
                                  Color.dark_purple];

        ///GraphData to display.
        GraphData data_;

        ///Color of graph for each value.
        Color[] graph_colors_;

    public:
        ///Construct a factory to produce a GUILineGraph displaying specified GraphData.
        this(GraphData data)
        {
            data_ = data;
            if(data_.graph_count > palette.length)
            {
                foreach(c; 0 .. data_.graph_count)
                {
                    graph_colors_ ~= Color.random_rgb();
                }
                return;
            }
            graph_colors_ = palette[0 .. data_.graph_count];
        }

        void graph_colors(Color[] colors)
        in
        {
            assert(colors.length == data_.graph_count);
        }
        body
        {
            graph_colors_ = colors;
        }

        ///Produce a GUILineGraph with parameters of the factory.
        override GUILineGraph produce()
        body{return new GUILineGraph(gui_element_params, graph_colors_, data_);}
}
