
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module monitor.graphmonitor;


import std.math;

import monitor.monitor;
import monitor.submonitor;
import gui.guilinegraph;
import gui.guielement;
import gui.guibutton;
import gui.guimenu;
import gui.guimousecontrollable;
import math.vector2;
import math.rectangle;
import platform.platform;
import util.signal;
import graphdata;
import color;
import stringctfe;


/**
 * Base class for system monitor style graph monitoring widgets.
 *
 * User can zoom and scroll the graph with mouse, change data point time, 
 * set average or sum mode and toggle display of monitored values.
 */
abstract class GraphMonitor : SubMonitor
{
    invariant{assert(zoom_mult_ > 1.0, "GraphMonitor zoom multiplier must be greater than 1");}

    protected:
        ///Measured graph data.
        GraphData data_;

    private:
        alias std.string.toString to_string;  
        ///Graph widget controlled by this monitor.
        GUILineGraph graph_;
        ///Buttons used to toggle display of values on the graph.
        ///Not using menu since we need to control color of each button.
        GUIButton[string] value_buttons_;
        ///Menu of buttons controlling the graph.
        GUIMenuHorizontal menu_;

        //note: in D2, this can be replaced with closures
        ///Function object used by buttons to toggle display of values.
        class Toggle
        {
            ///Name of the value to toggle.
            string name_;
            ///Construct a Toggle for value with specified name.
            this(string name){name_ = name;}
            ///Toggle display of the value.
            void toggle(){graph_.toggle_value(name_);}
        }

        ///Buttons' function objects to toggle display of values.
        Toggle[] toggles_;

        ///Default graph X scale to return to after zooming.
        float scale_x_default_;
        ///Zoom multiplier corresponding to one zoom level.
        float zoom_mult_ = 1.1;

    public:
        override void die()
        {
            data_.die();
            data_ = null;
            toggles_ = [];
            super.die();
        }

    protected:
        /**
         * Construct a GraphMonitor working on specified graph data.
         *
         * Params:  factory    = Factory used to produce the graph widget.
         *                       Derived class is responsible with adding values'
         *                       graphs to the factory.
         *          graph_data = Graph data to link the graph widget to.
         */
        this(GUILineGraphFactory factory, GraphData graph_data)
        {
            super();
            init_menu();
            data_ = graph_data;

            //construct the graph widget
            with(factory)
            {
                x = "p_left + 52";
                y = "p_top + 2";
                width = "p_width - 54";
                height = "p_height - 26";
                data = graph_data;
                graph_ = produce();
            }

            //provides zooming/panning functionality
            auto mouse_control = new GUIMouseControllable;
            mouse_control.zoom.connect(&zoom);
            mouse_control.pan.connect(&pan);
            mouse_control.reset_view.connect(&reset_view);
            graph_.add_child(mouse_control);

            add_child(graph_);

            scale_x_default_ = graph_.scale_x;
        }

        /**
         * Add a new measurement of value with specified name.
         *
         * Params:  name  = Name of the value.
         *          value = Measurement to add.
         */
        final void update_value(string name, real value){data_.update_value(name,value);}

        ///Set graph mode.
        final void mode(GraphMode graph_mode){data_.mode(graph_mode);}

        /**
         * Add a display toggling button for a value.
         *
         * Params:  name  = Name of the value toggled by the button.
         *          color = Color of the button text.
         */  
        void add_toggle(string name, Color color)
        {
            auto toggle = new Toggle(name);
            with(new GUIButtonFactory)
            {
                x = "p_left + 2";
                width = "48";
                height = "12";
                font_size = 8;
                y = "p_top + " ~ to_string(2 + 14 * value_buttons_.keys.length);
                font_size = Monitor.font_size;
                text_color(ButtonState.Normal, color);
                text = name;

                auto button = produce();
                button.pressed.connect(&(toggle.toggle));
                value_buttons_[name] = button;
                add_child(button);
            }
            toggles_ ~= toggle;
        }     

        override void update()
        {
            super.update();
            data_.update();
        }

    private:
        ///Initialize menu. 
        void init_menu()
        {
            with(new GUIMenuHorizontalFactory)
            {
                x = "p_left + 50";
                y = "p_bottom - 24";
                item_width = "48";
                item_height = "20";
                item_spacing = "2";
                item_font_size = Monitor.font_size;
                add_item ("res +", &resolution_increase);
                add_item ("res -", &resolution_decrease);
                add_item ("sum", &sum);
                add_item ("avg", &average);
                menu_ = produce();
            }
            add_child(menu_);
        }

        ///Decrease graph data point time - used by resolution + button.
        void resolution_increase(){graph_.data_point_time = graph_.data_point_time * 0.5;}

        ///Increase graph data point time - used by resolution - button.
        void resolution_decrease(){graph_.data_point_time = graph_.data_point_time * 2.0;}

        ///Set sum graph mode - used by sum button.
        void sum(){data_.mode = GraphMode.Sum;}

        ///Set average graph mode - used by average button.
        void average(){data_.mode = GraphMode.Average;}

        ///Zoom by specified number of levels.
        void zoom(float relative)
        {
            graph_.auto_scale = false;
            graph_.scale_x = graph_.scale_x * pow(zoom_mult_, relative);
            graph_.scale_y = graph_.scale_y * pow(zoom_mult_, relative); 
        }

        ///Pan view with specified offset.
        void pan(Vector2f relative){graph_.scroll(-relative.x);}

        ///Restore default view.
        void reset_view()
        {
            graph_.scale_x = scale_x_default_;
            graph_.auto_scale = true;
            graph_.auto_scroll = true;
        }
}

/**
 * Basic graph monitor template, will fetch statistics from monitored object and display them.
 *
 * Monitorable template type must have a send_statistics signal that sends
 * an object of Statistics template type. Any further template parameters
 * are strings representing data members of the Statistics object to use as 
 * graph values. At most 16 values are supported at the moment.
 *
 * Examples:
 * --------------------
 * struct Statistics
 * {
 *     int value;
 * }
 *
 * class Monitored
 * {
 *     private:
 *         Statistics statistics_;
 *
 *     public:  
 *         mixin Signal!(Statistics) send_statistics;
 *         
 *         void update()
 *         {
 *             //send statistics
 *             send_statistics.emit(statistics_);
 *             //reset statistics for next measurement
 *             statistics_.value = 0;
 *         }
 *
 *         //stuff done between updates
 *         void do_stuff(){statistics_.value++;}
 * }
 *
 * //The monitor using Monitored and Statistics types aliased for easier usage.
 * alias SimpleGraphMonitor!(Monitored, Statistics, "value") ExampleMonitor;
 * --------------------
 */
class SimpleGraphMonitor(Monitored, Statistics, Values ...) : GraphMonitor
{
    private:
        ///Palette of colors used by generated graph monitor code.
        const Color[] palette = [Color.red,
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

        ///Signal used to... disconnect from monitored objects' send_statistics signal.
        mixin Signal!(void delegate(Statistics)) disconnect_;

    public:
        ///Construct a SimpleGraphMonitor monitoring specified object.
        this(Monitored monitored)
        {
            auto factory = new GUILineGraphFactory;

            //names of values will be stored here to be passed to GraphData ctor
            string values[];
            foreach(color, value; Values)
            {
                //can't pass template parameter strings around directly, must copy them
                string v = value.dup;
                values ~= v;
                factory.graph_color(v, palette[color]);
                add_toggle(v, palette[color]);
            }
            auto data = new GraphData(values);
            super(factory, data);

            monitored.send_statistics.connect(&fetch_statistics); 
            disconnect_.connect(&monitored.send_statistics.disconnect);
        }

        override void die()
        {
            disconnect_.emit(&fetch_statistics);
            disconnect_.disconnect_all();
            super.die();
        }

    private:
        ///Called by monitored object to pass statistics gathered.
        void fetch_statistics(Statistics statistics)
        {
            ///Generate code to update graph values at compile time.
            string update_values()
            {
                string result;
                foreach(value; Values)
                {
                    result ~= "data_.update_value(\"" ~ value ~ "\", statistics." ~ value ~ ");\n";
                }
                return result;
            }

            mixin(update_values());
        }
}
