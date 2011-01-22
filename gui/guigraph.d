module gui.guigraph;


import gui.guielement;
import math.math;
import time.time;
import time.timer;
import arrayutil;

///Graph display modes.
enum GraphMode
{
    ///Show totals per time unit.
    Sum,
    ///Show averages over measurements (e.g. frames).
    Average
}

///Base class for all graph widgets.
abstract class GUIGraph : GUIElement
{
    protected:
        ///Stores values accumulated over a time period set by GUIGraph's time_resolution.
        static align(1) struct Value
        {
            //Time point of the value (set to the middle of measurement).
            real time;
            //Sum of the values measured.
            real value = 0.0;
            //Number of values accumulated.
            uint value_count = 0;
        }

        ///Graph data related to measurement of single value over time.
        class Graph
        {
            private:
                //Value we're currently accumulating to. This is a total of values 
                //added over period specified by the time resolution.
                Value current_value_;
                //Values recorded, sorted from earliest to latest.
                Value[] values_;

            public:
                /*
                 * Construct the graph with specified starting time.
                 *
                 * Params:  time = Starting time of the graph.
                 */
                this(real time)
                {
                    current_value_.time = time + time_resolution_ * 0.5; 
                }

                /*
                 * Update the graph and finish accumulating a value.
                 *
                 * Params:  time = End time of the accumulated value.
                 */
                void update(real time)
                {
                    values_ ~= current_value_;
                    current_value_.time = time + time_resolution_ * 0.5;
                    current_value_.value = 0.0;
                    current_value_.value_count = 0;
                }

                /*
                 * Accumulate recorded values to data points, one point per
                 * period specified, each data point being an sum or average of values
                 * over that period, depending on graph mode. 
                 * Return data points between times specified by start and end.
                 * 
                 * Params:  start  = Start time to take data points from.
                 *          end    = End time to take data points until.
                 *          period = Time period to represent by single data point.
                 * 
                 * Returns: Resulting array of data points.
                 */
                real[] data_points(real start, real end, real period)
                in
                {
                    assert(start < end, "Can't retrieve data points for a time window"
                                        " that ends before it starts");
                }
                body
                {
                    real[] data_points;
                    uint[] value_counts;

                    value_counts.length = data_points.length = cast(uint)((end - start) / period);
                    for(uint point; point < data_points.length; point++)
                    {
                        data_points[point] = 0.0;
                        value_counts[point] = 0;
                    }

                    foreach(ref value; values_)
                    {
                        int index = cast(int)((value.time - start) / period);
                        if(index < 0){continue;}
                        if(index >= data_points.length){break;}
                        data_points[index] += value.value;
                        value_counts[index] += value.value_count;
                    }

                    if(mode_ == GraphMode.Average)
                    {
                        for(uint point; point < data_points.length; point++)
                        {
                            data_points[point] /= value_counts[point];
                        } 
                    }

                    //return output;
                    return data_points;
                }

                /*
                 * Add a value to the graph. 
                 * 
                 * Params:  value = Value to add. 
                 */
                void add_value(real value)
                {
                    //accumulate the value
                    current_value_.value += value;
                    current_value_.value_count++;
                }

                /*
                 * Is this graph empty, i.e. there are no values stored?
                 *
                 * Note that if the graph is empty until the first accumulate
                 * value is added, which depends on time resolution.
                 */
                bool empty(){return values_.length == 0;}

                /*
                 * Return start time of the graph, i.e. time of the first value in the graph.
                 *
                 * Note that this only makes sense if the graph is not empty.
                 */
                real start_time()
                in{assert(!empty(), "Can't get start time of an empty graph");}
                body{return values_[0].time;}
        }

        ///Graphs of values measured, indexed by values' names.
        Graph[string] graphs_;

        //Graph display mode, i.e. display sums for time period or average values.
        GraphMode mode_ = GraphMode.Average;

        //Time when this guigraph was created
        real start_time_;
        //Shortest time period to accumulate values for.
        real time_resolution_ = 0.03125;
        //Timer used to time graph updates.
        Timer update_timer_;

    public:
        /**
         * Construct a graph with specified names of measured values.
         *
         * Params:  graph_names = Names of values in the graph.
         */
        this(string[] graph_names ...)
        {
            //moved here due to contract inheritance
            foreach(index_a, name_a; graph_names)
            {
                foreach(index_b, name_b; graph_names)
                {
                    assert(!(name_a == name_b && index_a != index_b),
                           "GUIGraph can't show multiple values with identical names");
                }
            }

            super();

            start_time_ = get_time();

            foreach(name; graph_names){graphs_[name] = new Graph(start_time_);}

            update_timer_ = Timer(time_resolution_, start_time_);
        }

        ///Set graph display mode, i.e. should data points be sums or averages?
        final void mode(GraphMode mode)
        {
            aligned_ = false;
            mode_ = mode;
        }

        ///Add a value to the graph for value with specified name.
        final void add_value(string name, real value)
        in{assert(graphs_.keys.contains(name), "Adding unknown value to graph");}
        body{graphs_[name].add_value(value);}

    protected:
        void update()
        {
            super.update();

            if(update_timer_.expired)
            {
                real time = get_time();
                foreach(graph; graphs_.values){graph.update(time);}
            }
        }

}
