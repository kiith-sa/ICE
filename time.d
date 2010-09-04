module time;


version(linux)
{
    import std.c.linux.linux;
}
else
{
    import std.date;
}

import singleton;


class Time 
{
    mixin Singleton;
    public:
        this(){singleton_ctor();}

        ///Returns time since start of epoch in seconds.
        static real get_time()
        {
            //high-resolution linux clock - microsecond precision
            version(linux)
            {
                timeval tv;
                gettimeofday(&tv, null);
                return tv.tv_sec + tv.tv_usec / 1000000.0;
            }
            //portable D standard library clock - usually millisecond precision
            else
            {
                return getUTCtime() / cast(real)TicksPerSecond;
            }
        }
}
