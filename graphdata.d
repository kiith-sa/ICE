
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Struct managing statistics displayed by graphs.
module graphdata;
@trusted


import std.algorithm;

import math.math;
import time.time;
import time.timer;
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
        ///Graphs of measured values.
        Graph[] graphs_;

        ///Time when this GraphData was created
        real start_time_;
        ///Shortest time period to accumulate values for.
        real time_resolution_ = 0.0625;
        ///Timer used to time graph updates.
        Timer update_timer_;

    public:
        ///Graph data related to measurement of single value over time.
        class Graph
        {
            private:
                ///Stores values accumulated over a time period set by GraphData's time_resolution.
                static align(4) struct Value
                {
                    ///Time point of the value (set to the start of measurement).
                    real time;
                    ///Sum of the values measured.
                    real value = 0.0;
                    ///Number of values accumulated.
                    uint value_count = 0;
                }                 

                ///Value we're currently accumulating to.
                Value current_value_;
                ///Recorded values sorted from earliest to latest.
                Vector!Value values_;
                ///Memory for arrays returned by data_points().
                Vector!real data_points_;
                ///Memory for value counts array used to compute data points in average mode.
                Vector!uint value_counts_;

            public:
                /**
                 * Accumulate values recorded over a time window to data points, one 
                 * point per period specified, each data point is a sum or average of 
                 * values over the period, depending on graph mode. 
                 * 
                 * Params:  start  = Start of the time window.
                 *          end    = End of the time window.
                 *          period = Time period to represent by single data point.
                 *          mode   = Graph mode (average per measurement or sums over time).
                 * 
                 * Returns: Array of data points in specified time window.
                 */
                const(real)[] data_points(real start, real end, real period, GraphMode mode)
                in
                {
                    assert(start < end, 
                           "Can't get data points for a time window that ends before it starts");
                }
                body
                {
                    data_points_.length = cast(size_t)((end - start) / period); 
                    (data_points_.ptr_unsafe[0 .. data_points_.length])[] = 0.0;
                    if(empty){return data_points_[];}

                    if(mode == GraphMode.Sum){data_points_sum(start, period);}
                    else if(mode == GraphMode.Average){data_points_average(start, period);}
                    else{assert(false, "Unsupported graph mode");}

                    return data_points_[];
                }

                /**
                 * Is the graph empty, i.e. are there no values stored?
                 *
                 * Note that the graph is empty until the first accumulated
                 * value is added, which depends on time resolution.
                 */
                @property bool empty() const {return values_.length == 0;}

                /**
                 * Get start time of the graph, i.e. time of the first value in the graph.
                 *
                 * Only makes sense if the graph is not empty.
                 */
                @property real start_time() const
                in{assert(!empty(), "Can't get start time of an empty graph");}
                body{return values_[0].time;}

                /**
                 * Add a value to the graph. 
                 * 
                 * Params:  value = Value to add. 
                 */
                void update_value(real value)
                {
                    //accumulate to current_value_
                    current_value_.value += value;
                    current_value_.value_count++;
                }

            private:
                /**
                 * Construct a graph with specified starting time.
                 *
                 * Params:  time = Starting time of the graph.
                 */
                this(real time)
                {
                    current_value_.time = time;
                }

                /**
                 * Update the graph and finish accumulating a value.
                 *
                 * Params:  time = End time of the accumulated value.
                 */
                void update(real time)
                {
                    values_ ~= current_value_;
                    clear(current_value_);
                    current_value_.time = time;
                }

                /**
                 * Get the index of the first value in a time window starting at start.
                 *
                 * Params:  start  = Start time to get data points from.
                 *
                 * Returns: Index of the first value to aggregate.
                 */
                size_t first_value_index(real start)
                {
                    //ugly, but optimized

                    //guess the first value based on time resolution.
                    const real age = start - start_time;
                    const size_t value_idx = clamp(floor_s32(age / time_resolution_),
                                                   0 , cast(int)values_.length - 1);

                    const(Value)* values_start = values_.ptr_unsafe;
                    const Value* values_end = values_start + values_.length;
                    const(Value)* value_ptr = values_start + value_idx;

                    //move linearly to the desired value
                    while(value_ptr.time >= start && value_ptr > values_start)
                    {
                        value_ptr--;
                    }
                    while(value_ptr.time < start && value_ptr < values_end)
                    {
                        value_ptr++;
                    }

                    return cast(size_t)(value_ptr - values_start);
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
                    const num_points = data_points_.length;
                    real* points_ptr = data_points_.ptr_unsafe;

                    const(Value)* values_start = values_.ptr_unsafe;
                    const Value* values_end = values_start + values_.length;

                    //index of data point to add current value to.
                    int index;

                    const(Value)* value = values_start + first_value_index(start);  
                    //iterate over values and aggregate data points
                    for(; value < values_end; value++)
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
                    const num_points = data_points_.length;
                    real* points_ptr = data_points_.ptr_unsafe;

                    value_counts_.length = num_points;
                    uint* value_counts_start = value_counts_.ptr_unsafe;
                    const uint* value_counts_end = value_counts_start + num_points;
                     
                    //zero all value counts.
                    value_counts_[] = 0; 

                    const(Value)* values_start = values_.ptr_unsafe;
                    const Value* values_end = values_start + values_.length;

                    //index of data point to add current value to.
                    int index;
                    //iterate over values and aggregate data points, value counts
                    const(Value)* value = values_start + first_value_index(start); 
                    for(; value < values_end; value++)
                    {
                        index = floor_s32((value.time - start) / period);
                        if(index >= num_points){break;}
                        *(points_ptr + index) += value.value;
                        *(value_counts_start + index) += value.value_count;
                    }

                    //divide data points by value counts to get averages.
                    real* point = points_ptr;
                    const(uint)* count = value_counts_start; 
                    for(; count < value_counts_end; count++, point++)
                    {
                        if(*count == 0){continue;}
                        *point /= *count;
                    }
                }
        }
                  
        /**
         * Construct graph data with specified number of graphs.
         *
         * Params:  graph_count = Number of graphs to store.
         */
        this(size_t graph_count)
        {
            start_time_ = get_time();

            foreach(idx; 0 .. graph_count){graphs_ ~= new Graph(start_time_);}

            update_timer_ = Timer(time_resolution_, start_time_);
        }

        ///Destroy this GraphData.
        ~this()
        {
            foreach(graph; graphs_){clear(graph);}
            clear(graphs_);
        }

        ///Get time resolution of the graph.
        @property final real time_resolution(){return time_resolution_;}

        ///Get time when this graph started to exist.
        @property final real start_time() const {return start_time_;}

        ///Get (non-const) access to graphs stored.
        @property Graph[] graphs()
        {
            return graphs_;
        }

        ///Update graph data memory representation.
        void update()
        {
            if(update_timer_.expired)
            {
                real time = get_time();
                foreach(graph; graphs_){graph.update(time);}
            }
        }
}
