
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Base class for graph (system monitor style) monitors.
module monitor.graphmonitor;


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
 * Params:  Monitored  = Type of monitored object. Must have a sendStatistics 
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
 *         mixin Signal!(StatisticsExample) sendStatistics;
 *         
 *         void update()
 *         {
 *             //send statistics
 *             sendStatistics.emit(statistics_);
 *             //reset statistics for next measurement
 *             statistics_.a = statistics_.b = 0;
 *         }
 *
 *         //stuff done between updates
 *         void doStuff(){statistics_.a++;}
 *         void doSomethingElse(){statistics_.b++;}
 *         
 *         SubMonitor monitor()
 *         {
 *             //get a graph monitor monitoring this object
 *             return newGraphMonitor!(MonitoredExample, StatisticsExample, "a")(this);
 *         }
 * }
 * --------------------
 */
SubMonitor newGraphMonitor(Monitored, Statistics, Values ...)(Monitored monitored)
{
    //copy V to an array of strings
    string[] values;
    foreach(s; Values){values ~= s.idup;}
    return new GraphMonitor!(Monitored, Statistics, Values)
                            (monitored, new GraphData(values.length), values);
}

private:

/**
 * Monitor that measures statistics of monitored object and stores them in GraphData.
 *
 * Params:  Monitored  = Type of monitored object. Must have a sendStatistics 
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

        ///Names of the graphs.
        string[] graphNames_;

        ///Disconnects the monitor from monitorable's sendStatistics.
        void delegate() disconnect_;

    public:
        ~this()
        {
            disconnect_();
            clear(data_);
        }

        @property override SubMonitorView view()
        {
            return new GraphMonitorView!(typeof(this))(this);
        }

        ///Get access to graph data.
        @property GraphData data() pure {return data_;}

        ///Get names of the graphs.
        @property string[] graphNames() pure {return graphNames_;} 

    protected:
        /**
         * Construct a GraphMonitor.
         *
         * Params:  monitored   = Object to monitor.
         *          graphData  = Graph data to store statistics in.
         *          graphNames = Names of graphs in graphData.
         */
        this(Monitored monitored, GraphData graphData, string[] graphNames)
        in
        {
            assert(graphNames.length == graphData.graphs.length,
                   "Numbers of graphs and graph names passed to GraphMonitor do not match");
        }
        body
        {
            super();
            monitored.sendStatistics.connect(&receiveStatistics); 
            disconnect_ = {monitored.sendStatistics.disconnect(&receiveStatistics);};
            graphNames_ = graphNames;
            data_ = graphData;
        }

        ///Receive statistics data from the monitored object.
        void receiveStatistics(Statistics statistics)
        {
            //Generate code to update graph values at compile time.
            string updateValues() 
            {
                string result;
                foreach(idx, value; Values)
                {
                    result ~= "data_.graphs[" ~ std.conv.to!string(idx) ~ 
                              "].updateValue(statistics." ~ value ~ ");\n";
                }
                return result;
            }

            mixin(updateValues());
            
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
        ///Graph monitor viewed.
        GraphMonitor monitor_;

        ///Graph widget.
        GUILineGraph graph_;
        //Not using menu since we need to control color of each button.
        ///Buttons used to toggle display of values on the graph.
        GUIButton[string] valueButtons_;

        ///Default graph X scale to return to after zooming.
        float scaleXDefault_;
        ///Zoom multiplier corresponding to one zoom level.
        float zoomMult_ = 1.1;

    public:
        ///Construct a GraphMonitorView viewing specified monitor.
        this(GraphMonitor monitor)
        {
            super();

            monitor_ = monitor;

            initGraph();
            initMouse();
            initToggles();
            initMenu();
        }

    private:
        ///Initialize the graph widget.
        void initGraph()
        {
            //construct the graph widget
            with(new GUILineGraphFactory(monitor_.data))
            {
                margin(2, 2, 24, 52);
                graph_ = produce();
            }
            main_.addChild(graph_);
            scaleXDefault_ = graph_.scaleX;
        }

        ///Initialize mouse control.
        void initMouse()
        {
            //provides zooming/panning functionality
            auto mouse = new GUIMouseControllable;
            mouse.zoom.connect(&zoom);
            mouse.pan.connect(&pan);
            mouse.resetView.connect(&resetView);
            graph_.addChild(mouse);
        }
        
        ///Initialize buttons that toggle values' graph display.
        void initToggles()
        {
            void delegate() workaround(size_t graph)
            {
                return {graph_.toggleGraphVisibility(graph);};
            }

            foreach(graph; 0 .. monitor_.data.graphs.length) with(new GUIButtonFactory)
            {
                auto name = monitor_.graphNames[graph];

                x         = "p_left + 2";
                width     = "48";
                height    = "12";
                fontSize = 8;
                y         = "p_top + " ~ to!string(2 + 14 * valueButtons_.keys.length);
                fontSize = MonitorView.fontSize;
                text      = name;
                textColor(ButtonState.Normal, graph_.graphColor(graph));

                auto button = produce();

                //DMD bug workaround:
                //delegate here can't remember its context correctly
                //(or rather, all iterations remember the same context - at the end of loop)
                //so we have to construct the delegate in a separate function.
                button.pressed.connect(workaround(graph));
                valueButtons_[name] = button;
                main_.addChild(button);
            }
        }     

        ///Initialize menu. 
        void initMenu()
        {
            with(new GUIMenuHorizontalFactory)
            {
                x            = "p_left + 50";
                y            = "p_bottom - 24";
                itemWidth   = "48";
                itemHeight  = "20";
                itemSpacing = "2";
                itemFontSize = MonitorView.fontSize;
                addItem("res +", &resolutionIncrease);
                addItem("res -", &resolutionDecrease);
                addItem("sum", &sum);
                addItem("avg", &average);
                main_.addChild(produce());
            }
        }

        ///Decrease graph data point time - used by resolution + button.
        void resolutionIncrease()
        {
            graph_.dataPointTime = graph_.dataPointTime * 0.5;
        }

        ///Increase graph data point time - used by resolution - button.
        void resolutionDecrease()
        {
            graph_.dataPointTime = graph_.dataPointTime * 2.0;
        }

        ///Set sum graph mode - used by sum button.
        void sum(){graph_.graphMode = GraphMode.Sum;}

        ///Set average graph mode - used by average button.
        void average(){graph_.graphMode = GraphMode.Average;}

        ///Zoom by specified number of levels.
        void zoom(float relative)
        {
            graph_.autoScale = false;
            graph_.scaleX    = graph_.scaleX * pow(zoomMult_, relative);
            graph_.scaleY    = graph_.scaleY * pow(zoomMult_, relative); 
        }

        ///Pan view with specified offset.
        void pan(Vector2f relative){graph_.scroll(-relative.x);}

        ///Restore default view.
        void resetView()
        {
            graph_.scaleX     = scaleXDefault_;
            graph_.autoScale  = true;
            graph_.autoScroll = true;
        }
}
