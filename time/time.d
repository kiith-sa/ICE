
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module time.time;


import math.math;


version(linux){import std.c.linux.linux;}
else{import std.date;}

///Returns time since start of epoch in seconds.
real get_time()
{
    //high-resolution posix clock - microsecond precision
    version(linux)
    {
        timeval tv;
        gettimeofday(&tv, null);
        return tv.tv_sec + tv.tv_usec / 1000000.0;
    }
    //portable D standard library clock - usually millisecond precision
    else{return getUTCtime() / cast(real)TicksPerSecond;}
}


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
string time_string(real time, bool hours = false)
in
{
    assert(time >= 0, "Can't convert negative time value to a string");
}
body
{
    alias std.string.toString to_string;  
    uint total_s = round_s32(time);
    uint s = total_s % 60;
    uint m = total_s / 60;
    string s_str = to_string(s);
    if(!hours)
    {
        if(s_str.length == 1){s_str = "0" ~ s_str;}
        return to_string(m) ~ ":" ~ s_str;
    }
    else
    {
        string m_str = to_string(m);
        if(m_str.length == 1){m_str = "0" ~ m_str;}
        uint h = m / 60;
        m %= 60;
        return to_string(h) ~ ":" ~ m_str ~ ":" ~ s_str;
    }
}
