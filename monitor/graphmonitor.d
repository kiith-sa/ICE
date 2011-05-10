
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for graph (system monitor style) monitors.
module monitor.graphmonitor;
@safe


import std.math;

import monitor.monitormanager;
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


/**
 * Create and return a reference to a graph monitor with specified parameters.
 *
 * Params:  Monitored  = Type of monitored object. Must have a send_statistics 
 *                       signal that passes a Statistics struct.
 *          Statistics = Struct used by the Monitorable to send statistics to 
 *                       the GraphMonitor.
 *          Values     = Strings specifying names of values measured. Must
 *                       correspond with public data members of Statistics.
 *  
 * Examples:
 * --------------------
 * struct StatisticsExample
 * {
 *     int a;
 *     int b;
 * }
 *
 * class MonitoredExample
 * {
 *     private:
 *         StatisticsExample statistics_;
 *
 *     public:  
 *         mixin Signal!(StatisticsExample) send_statistics;
 *         
 *         void update()
 *         {
 *             //send statistics
 *             send_statistics.emit(statistics_);
 *             //reset statistics for next measurement
 *             statistics_.a = statistics_.b = 0;
 *         }
 *
 *         //stuff done between updates
 *         void do_stuff(){statistics_.a++;}
 *         void do_something_else(){statistics_.b++;}
 *         
 *         SubMonitor monitor()
 *         {
 *             //get a graph monitor monitoring this object
 *             return new_graph_monitor!(MonitoredExample, StatisticsExample, "a")(this);
 *         }
 * }
 * --------------------
 */
SubMonitor new_graph_monitor(Monitored, Statistics, Values ...)(Monitored monitored)
{
    //copy V to an array of strings
    string[] values;
    foreach(s; Values){values ~= s.idup;}
    return new GraphMonitor!(Monitored, Statistics, Values)(monitored, new GraphData(values));
}

private:

/**
 * Monitor that measures statistics of monitored object and stores them in GraphData.
 *
 * Params:  Monitored  = Type of monitored object. Must have a send_statistics 
 *                       signal that passes a Statistics struct.
 *          Statistics = Struct used by the Monitorable to send statistics to 
 *                       the GraphMonitor.
 *          Values     = Strings specifying names of values measured. Must
 *                       correspond with public data members of Statistics.
 */
final package class GraphMonitor(Monitored, Statistics, Values ...) : SubMonitor
{
    private:
        ///Graph data.
        GraphData data_;

        ///Disconnects the monitor from monitorable's send_statistics.
        void delegate() disconnect_;

    public:
        override void die()
        {
            disconnect_();
            data_.die();
            data_ = null;
            super.die();
        }

        @property override SubMonitorView view()
        {
            return new GraphMonitorView!(typeof(this))(this);
        }

        ///Get access to graph data.
        @property GraphData data(){return data_;}

    protected:
        /**
         * Construct a GraphMonitor.
         *
         * Params:  monitored  = Object to monitor.
         *          graph_data = Graph data to store statistics in.
         */
        this(Monitored monitored, GraphData graph_data)
        {
            super();
            monitored.send_statistics.connect(&receive_statistics); 
            disconnect_ = {monitored.send_statistics.disconnect(&receive_statistics);};
            data_ = graph_data;
        }

        ///Receive statistics data from the monitored object.
        void receive_statistics(Statistics statistics)
        {
            //Generate code to update graph values at compile time.
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
            
            data_.update();
        }
}

/**
 * GUI view for GraphMonitor.
 *
 * Allows the user to view a system monitor style graph, select which values to 
 * view, pan and zoom the view and change graph resolution.
 *
 * Params:  GraphMonitor = Type of GraphMonitor (template specialization) viewed.
 */
final package class GraphMonitorView(GraphMonitor) : SubMonitorView
{
    private:
        ///Palette of colors used by generated graph monitor code.
        static immutable Color[] palette = [Color.red,
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

        ///Graph monitor viewed.
        GraphMonitor monitor_;

        ///Graph widget.
        GUILineGraph graph_;
        //Not using menu since we need to control color of each button.
        ///Buttons used to toggle display of values on the graph.
        GUIButton[string] value_buttons_;

        ///Default graph X scale to return to after zooming.
        float scale_x_default_;
        ///Zoom multiplier corresponding to one zoom level.
        float zoom_mult_ = 1.1;

    public:
        ///Construct a GraphMonitorView viewing specified monitor.
        this(GraphMonitor monitor)
        {
            super();

            monitor_ = monitor;

            init_graph();
            init_mouse();
            init_toggles();
            init_menu();
        }

    private:
        ///Initialize the graph widget.
        void init_graph()
        {
            //construct the graph widget
            with(new GUILineGraphFactory)
            {
                foreach(color, value; monitor_.data.graph_names)
                {
                    graph_color(value, palette[color]);
                }
                margin(2, 2, 24, 52);
                data = monitor_.data;
                graph_ = produce();
            }
            main_.add_child(graph_);
            scale_x_default_ = graph_.scale_x;
        }

        ///Initialize mouse control.
        void init_mouse()
        {
            //provides zooming/panning functionality
            auto mouse= new GUIMouseControllable;
            mouse.zoom.connect(&zoom);
            mouse.pan.connect(&pan);
            mouse.reset_view.connect(&reset_view);
            graph_.add_child(mouse);
        }
        
        ///Initialize buttons that toggle values' graph display.
        void init_toggles()
        {
            foreach(color, name; monitor_.data.graph_names)
            {
                with(new GUIButtonFactory)
                {
                    x = "p_left + 2";
                    width = "48";
                    height = "12";
                    font_size = 8;
                    y = "p_top + " ~ to!string(2 + 14 * value_buttons_.keys.length);
                    font_size = MonitorView.font_size;
                    text_color(ButtonState.Normal, palette[color]);
                    text = name;

                    auto button = produce();
                    button.pressed.connect({graph_.toggle_value(name);});
                    value_buttons_[name] = button;
                    main_.add_child(button);
                }
            }
        }     

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
                item_font_size = MonitorView.font_size;
                add_item("res +", &resolution_increase);
                add_item("res -", &resolution_decrease);
                add_item("sum", &sum);
                add_item("avg", &average);
                main_.add_child(produce());
            }
        }

        ///Decrease graph data point time - used by resolution + button.
        void resolution_increase()
        {
            graph_.data_point_time = graph_.data_point_time * 0.5;
        }

        ///Increase graph data point time - used by resolution - button.
        void resolution_decrease()
        {
            graph_.data_point_time = graph_.data_point_time * 2.0;
        }

        ///Set sum graph mode - used by sum button.
        void sum(){graph_.graph_mode = GraphMode.Sum;}

        ///Set average graph mode - used by average button.
        void average(){graph_.graph_mode = GraphMode.Average;}

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
