module monitor.graphmonitor;


import gui.guigraph;
import gui.guilinegraph;
import gui.guielement;
import gui.guibutton;
import math.vector2;
import math.rectangle;
import platform.platform;
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
        
        //Button used to decrease data point time, or increase time resolution of the graph.
        GUIButton resolution_plus_;
        //Button used to increase data point time, or decrease time resolution of the graph.
        GUIButton resolution_minus_;

        //Button used to set sum graph mode.
        GUIButton sum_;
        //Button used to set average graph mode.
        GUIButton average_;

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
            init_resolution_buttons();

            graph_ = new GUILineGraph(value_names);
            with(graph_)
            {
                position_x = "p_left + 52";
                position_y = "p_top + 2";
                width = "p_right - p_left - 54";
                height = "p_bottom - p_top - 34";
            }
            add_child(graph_);

            scale_x_default_ = graph_.scale_x;
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
            sum_ = new GUIButton;
            sum_.pressed.connect(&sum);
            with(sum_)
            {
                text = "sum";
                font_size = 8;
                position_x = "p_left + 52";
                position_y = "p_bottom - 15";
                width = "(p_right - p_left - 54) / 2 - 1";
                height = "13";
            }
            add_child(sum_);

            average_ = new GUIButton;
            average_.pressed.connect(&average);
            with(average_)
            {
                text = "average";
                font_size = 8;
                position_x = "p_right - (p_right - p_left - 54) / 2 - 1";
                position_y = "p_bottom - 15";
                width = "(p_right - p_left - 54) / 2 - 1";
                height = "13";
            }
            add_child(average_);
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

        //Initialize buttons changing data point time (resolution) of the graph.
        void init_resolution_buttons()
        {
            resolution_plus_ = new GUIButton;
            resolution_plus_.pressed.connect(&resolution_increase);
            with(resolution_plus_)
            {
                text = "resolution +";
                font_size = 8;
                position_x = "p_left + 52";
                position_y = "p_bottom - 30";
                width = "(p_right - p_left - 54) / 2 - 1";
                height = "13";
            }
            add_child(resolution_plus_);

            resolution_minus_ = new GUIButton;
            resolution_minus_.pressed.connect(&resolution_decrease);
            with(resolution_minus_)
            {
                text = "resolution -";
                font_size = 8;
                position_x = "p_right - (p_right - p_left - 54) / 2 - 1";
                position_y = "p_bottom - 30";
                width = "(p_right - p_left - 54) / 2 - 1";
                height = "13";
            }
            add_child(resolution_minus_);
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
