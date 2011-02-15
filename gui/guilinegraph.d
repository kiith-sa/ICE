
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module gui.guilinegraph;


import std.math;
import std.string;

import video.videodriver;
import math.math;
import math.vector2;
import gui.guielement;
import graphdata;
import time.time;
import time.timer;
import color;
import util.factory;     
import containers.vector;

/**
 * Line graph widget, showing graphs for multiple changing values system monitor style.
 *
 * The graph data is managed by a GraphData instance, GUILineGraph only handles display.
 */
final class GUILineGraph : GUIElement
{
    invariant
    {
        assert(data_point_time_ > 0.0, "Graph data point time period must be more than 0");
        assert(scale_x_ > 0.0, "Graph X scale must be more than 0");
        assert(scale_y_ > 0.0, "Graph Y scale must be more than 0");
    }

    private:
        ///Stores data used to display graph of one value.
        static class GraphDisplay
        {
            ///Is this graph visible?.
            bool visible = true;
            ///Color of the graph.
            Color color = Color.grey;
            ///Vertices of the line strip used to display the graph, in screen space.
            Vector!(Vector2f) line_strip;

            ///Construct a GraphDisplay.
            this(){line_strip = Vector!(Vector2f)();}
            ///Destroy this GraphDisplay.
            void die(){line_strip.die();}
        }

        ///Horizontal line on the graph, shown for visual comparison with graph values.
        static align(1) struct Line
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
        ///If true, the graph is automatically scrolled as new data is added.
        bool auto_scroll_ = true;
        ///If true, graph is automatically scaled on Y axis according to the highest value.
        bool auto_scale_ = true;

        ///Display data for graph of every value.
        GraphDisplay[string] graphics_;
        ///Horizontal lines on the graph, shown for visual comparison with graph values.
        Line[] lines_;
        ///Font size used for numbers describing values represented by the lines.
        uint font_size_ = 8;

        ///Time difference between two data points displayed on the graph, in seconds,
        real data_point_time_ = 1.0;
        ///Timer used to time graph display updates.
        Timer display_timer_;

    public:
        ///Set time difference between two graph data points.
        void data_point_time(real time)
        {
            aligned_ = false;
            //limiting to prevent absurd values
            data_point_time_ = clamp(time, data_.time_resolution, 64.0L);
        }

        ///Return time between two graph data points.
        real data_point_time(){return data_point_time_;}

        ///Toggle visibility of graph of specified value.
        void toggle_value(string value)
        {
            auto graphics = graphics_[value];
            graphics.visible = !graphics.visible;
        }

        ///If true, Y axis of the graph will be scaled automatically according to highest value.
        void auto_scale(bool scale){aligned_ = false; auto_scale_ = scale;}

        ///If true, the graph will automatically scroll to show newest data.
        void auto_scroll(bool scroll){aligned_ = false; auto_scroll_ = scroll;}

        ///Set time offset of the graph. Used for manual scrolling.
        void time_offset(float offset)
        {
            aligned_ = false; 
            //limiting to prevent absurd values
            time_offset_ = clamp(cast(real)offset, 0.0L, age());
        }

        /**
         * Manually scroll the graph horizontally.
         *
         * Disables automatic scrolling, if enabled.
         *
         * Params:  offset = Screen space offset relative the start of graph.
         */
        void scroll(float offset)
        {
            auto_scroll = false;

            //convert time offset to screen space, modify it and convert back to time.
            float conv = data_point_time_ / scale_x;
            float space_offset = time_offset_ / conv + offset;
            time_offset(space_offset * conv);
        }

        ///Get X scale of the graph.
        float scale_x(){return scale_x_;}
        ///Set X scale of the graph. Used for manual zooming.
        void scale_x(float scale_x){aligned_ = false; scale_x_ = clamp(scale_x, 0.01f, 200.0f);}

        ///Get Y scale of the graph. 
        float scale_y(){return scale_y_;}
        ///Set Y scale of the graph. Used for manual zooming.
        void scale_y(float scale_y){aligned_ = false; scale_y_ = clamp(scale_y, 0.0005f, 10.0f);}

        ///Set font size of the graph.
        void font_size(uint size){font_size_ = size;}

        ///Destroy this GUILineGraph.
        void die()
        {
            foreach(display; graphics_.values){display.die();}
            super.die();
        }

    protected:
        /**
         * Construct a GUILineGraph with specified parameters.
         *
         * Params:  params = Parameters for GUIElement constructor.
         *          colors = Colors of graphs of measured values.
         *          data   = Reference to GraphData to display.
         *                   GUILineGraph just displays the GraphData, it doesn't manage it.
         */
        this(GUIElementParams params, Color[string] colors, GraphData data)
        {
            super(params);

            data_ = data;
            reset_timer(get_time());
            foreach(name, color; colors)
            {
                graphics_[name] = new GraphDisplay;
                graphics_[name].color = color;
            }
        }

        override void update()
        {
            super.update();

            real time = get_time();
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

            foreach(graph; data_.graph_names){draw_graph(driver, graph);}
            draw_info(driver);
        }

        override void realign(VideoDriver driver)
        {
            super.realign(driver);
            update_view();
        }

    private:
        ///Resets update timer according to data point time, starting at specified time.
        void reset_timer(real time)
        {
            //limiting to prevent absurd values (and lag)
            display_timer_ = Timer(clamp(data_point_time_, 0.125L, 8.0L), time);
        }

        ///Returns age of this graph at last display timer reset.
        real age(){return display_timer_.start - data_.start_time;}

        ///Update graph display data such as graph line strips.
        void update_view()
        {
            if(auto_scroll_){time_offset_ = age();}

            real maximum;
            real[][string] data_points = get_data_points_and_maximum(maximum);

            if(auto_scale_)
            {
                if(!equals(maximum, 0.0L)){scale_y = (bounds_.height * 0.8) / maximum;}
            }

            update_lines();

            //generate line strips
            foreach(name; data_.graph_names)
            {
                auto points = data_points[name];
                auto graphics = graphics_[name];

                //clearn the strip
                graphics.line_strip.length = 0;
                if(data_.empty(name)){continue;}

                float x = bounds_.max.x - scale_x_ * (points.length - 1);
                x += data_.delay(name) * scale_x_;
                float y = bounds_.max.y;

                foreach(real point; points)
                {
                    graphics.line_strip ~= Vector2f(x, y - point * scale_y);
                    x += scale_x_;
                }
            }
        }

        /*
         * Gets data points to draw from graph of each value, and a maximum of all data points.
         * 
         * Officially the worst named method in this entire project.
         * Used by update_view.
         *
         * Params:  maximum = Maximum of all data points will be written here.
         *
         * Returns: Data points of every graph in an associative array indexed by graph name.
         */
        real[][string] get_data_points_and_maximum(out real maximum)
        {
            //calculate the time window we want to get data points for
            //why +3 : get a few more points so the graph is always full if there's enough data
            real time_width = (bounds_.width / scale_x_ + 3) * data_point_time_;

            real end_time = data_.start_time + time_offset_;
            real start_time = end_time - time_width;

            maximum = 0.0;
            real[][string] data_points;

            //getting all data points and the maximum
            foreach(name; data_.graph_names)
            {
                real[] points = data_.data_points(name, start_time, end_time, data_point_time_);

                data_points[name] = points;
                if(points.length <= 1){continue;}

                real graph_maximum = max(points);
                if(graph_maximum > maximum){maximum = graph_maximum;}
            }

            return data_points;
        }

        ///Update the horizontal lines of the graph.
        void update_lines()
        {
            lines_.length = 0;

            real graph_height = bounds_.height / scale_y_;
            uint spacing = cast(uint)pow(cast(real)10.0, cast(uint)log10(graph_height));
            if(spacing == 0){spacing = 1;}

            //always have at least two horizontal lines.
            if(graph_height / spacing < 2){spacing /= 2;}

            uint line_height = 0;

            Line line;
            do
            {
                line.y = bounds_.max.y - scale_y_ * line_height;
                line.text = to_string(line_height);
                line.color = Color(255, 128, 0, 192);
                lines_ ~= line;

                line_height += spacing;
            }
            while(line_height <= graph_height)
        }

        /**
         * Draw specified graph.
         *
         * Params:  driver = Video driver to draw with.
         *          name   = Name of the graph to draw.
         */
        void draw_graph(VideoDriver driver, string name)
        {
            auto graphics = graphics_[name];

            if(!graphics.visible || graphics.line_strip.length <= 1){return;}

            //Use scissor test to only draw within bounds of the graph.
            driver.scissor(bounds_);
            driver.line_aa = true;
            driver.line_width = 0.65;

            driver.draw_line_strip(graphics.line_strip.array, graphics.color);

            driver.line_width = 1;                  
            driver.line_aa = false;
            driver.disable_scissor();
        }

        /**
         * Draw graph related information, e.g. the horizontal lines and data point time.
         *
         * Params:  driver = VideoDriver to draw with.
         */
        void draw_info(VideoDriver driver)
        {
            static data_time_color = Color(255, 0, 0, 192);
            static data_time_offset = Vector2i(-32, 4);

            Vector2f start;
            start.x = bounds_.min.x;
            Vector2f end;
            end.x = bounds_.max.x;
            Vector2i text_start;
            text_start.x = bounds_.min.x;

            driver.font = "default";
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
                             to_string(data_point_time_) ~ "s", data_time_color);

            driver.disable_scissor();
        }
}

/**
 * Factory used for line graph construction.
 *
 * See_Also: GUIElementFactoryBase
 *
 * Params:  data        = Graph data to display. Must be specified.
 *          graph_color = Set color for graph of measured value with specified name.
 */
final class GUILineGraphFactory : GUIElementFactoryBase!(GUILineGraph)
{
    private:
        mixin(generate_factory("GraphData $ data $ null"));
        ///Name and color of graph for each value.
        Color[string] graphs_;
    public:
        void graph_color(string name, Color color){graphs_[name] = color;}

        ///Produce a GUILineGraph with parameters of the factory.
        GUILineGraph produce()
        in{assert(data_ !is null, "GUI line graph needs to be linked to graph data");}
        body{return new GUILineGraph(gui_element_params, graphs_, data_);}
}
