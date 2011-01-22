module monitor.graphmonitor;


import gui.guigraph;
import gui.guilinegraph;
import gui.guielement;
import gui.guibutton;
import gui.guimenu;
import math.vector2;
import math.rectangle;
import platform.platform;
import monitor.monitor;
import color;


/**
 * Base class for system monitor style graph monitoring widgets.
 *
 * User can zoom and scroll the graph with mouse,
 * change data point time, average or sum mode and toggle display of
 * monitored values.
 */
abstract class GraphMonitor : GUIElement
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

    public:
        /**
         * Construct a GraphMonitor monitoring values with specified names.
         *
         * Params:  value_names = Names of values to monitor.
         */
        this(string[] value_names ...)
        {
            init_toggles(value_names);
            init_menu();

            graph_ = new GUILineGraph(value_names);
            with(graph_)
            {
                position_x = "p_left + 52";
                position_y = "p_top + 2";
                width = "p_right - p_left - 54";
                height = "p_bottom - p_top - 26";
            }
            add_child(graph_);

            scale_x_default_ = graph_.scale_x;
            font_size = Monitor.font_size;
        }

        ///Set font size of all elements of this graph.
        void font_size(uint size)
        {
            graph_.font_size = size;
            foreach(value; value_buttons_.values){value.font_size = size;}
        }

    protected:
        /**
         * Add a new measurement to value with specified name.
         *
         * Params:  name  = Name of the value to add to.
         *          value = Measurement to add.
         */
        final void add_value(string name, real value){graph_.add_value(name,value);}

        /**
         * Set color of specified value in the graph (and its toggle button)
         *
         * Params:  name  = Name of the value.
         *          color = Color to set.
         */
        final void color(string name, Color color)
        {
            graph_.color(name, color);
            value_buttons_[name].text_color(color, ButtonState.Normal);
        }

        ///Set graph mode.
        final void mode(GraphMode graph_mode){graph_.mode(graph_mode);}

        //Add buttons changing graph mode. Can optionally be used by some implementations.
        void add_mode_buttons()
        {
            menu_.add_item("sum", &sum);
            menu_.add_item("avg", &average);
        }

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
        //Initialize value display toggling buttons.
        void init_toggles(string[] value_names)
        {
            uint y_offset = 2;
            foreach(name; value_names)
            {
                auto button = new GUIButton;
                auto value = new Toggle(name);

                button.pressed.connect(&(value.toggle));
                with(button)
                {
                    text = name;
                    font_size = 8;
                    position_x = "p_left + 2";
                    position_y = "p_top + " ~ to_string(y_offset);
                    width = "48";
                    height = "12";
                }
                value_buttons_[name] = button;
                add_child(button);
                values_ ~= value;
                y_offset += 14;
            }
        }

        //Initialize menu. 
        void init_menu()
        {
            menu_ = new GUIMenu;
            with(menu_)
            {
                position_x = "p_left + 50";
                position_y = "p_bottom - 24";
                orientation = MenuOrientation.Horizontal;

                add_item("res +", &resolution_increase);
                add_item("res -", &resolution_decrease);

                item_font_size = 8;
                item_width = "48";
                item_height = "20";
                item_spacing = "2";
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
    string result = "super(\"" ~ values[0] ~ "\"";

    foreach(value; values[1 .. $]){result ~= ", \"" ~ value ~ "\"";}

    result ~= ");";
    result ~= "monitored.send_statistics.connect(&fetch_statistics);";

    foreach(v, value; values)
    {
        result ~= "color(\"" ~ value ~ "\", " ~ palette[v] ~ ");";
    }

    return result;
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
    string result = "void fetch_statistics(Statistics statistics)"
                    "{";
    foreach(value; values)
    {
        result ~= "add_value(\"" ~ value ~ "\", statistics." ~ value ~ ");";
    }
    result ~= "}";
    return result;
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
                          "Color(0, 128, 0, 255)"];
