module monitor.graphmonitor;


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
    private:
        alias std.string.toString to_string;  

        //Graph widget controlled by this monitor.
        GUILineGraph graph_;
        //Buttons used to toggle display of values on the graph.
        //Not using menu since we need to control color of each button.
        GUIButton[string] value_buttons_;
        //Menu of buttons controlling the graph.
        GUIMenu menu_;

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

    protected:
        /**
         * Construct a GraphMonitor monitoring values with specified names.
         *
         * Params:  names  = Names of values to monitor.
         *          colors = Colors of the values on the graph.
         */
        this(string[] names, Color[] colors)
        {
            super();

            init_toggles(names, colors);
            init_menu();

            with(new GUILineGraphFactory)
            {
                foreach(n, name; names){add_graph(name, colors[n]);}
                x = "p_left + 52";
                y = "p_top + 2";
                width = "p_right - p_left - 54";
                height = "p_bottom - p_top - 26";
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
        final void update_value(string name, real value){graph_.update_value(name,value);}

        ///Set graph mode.
        final void mode(GraphMode graph_mode){graph_.mode(graph_mode);}

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
                //middle (wheel) click returns to autoscaling
                case MouseKey.Middle:
                    if(state == KeyState.Pressed)
                    {
                        graph_.scale_x = scale_x_default_;
                        graph_.auto_scale = true;
                    }
                    break;
                //right click returns to autoscrolling
                case MouseKey.Right:
                    if(state == KeyState.Pressed){graph_.auto_scroll = true;}
                    break;
                //detect when left is pressed so we can detect mouse dragging
                case MouseKey.Left:
                    if(state == KeyState.Pressed){left_pressed_ = true;}
                    else{left_pressed_ = false;}
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

    private:
        /*
         * Initialize value display toggling buttons.
         *
         * Params:  names  = Names of the graphs toggled by the buttons.
         *          colors = Colors of the buttons' texts.
         */
        void init_toggles(string[] names, Color[] colors)
        {
            auto factory = new GUIButtonFactory;
            with(factory)
            {
                x = "p_left + 2";
                width = "48";
                height = "12";
                font_size = 8;
            }

            uint y_offset = 2;
            foreach(n, name; names)
            {
                auto value = new Toggle(name);

                with(factory)
                {
                    y = "p_top + " ~ to_string(y_offset);
                    font_size = Monitor.font_size;
                    text_color(ButtonState.Normal, colors[n]);
                    text = name;
                }
                auto button = factory.produce();

                button.pressed.connect(&(value.toggle));
                value_buttons_[name] = button;
                add_child(button);
                values_ ~= value;
                y_offset += 14;
            }
        }

        /*
         * Initialize menu. 
         *
         * Params:  mode_buttons = Add buttons for changing graph mode?
         */
        void init_menu()
        {
            with(new GUIMenuFactory)
            {
                x = "p_left + 50";
                y = "p_bottom - 24";
                orientation = MenuOrientation.Horizontal;
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
        void sum(){graph_.mode = GraphMode.Sum;}

        //Set average graph mode - used by average button
        void average(){graph_.mode = GraphMode.Average;}
}

/**
 * Generate constructor code for a graph monitor implementation.
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
    string super_start = "super(";

    string names = "[\"" ~ values[0] ~ "\"";
    foreach(value; values[1 .. $]){names ~= ", \"" ~ value ~ "\"";}
    names ~= "],";

    string colors = "[" ~ palette[0];
    for(uint c = 1; c < values.length; c++){colors ~= "," ~ palette[c];}
    colors ~= "]";

    string super_end = ");\n";

    string connect = "monitored.send_statistics.connect(&fetch_statistics);\n";

    return super_start ~ names ~ colors ~ super_end ~ connect;
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
        update_values ~= "update_value(\"" ~ value ~ "\", statistics." ~ value ~ ");\n";
    }
    return header ~ update_values ~ "}\n";
}

private:

///Palette of colors used by graph monitor code generated with string mixins.
const string[] palette = ["Color(255, 0, 0, 255)",
                          "Color(0, 255, 0, 255)",
                          "Color(0, 0, 255, 255)",
                          "Color(255, 255, 0, 255)",
                          "Color(0, 255, 255, 255)",
                          "Color(255, 0, 255, 255)",
                          "Color(128, 0, 0, 255)",
                          "Color(0, 128, 0, 255)",
                          "Color(0, 0, 128, 255)",
                          "Color(128, 128, 0, 255)",
                          "Color(0, 128, 128, 255)",
                          "Color(128, 0, 128, 255)"];
