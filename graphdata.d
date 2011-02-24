
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module graphdata;


import math.math;
import time.time;
import time.timer;
import containers.array;
import containers.vector;


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
    private:
        ///Stores values accumulated over a time period set by GraphData's time_resolution.
        static align(1) struct Value
        {
            ///Time point of the value (set to the middle of measurement).
            real time;
            ///Sum of the values measured.
            real value = 0.0;
            ///Number of values accumulated.
            uint value_count = 0;
        }                 

        ///Graph data related to measurement of single value over time.
        class Graph
        {
            private:
                ///Value we're currently accumulating to.
                Value current_value_;
                ///Recorded values sorted from earliest to latest.
                Vector!(Value) values_;
                ///Memory for arrays returned by data_points().
                Vector!(real) data_points_;
                ///Memory for value counts array used to compute data points in average mode.
                Vector!(uint) value_counts_;

            public:
                /**
                 * Accumulate values recorded over a time window to data points, one 
                 * point per period specified, each data point is an sum or average of 
                 * values over the period, depending on graph mode. 
                 * 
                 * Params:  start  = Start of the time window.
                 *          end    = End of the time window.
                 *          period = Time period to represent by single data point.
                 * 
                 * Returns: Array of data points in specified time window.
                 */
                real[] data_points(real start, real end, real period)
                in
                {
                    assert(start < end, 
                           "Can't get data points for a time window that ends before it starts");
                }
                body
                {
                    data_points_.length = cast(uint)((end - start) / period); 
                    data_points_.array[] = 0.0;
                    if(empty){return data_points_.array;}

                    if(mode_ == GraphMode.Sum){data_points_sum(start, period);}
                    else if(mode_ == GraphMode.Average){data_points_average(start, period);}
                    else{assert(false, "Unsupported graph mode");}

                    return data_points_.array;
                }

                /**
                 * Is the graph empty, i.e. are there no values stored?
                 *
                 * Note that the graph is empty until the first accumulated
                 * value is added, which depends on time resolution.
                 */
                bool empty(){return values_.length == 0;}

                /**
                 * Get start time of the graph, i.e. time of the first value in the graph.
                 *
                 * Only makes sense if the graph is not empty.
                 */
                real start_time()
                in{assert(!empty(), "Can't get start time of an empty graph");}
                body{return values_[0].time;}

            private:
                /**
                 * Construct a graph with specified starting time.
                 *
                 * Params:  time = Starting time of the graph.
                 */
                this(real time)
                {
                    values_ = Vector!(Value)();
                    data_points_ = Vector!(real)();
                    value_counts_ = Vector!(uint)();
                    current_value_.time = time + time_resolution * 0.5; 
                }

                ///Destroy this graph.
                void die()
                {
                    values_.die();
                    data_points_.die();
                    value_counts_.die();
                }

                /**
                 * Update the graph and finish accumulating a value.
                 *
                 * Params:  time = End time of the accumulated value.
                 */
                void update(real time)
                {
                    values_ ~= current_value_;
                    current_value_.time = time + time_resolution * 0.5;
                    current_value_.value = 0.0;
                    current_value_.value_count = 0;
                }

                /**
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

                /**
                 * Get the index of the first value to be aggregated to data points
                 * with specified start time and period.
                 *
                 * Params:  start  = Start time to get data points from.
                 *          period = Length of time to represent by single data point.
                 *
                 * Returns: Index of the first value to aggregate.
                 */
                uint first_value_index(real start, real period)
                {
                    //ugly, but optimized

                    //guess the first value based on time resolution.
                    real age = start - start_time;
                    uint value = clamp(floor_s32(age / time_resolution_) ,0 , 
                                       cast(int)values_.length - 1);

                    Value* values_ptr = values_.array.ptr;
                    Value* value_ptr = values_ptr + value;
                    Value* values_end = values_ptr + values_.length;

                    //move linearly to the desired value
                    while(value_ptr.time >= start && value_ptr > values_ptr)
                    {
                        value_ptr--;
                    }
                    while(value_ptr.time < start && value_ptr < values_end)
                    {
                        value_ptr++;
                    }

                    return cast(uint)(value_ptr - values_ptr);
                }

                /**
                 * Aggregate data points in sum mode.
                 *
                 * This depends on code in data_points() and can only be called from there.
                 *
                 * Params:  start  = Start time to take data points from.
                 *          period = Time period to represent by single data point.
                 */
                void data_points_sum(real start, real period)
                {
                    //ugly, but optimized
                    uint num_points = data_points_.length;
                    real* points_ptr = data_points_.array.ptr;

                    Value* values_ptr = values_.array.ptr;
                    Value* values_end = values_ptr + values_.length;

                    //index of data point to add current value to.
                    int index;

                    //iterate over values and aggregate data points
                    for(Value* value = values_ptr + first_value_index(start, period); 
                        value < values_end; value++)
                    {
                        index = floor_s32((value.time - start) / period);
                        if(index >= num_points){return;}
                        *(points_ptr + index) += value.value;
                    }
                }

                /**
                 * Aggregate data points in average mode.
                 *
                 * This depends on code in data_points() and can only be called from there.
                 *
                 * Params:  start  = Start time to take data points from.
                 *          period = Time period to represent by single data point.
                 */
                void data_points_average(real start, real period)
                {
                    //ugly, but optimized
                    uint num_points = data_points_.length;
                    real* points_ptr = data_points_.array.ptr;

                    value_counts_.length = num_points;
                    uint* value_counts_ptr = value_counts_.array.ptr;
                    uint* value_counts_end = value_counts_ptr + num_points;
                     
                    //zero all value counts. memset could make this even faster, but want to avoid cstdlib if I can
                    for(uint* count = value_counts_ptr; count < value_counts_end; count++)
                    {
                        *count = 0;
                    }

                    Value* values_ptr = values_.array.ptr;
                    Value* values_end = values_ptr + values_.length;

                    //index of data point to add current value to.
                    int index;

                    //iterate over values and aggregate data points, value counts
                    for(Value* value = values_ptr + first_value_index(start, period);
                        value < values_end; value++)
                    {
                        index = floor_s32((value.time - start) / period);
                        if(index >= num_points){break;}
                        *(points_ptr + index) += value.value;
                        *(value_counts_ptr + index) += value.value_count;
                    }

                    //divide data points by value counts to get averages.
                    real* point = points_ptr;
                    for(uint* count = value_counts_ptr; 
                        count < value_counts_end; count++, point++)
                    {
                        if(*count == 0){continue;}
                        *point /= *count;
                    }
                }
        }
                  

        ///Graphs of measured values, indexed by values' names.
        Graph[string] graphs_;

        ///Graph mode: Are data points sums or averages over time?
        GraphMode mode_ = GraphMode.Average;

        ///Time when this GraphData was created
        real start_time_;
        ///Shortest time period to accumulate values for.
        real time_resolution_ = 0.0625;
        ///Timer used to time graph updates.
        Timer update_timer_;

    public:
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

        ///Get names of measured values.
        final string[] graph_names(){return graphs_.keys;}

        ///Add a value to the graph of value with specified name.
        final void update_value(string name, real value)
        in{assert(graphs_.keys.contains(name), "Adding unknown value to graph");}
        body{graphs_[name].add_value(value);}

        /**
         * Accumulate values recorded over a time window to data points, one 
         * point per specified period, each data point is a sum or average of 
         * values over the period, depending on graph mode. 
         * 
         * Params:  name   = Name of the value to get data points for.
         *          start  = Start of the time window.
         *          end    = End of the time window.
         *          period = Time period to represent by single data point.
         * 
         * Returns: Array of data points in the specified time window.
         */
        real[] data_points(string name, real start, real end, real period)
        {
            return graphs_[name].data_points(start, end, period);
        }

        /**
         * Determine if graph of value with specified name is empty.
         *
         * Note that the graph is empty for a while until first accumulated
         * value is added, which depends on time resolution.
         *
         * Params:  name = Name of the value to check.
         *
         * Returns: True if the graph is empty, false otherwise.
         */
        bool empty(string name){return graphs_[name].empty;}

        /**
         * Get delay of graph of value with specified name relative to this GraphData.
         *
         * Params:  name = Name of the value to check.
         *
         * Returns: Delay of the graph relative to this GraphData in seconds.
         */
        real delay(string name){return graphs_[name].start_time - start_time_;}

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
