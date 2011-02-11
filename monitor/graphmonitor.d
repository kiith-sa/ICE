module monitor.graphmonitor;


import stringctfe;

import graphdata;
import gui.guilinegraph;
import gui.guielement;
import gui.guibutton;
import gui.guimenu;
import math.vector2;
import math.rectangle;
import platform.platform;
import monitor.monitor;
import monitor.submonitor;
import color;


/**
 * Base class for system monitor style graph monitoring widgets.
 *
 * User can zoom and scroll the graph with mouse,
 * change data point time, average or sum mode and toggle display of
 * monitored values.
 */
abstract class GraphMonitor : SubMonitor
{
    protected:
        //Measured graph da0ta.
        GraphData data_;
    private:
        alias std.string.toString to_string;  
        //Graph widget controlled by this monitor.
        GUILineGraph graph_;
        //Buttons used to toggle display of values on the graph.
        //Not using menu since we need to control color of each button.
        GUIButton[string] value_buttons_;
        //Menu of buttons controlling the graph.
        GUIMenuHorizontal menu_;

        //note: in D2, this can be replaced with closures
        //Function object used by buttons for graph method calls to toggle display of values.
        class Toggle
        {
            //Name of the value to toggle.
            string name_;
            //Constructor to save keystrokes.
            this(string name){name_ = name;}
            //This is the actual method to connect to a button.
            void toggle(){graph_.toggle_value(name_);}
        }

        //Function objects for every button to toggle display of its respective value.
        Toggle[] values_;

        //Default graph X scale to return to after zooming.
        float scale_x_default_;

        //Is the left mouse button pressed? Used to detect mouse dragging for scrolling.
        bool left_pressed_;

    public:
        override void die()
        {
            data_.die();
            super.die();
        }

    protected:
        /*
         * Construct a GraphMonitor monitoring values with specified names.
         *
         * Params:  factory    = Factory used to produce the graph widget.
         *                       Derived class is responsible with adding value
         *                       graphs to the factory.
         *          graph_data = Graph data to link the graph widget to.
         */
        this(GUILineGraphFactory factory, GraphData graph_data)
        {
            super();
            init_menu();
            data_ = graph_data;

            with(factory)
            {
                x = "p_left + 52";
                y = "p_top + 2";
                width = "p_width - 54";
                height = "p_height - 26";
                data = graph_data;
                graph_ = produce();
            }

            add_child(graph_);

            scale_x_default_ = graph_.scale_x;
        }

        /**
         * Add a new measurement to value with specified name.
         *
         * Params:  name  = Name of the value to add to.
         *          value = Measurement to add.
         */
        final void update_value(string name, real value){data_.update_value(name,value);}

        ///Set graph mode.
        final void mode(GraphMode graph_mode){data_.mode(graph_mode);}

        override void mouse_key(KeyState state, MouseKey key, Vector2u position)
        {
            if(!visible_){return;}
            super.mouse_key(state, key, position);

            //ignore if mouse is outside of the graph widget
            if(!graph_.bounds_global.intersect(Vector2i(position.x, position.y))){return;}

            //zoom the graph by specified multiplier.
            void zoom(float zoom)
            {
                graph_.scale_x = graph_.scale_x * zoom;
                graph_.scale_y = graph_.scale_y * zoom;
            }

            switch(key)
            {
                //mouse wheel handles zooming
                case MouseKey.WheelUp:
                    graph_.auto_scale = false;
                    zoom(1.25f);
                    break;
                case MouseKey.WheelDown:
                    graph_.auto_scale = false;
                    zoom(0.8f);
                    break;
                //right click returns to autoscrolling and autoscaling
                case MouseKey.Right:
                    if(state == KeyState.Pressed)
                    {
                        graph_.scale_x = scale_x_default_;
                        graph_.auto_scale = true;
                        graph_.auto_scroll = true;
                    }
                    break;
                //detect when left is pressed so we can detect mouse dragging
                case MouseKey.Left:
                    left_pressed_ = state == KeyState.Pressed ? true : false;
                    break;
                default:
                    break;
            }
        }

        override void mouse_move(Vector2u position, Vector2i relative)
        {
            if(!visible_){return;}
            super.mouse_move(position, relative);

            //ignore if mouse is outside of the graph widget
            if(!graph_.bounds_global.intersect(Vector2i(position.x, position.y)))
            {
                left_pressed_ = false;
                return;
            }

            //dragging over the graph
            if(left_pressed_){graph_.scroll(-relative.x);}
        }

        /*
         * Add a value display toggling button for a value.
         *
         * Params:  name  = Name of the graph toggled by the button.
         *          color = Color of the button text.
         */  
        void add_toggle(string name, Color color)
        {
            auto value = new Toggle(name);
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
                button.pressed.connect(&(value.toggle));
                value_buttons_[name] = button;
                add_child(button);
            }
            values_ ~= value;
        }     

        override void update()
        {
            super.update();
            data_.update();
        }

    private:
        /*
         * Initialize menu. 
         *
         * Params:  mode_buttons = Add buttons for changing graph mode?
         */
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

        //Decrease graph data point time - used by resolution + button.
        void resolution_increase(){graph_.data_point_time = graph_.data_point_time * 0.5;}

        //Increase graph data point time - used by resolution - button.
        void resolution_decrease(){graph_.data_point_time = graph_.data_point_time * 2.0;}

        //Set sum graph mode - used by sum button
        void sum(){data_.mode = GraphMode.Sum;}

        //Set average graph mode - used by average button
        void average(){data_.mode = GraphMode.Average;}
}

/**
 * Generate constructor code for a graph monitor implementation.
 *
 * Note: To use this as a mixin, you have to import gui.guilinegraph .
 *
 * Initializes graph monitor with specified values to monitor, 
 * automatically sets their colors, and connectss a callback
 * to fetch statistics from the monitored object. 
 * This code should be inserted to a graph monitor implementation constructor
 * with a string mixin.
 *
 * Note: The constructor must have access to the monitored object through a variable
 * called "monitored", the monitored object must have a "send_statistics" signal
 * that passes a struct/class called "Statistics" to a method called 
 * "fetch_statistics" in the implementation, which should be generated by a string
 * mixin generating code with the generate_graph_fetch_statistics function.
 *
 * Params: values = Names of the values monitored by the graph monitor that will
 *                  use the generated code. Colors will be automatically assigned
 *                  to the values from a limited palette, limiting number of values
 *                  supported (8 right now). Parameters passed here must be the same
 *                  as ones passed to corresponding generate_graph_fetch_statistics
 *                  call.
 *
 * Returns: Generated code, ready to be inserted into a graph monitor constructor.
 */
string generate_graph_monitor_ctor(string[] values...)
in
{
    assert(values.length <= palette.length && values.length > 0, 
           "Too many or no values to track");
}
body
{
    string factory = "auto factory = new GUILineGraphFactory;\n";
    //code adding graphs for values measured to the factory
    string values_str;
    foreach(color, value; values)
    {
        values_str ~= "factory.graph_color(\"" ~ value ~ "\", " ~ palette[color] ~ ");\n";
        values_str ~= "add_toggle(\"" ~ value ~ "\", " ~ palette[color] ~ ");\n";
    }
    string data = "auto data = new GraphData(\"" ~ values.join("\", \"") ~ "\");\n";
    string super_call = "super(factory, data);\n";

    string connect = "monitored.send_statistics.connect(&fetch_statistics);\n";

    return factory ~ values_str ~ data ~ super_call ~ connect;
}
unittest
{
    string expected =
        "auto factory = new GUILineGraphFactory;\n"
        "factory.graph_color(\"a\", " ~ palette[0] ~ ");\n"
        "add_toggle(\"a\", " ~ palette[0] ~ ");\n"
        "factory.graph_color(\"b\", " ~ palette[1] ~ ");\n"
        "add_toggle(\"b\", " ~ palette[1] ~ ");\n"
        "auto data = new GraphData(\"a\", \"b\");\n"
        "super(factory, data);\n"
        "monitored.send_statistics.connect(&fetch_statistics);\n"; 
    assert(expected == generate_graph_monitor_ctor("a","b"),
           "Unexpected graph monitor ctor code generated");
}

/**
 * Generate a statistics fetching method for a graph monitor implementation.
 * Pases values of data members of a struct/class called Statistics to 
 * values of the same name in the graph monitor.
 * This code should be inserted to a graph monitor implementation as a method
 * with a string mixin.
 *
 * Params: values = Names of the values monitored by the graph monitor that will
 *                  use the generated code. These have to correspond with data members
 *                  of the Statistics class/struct passed.
 *
 * Returns: Generated code, ready to be inserted into a graph monitor implementation.
 */
string generate_graph_fetch_statistics(string[] values...)
in{assert(values.length > 0 , "No values to track");}
body
{
    string header = "void fetch_statistics(Statistics statistics)\n"
                    "{\n";
    string update_values;
    foreach(value; values)
    {
        update_values ~= "    data_.update_value(\"" ~ value ~ "\", statistics." ~ value ~ ");\n";
    }
    return header ~ update_values ~ "}\n";
}
unittest
{
    string expected =
        "void fetch_statistics(Statistics statistics)\n"
        "{\n"
        "    data_.update_value(\"a\", statistics.a);\n"
        "    data_.update_value(\"b\", statistics.b);\n"
        "}\n";
    assert(expected == generate_graph_fetch_statistics("a","b"),
           "Unexpected graph monitor fetch_statistics() code generated");
}

private:

///Palette of colors used by graph monitor code generated with string mixins.
const string[] palette = ["Color.red",
                          "Color.green",
                          "Color.blue",
                          "Color.yellow",
                          "Color.cyan",
                          "Color.magenta",
                          "Color.burgundy",
                          "Color(0, 128, 0, 255)",
                          "Color(0, 0, 128, 255)",
                          "Color.forest_green",
                          "Color(0, 128, 128, 255)",
                          "Color.dark_purple"];
