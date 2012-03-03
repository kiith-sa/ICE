
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Struct managing statistics displayed by graphs.
module graphdata;


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
        real startTime_;
        ///Shortest time period to accumulate values for.
        real timeResolution_ = 0.0625;
        ///Timer used to time graph updates.
        Timer updateTimer_;

    public:
        ///Graph data related to measurement of single value over time.
        class Graph
        {
            private:
                ///Stores values accumulated over a time period set by GraphData's timeResolution.
                static align(4) struct Value
                {
                    ///Time point of the value (set to the start of measurement).
                    real time;
                    ///Sum of the values measured.
                    real value = 0.0;
                    ///Number of values accumulated.
                    uint valueCount = 0;
                }                 

                ///Value we're currently accumulating to.
                Value currentValue_;
                ///Recorded values sorted from earliest to latest.
                Vector!Value values_;
                ///Memory for arrays returned by dataPoints().
                Vector!real dataPoints_;
                ///Memory for value counts array used to compute data points in average mode.
                Vector!uint valueCounts_;

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
                const(real)[] dataPoints(real start, real end, real period, GraphMode mode)
                in
                {
                    assert(start < end, 
                           "Can't get data points for a time window that ends before it starts");
                }
                body
                {
                    dataPoints_.length = cast(size_t)((end - start) / period); 
                    (dataPoints_.ptrUnsafe[0 .. dataPoints_.length])[] = 0.0;
                    if(empty){return dataPoints_[];}

                    if(mode == GraphMode.Sum){dataPointsSum(start, period);}
                    else if(mode == GraphMode.Average){dataPointsAverage(start, period);}
                    else{assert(false, "Unsupported graph mode");}

                    return dataPoints_[];
                }

                /**
                 * Is the graph empty, i.e. are there no values stored?
                 *
                 * Note that the graph is empty until the first accumulated
                 * value is added, which depends on time resolution.
                 */
                @property bool empty() const pure {return values_.length == 0;}

                /**
                 * Get start time of the graph, i.e. time of the first value in the graph.
                 *
                 * Only makes sense if the graph is not empty.
                 */
                @property real startTime() const pure
                in{assert(!empty(), "Can't get start time of an empty graph");}
                body{return values_[0].time;}

                /**
                 * Add a value to the graph. 
                 * 
                 * Params:  value = Value to add. 
                 */
                void updateValue(real value)
                {
                    //accumulate to currentValue_
                    currentValue_.value += value;
                    currentValue_.valueCount++;
                }

            private:
                /**
                 * Construct a graph with specified starting time.
                 *
                 * Params:  time = Starting time of the graph.
                 */
                this(real time)
                {
                    currentValue_.time = time;
                }

                /**
                 * Update the graph and finish accumulating a value.
                 *
                 * Params:  time = End time of the accumulated value.
                 */
                void update(const real time)
                {
                    values_ ~= currentValue_;
                    clear(currentValue_);
                    currentValue_.time = time;
                }

                /**
                 * Get the index of the first value in a time window starting at start.
                 *
                 * Params:  start  = Start time to get data points from.
                 *
                 * Returns: Index of the first value to aggregate.
                 */
                size_t firstValueIndex(real start)
                {
                    //ugly, but optimized

                    //guess the first value based on time resolution.
                    const real age = start - startTime;
                    const size_t valueIdx = clamp(floor!int(age / timeResolution_),
                                                   0 , cast(int)values_.length - 1);

                    const(Value)* valuesStart = values_.ptrUnsafe;
                    const Value* valuesEnd = valuesStart + values_.length;
                    const(Value)* valuePtr = valuesStart + valueIdx;

                    //move linearly to the desired value
                    while(valuePtr.time >= start && valuePtr > valuesStart)
                    {
                        valuePtr--;
                    }
                    while(valuePtr.time < start && valuePtr < valuesEnd)
                    {
                        valuePtr++;
                    }

                    return cast(size_t)(valuePtr - valuesStart);
                }

                /**
                 * Aggregate data points in sum mode.
                 *
                 * This depends on code in dataPoints() and can only be called from there.
                 *
                 * Params:  start  = Start time to take data points from.
                 *          period = Time period to represent by single data point.
                 */
                void dataPointsSum(real start, real period)
                {
                    //ugly, but optimized
                    const numPoints = dataPoints_.length;
                    real* pointsPtr = dataPoints_.ptrUnsafe;

                    const(Value)* valuesStart = values_.ptrUnsafe;
                    const Value* valuesEnd = valuesStart + values_.length;

                    //index of data point to add current value to.
                    int index;

                    const(Value)* value = valuesStart + firstValueIndex(start);  
                    //iterate over values and aggregate data points
                    for(; value < valuesEnd; value++)
                    {
                        index = floor!int((value.time - start) / period);
                        if(index >= numPoints){return;}
                        *(pointsPtr + index) += value.value;
                    }
                }

                /**
                 * Aggregate data points in average mode.
                 *
                 * This depends on code in dataPoints() and can only be called from there.
                 *
                 * Params:  start  = Start time to take data points from.
                 *          period = Time period to represent by single data point.
                 */
                void dataPointsAverage(real start, real period)
                {
                    //ugly, but optimized
                    const numPoints = dataPoints_.length;
                    real* pointsPtr = dataPoints_.ptrUnsafe;

                    valueCounts_.length = numPoints;
                    uint* valueCountsStart = valueCounts_.ptrUnsafe;
                    const uint* valueCountsEnd = valueCountsStart + numPoints;
                     
                    //zero all value counts.
                    valueCounts_[] = 0; 

                    const(Value)* valuesStart = values_.ptrUnsafe;
                    const Value* valuesEnd = valuesStart + values_.length;

                    //index of data point to add current value to.
                    int index;
                    //iterate over values and aggregate data points, value counts
                    const(Value)* value = valuesStart + firstValueIndex(start); 
                    for(; value < valuesEnd; value++)
                    {
                        index = floor!int((value.time - start) / period);
                        if(index >= numPoints){break;}
                        *(pointsPtr + index) += value.value;
                        *(valueCountsStart + index) += value.valueCount;
                    }

                    //divide data points by value counts to get averages.
                    real* point = pointsPtr;
                    const(uint)* count = valueCountsStart; 
                    for(; count < valueCountsEnd; count++, point++)
                    {
                        if(*count == 0){continue;}
                        *point /= *count;
                    }
                }
        }
                  
        /**
         * Construct graph data with specified number of graphs.
         *
         * Params:  graphCount = Number of graphs to store.
         */
        this(size_t graphCount)
        {
            startTime_ = getTime();

            foreach(idx; 0 .. graphCount){graphs_ ~= new Graph(startTime_);}

            updateTimer_ = Timer(timeResolution_, startTime_);
        }

        ///Destroy this GraphData.
        ~this()
        {
            foreach(graph; graphs_){clear(graph);}
            clear(graphs_);
        }

        ///Get time resolution of the graph.
        @property final real timeResolution() pure {return timeResolution_;}

        ///Get time when this graph started to exist.
        @property final real startTime() const pure {return startTime_;}

        ///Get (non-const) access to graphs stored.
        @property Graph[] graphs() pure
        {
            return graphs_;
        }

        ///Update graph data memory representation.
        void update()
        {
            if(updateTimer_.expired)
            {
                real time = getTime();
                foreach(graph; graphs_){graph.update(time);}
            }
        }
}
