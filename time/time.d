
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Time functions.
module time.time;


import std.conv;
import std.datetime;

import math.math;


///Time when the program started in tenths of microseconds since 00:00 1.1.1 AD.
private immutable long startTime_;

///Static ctor - initialize program start time.
private static this(){startTime_ = Clock.currStdTime();}

///Returns time since program start in seconds.
real getTime(){return (Clock.currStdTime() - startTime_) / 1_000_000_0.0L;}

/**
 * Converts a time value to a string in format mm:ss, or hh:mm:ss if hours is true.
 *
 * Seconds are always represented by two digits, even if the first one is zero, e.g. 01
 * Minutes are shown without the leading zero if hours is false (default), otherwise
 * same as seconds. Hours are always shown without leading zeroes.
 *
 * Params:  time  = Time value to convert.
 *          hours = Show hours (as opposed to only minutes, seconds).
 */
string timeString(const real time, const bool hours = false)
in
{
    assert(time >= 0, "Can't convert negative time value to a string");
}
body
{
    const uint totalS = roundS32(time);
    const uint s = totalS % 60;
    uint m = totalS / 60;
    string sStr = to!string(s);
    if(!hours)
    {
        if(sStr.length == 1){sStr = "0" ~ sStr;}
        return to!string(m) ~ ":" ~ sStr;
    }
    else
    {
        string mStr = to!string(m);
        if(mStr.length == 1){mStr = "0" ~ mStr;}
        const uint h = m / 60;
        m %= 60;
        return to!string(h) ~ ":" ~ mStr ~ ":" ~ sStr;
    }
}
