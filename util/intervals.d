
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.intervals;


import std.algorithm;
import std.traits;

pure nothrow @safe:

/**
 * Inteval of specified number type.
 *
 * Params: T = Number type of the interval.
 *         L = If '(', the interval is open from the left. If '<', it is closed.
 *         R = If ')', the interval is open from the right. If '>', it is closed.
 */
const struct Interval(T, char L, char R)
    if(isNumeric!T && (L == '(' || L == '<') && (R == ')' || R == '>'))
{
    /// Minimum extent of the interval.
    T min;
    /// Maximum extent of the interval.
    T max;

    /// Construct an interval with specified extents.
    this(const T min, const T max)
    in
    {
        assert(min <= max, "Interval minimum greater than maximum");
    }
    body
    {
        this.min = min;
        this.max = max;
    }

    /// Determine if the interval contains specified value.
    bool contains(const T value) const
    {
        const bool aboveMin = (L == '(' ? value > min : value >= min);
        const bool belowMax = (R == ')' ? value < max : value <= max);
        return aboveMin && belowMax;
    }
}

/**
 * Foreachable range of intervals of equal size between specified min and max values.
 *
 * Example:
 * --------------------
 * // Generates intervals <128, 144), <144, 160), ... , <240, 256)
 * foreach(interval; IntervalsLinear!uint(16, 128, 256))
 * {
 *     //Do something with the interval
 * }
 * --------------------
 *
 * Params: T = Number types of the intervals.
 *         L = If '(', the intervals are open from the left. If '<', they are closed.
 *         R = If ')', the intervals are open from the right. If '>', they are closed.
 */
struct IntervalsLinear(T, char L = '<', char R = ')')
{
    private:
        /*
         * Start of the next interval.
         *
         * This is increased during iteration, consuming the range.
         */
        T start;

        /// End of the last interval.
        immutable T end;

        /// Size of the intervals.
        immutable T step;

    public:
        /**
         * Construct IntervalsLinear generating intervals step wide from min to max.
         *
         * Params:  step = Width of the intervals.
         *          min  = Beginning of the first interval.
         *          max  = End of the last interval. Width of the last interval
         *                 might be lower than step to avoid going past this value.
         */
        this(const T step, const T min, const T max)
        in
        {
            assert(min <= max, "ClosedIntervalsLinear minimum greater than maximum");
            assert(step > cast(T)0, "ClosedIntervalsLinear step less or equal to zero");
        }
        body
        {
            start = min;
            end   = max;
            this.step  = step;
        }

        /// Is the interval range empty? (Done iterating).
        bool empty() const
        {
            return start > end;
        }

        /// Advance the range to the text interval.
        void popFront()
        {
            assert(start <= end, "ClosedIntervalsLinear popFront() called when empty");
            start += step;
        }

        /// Get the current interval from the range.
        @property Interval!(T, L, R) front() const
        {
            assert(start <= end, "ClosedIntervalsLinear front() called when empty");
            return Interval!(T, L, R)(start, min(start + step, end));
        }
}

/**
 * Foreachable range of intervals between powers-of-two from 0 to specified size.
 *
 * Example:
 * --------------------
 * // Generates intervals <0, 1), <1, 2), <2, 4), ... , <128, 256)
 * foreach(interval; IntervalsPowerOfTwo!uint(256))
 * {
 *     //Do something with the interval
 * }
 * --------------------
 *
 * Params: T = Number types of the intervals.
 *         L = If '(', the intervals are open from the left. If '<', they are closed.
 *         R = If ')', the intervals are open from the right. If '>', they are closed.
 */
struct IntervalsPowerOfTwo(T, char L = '<', char R = ')')
{
    private:
        /// Start of the first interval.
        T start = cast(T)0;
        /// End of the last interval.
        immutable T end;

    public:
        /**
         * Construct IntervalsPowerOfTwo generating intervals from 0 to max.
         *
         * Params:  max  = End of the last interval. The last interval will end at 
         *                 this value.
         */
        this(const T max)
        {
            end = max;
        }

        /// Is the interval range empty? (Done iterating).
        bool empty() const
        {
            return start > end;
        }

        /// Advance the range to the text interval.
        void popFront()
        {
            assert(start <= end, "ClosedIntervalsQuadratic popFront() called when empty");
            start = (start == 0) ? 1 : start * 2;
        }

        /// Get the current interval from the range.
        @property Interval!(T, L, R) front() const
        {
            assert(start <= end, "ClosedIntervalsLinear front() called when empty");
            return Interval!(T, L, R)(start, (start == 0) ? 1 : start * 2);
        }
}
