module graphdata;


import math.math;
import time.time;
import time.timer;
import arrayutil;
import vector;

///Graph modes.
enum GraphMode
{
    ///Show totals per time unit.
    Sum,
    ///Show averages over measurements (e.g. frames).
    Average
}

/**
 * Stores graph data accumulating over time.
 */
final class GraphData
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

        ///Graphs of values measured, indexed by values' names.
        Graph[string] graphs_;

        //Graph mode, i.e. are data points sums or averages over time?
        GraphMode mode_ = GraphMode.Average;

        //Time when this guigraph was created
        real start_time_;
        //Shortest time period to accumulate values for.
        real time_resolution_ = 0.0625;
        //Timer used to time graph updates.
        Timer update_timer_;

    public:
        ///Graph data related to measurement of single value over time.
        class Graph
        {
            private:
                //Value we're currently accumulating to. This is a total of values 
                //added over period specified by the time resolution.
                Value current_value_;
                //Values recorded, sorted from earliest to latest.
                Vector!(Value) values_;
                //Vector holding memory for arrays returned by data_points.
                Vector!(real) data_points_;

            public:
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
                    data_points_.length = cast(uint)((end - start) / period); 
                    foreach(ref point; data_points_){point = 0.0;}
                    if(empty){return data_points_.array;}

                    //guess the first value in our time window.
                    real age = start - start_time;
                    uint value_index = clamp(cast(int)(age / time_resolution_)
                                             ,0 , cast(int)values_.length - 1);
                    //if we guessed too far, move back (if too near, foreach will
                    //simply iterate to the first valid value)
                    while(cast(int)((values_[value_index].time - start) / period) >= 0 
                          && value_index > 0)
                    {
                        value_index--;
                    }

                    foreach(ref value; values_.array[value_index .. $])
                    {
                        int index = cast(int)((value.time - start) / period);
                        if(index < 0){continue;}
                        if(index >= data_points_.length){break;}
                        if(mode_ == GraphMode.Average)
                        {
                            data_points_[index] = value.value / value.value_count;
                        }
                        else if(mode_ == GraphMode.Sum)
                        {
                            data_points_[index] = value.value;
                        }
                        else{assert(false, "Unsupported graph mode");}
                    }

                    return data_points_.array;
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

            private:
                /*
                 * Construct the graph with specified starting time.
                 *
                 * Params:  time = Starting time of the graph.
                 */
                this(real time)
                {
                    values_ = Vector!(Value)();
                    data_points_ = Vector!(real)();
                    current_value_.time = time + time_resolution * 0.5; 
                }

                ///Destroy this graph.
                void die()
                {
                    values_.die();
                    data_points_.die();
                }

                /*
                 * Update the graph and finish accumulating a value.
                 *
                 * Params:  time =            End time of the accumulated value.
                 */
                void update(real time)
                {
                    values_ ~= current_value_;
                    current_value_.time = time + time_resolution * 0.5;
                    current_value_.value = 0.0;
                    current_value_.value_count = 0;
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
        }

        /**
         * Construct graph data with specified names of measured values.
         *
         * Params:  graph_names = Names of measured values.
         */
        this(string[] graph_names ...)
        in
        {
            foreach(index_a, name_a; graph_names)
            {
                foreach(index_b, name_b; graph_names)
                {
                    assert(!(name_a == name_b && index_a != index_b),
                           "GUIGraph can't show multiple values with identical names");
                }
            }
        }
        body
        {
            start_time_ = get_time();

            foreach(name; graph_names){graphs_[name] = new Graph(start_time_);}

            update_timer_ = Timer(time_resolution_, start_time_);
        }

        ///Destroy this GraphData.
        void die()
        {
            foreach(graph; graphs_.values){graph.die();}
        }

        ///Set graph mode, i.e. should data points be sums or averages?
        final void mode(GraphMode mode){mode_ = mode;}

        ///Get time resolution of the graph.
        final real time_resolution(){return time_resolution_;}

        ///Get time when this graph started to exist.
        final real start_time(){return start_time_;}

        ///Get graphs of values measured, indexed by values' names.
        final Graph[string] graphs(){return graphs_;}

        ///Add a value to the graph for value with specified name.
        final void update_value(string name, real value)
        in{assert(graphs_.keys.contains(name), "Adding unknown value to graph");}
        body{graphs_[name].add_value(value);}

        ///Update graph data memory representation.
        void update()
        {
            if(update_timer_.expired)
            {
                real time = get_time();
                foreach(graph; graphs_.values){graph.update(time);}
            }
        }
}
