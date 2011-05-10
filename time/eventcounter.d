
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Struct counting occurences of an event over time.
module time.eventcounter;
@safe


import std.conv;

import time.time;
import time.timer;
import util.signal;


/**
 * Generalization of an FPS counter - counts how many times an event happens
 *
 * Signal:
 *     public mixin Signal!(real) update
 *
 *     Emitted when a period ends - passes events per second.
 */
struct EventCounter
{
    private:
        ///Time when this eventcounter started.
        real start_time_;
        ///Used for periodic updates.
        Timer period_;

        ///Number of events last period.
        uint events_period_ = 0;
        ///Total number of events.
        uint events_total_ = 0;
        ///Total number of events until the end of the last period.
        uint events_total_last_period_ = 0;

    public:
        ///Emitted when a period ends - passes events per second.
        mixin Signal!(real) update;

        /**
         * Construct an EventCounter. 
         * 
         * Params:  period = Update period.
         */
        this(in real period)
        {
            period_ = Timer(period);
            start_time_ = get_time();
        }

        ///Destroy this EventCounter.
        ~this(){update.disconnect_all();}

        ///Count one event.
        void event()
        {
            if(period_.expired())
            {
                events_period_ = events_total_ - events_total_last_period_;

                const real updates_second = events_period_ / period_.age();
                update.emit(updates_second);

                events_total_last_period_ = events_total_;
                period_.reset();
            }
            ++events_total_;
        }

        ///Get number of events counted so far.
        @property uint events() const {return events_total_;}

        ///Return a string containing statistics about events counted.
        @property string statistics() const
        {
            const real time_total = get_time() - start_time_;
            const real events_second = events_total_ / time_total;

            return "Total events: " ~ to!string(events_total_) ~ "\n" 
                   ~ "Total Time: " ~ to!string(time_total) ~ "\n" 
                   ~ "Average events per second: " ~ to!string(events_second);
        }
}
