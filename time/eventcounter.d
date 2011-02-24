
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module time.eventcounter;


import std.string;

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
final class EventCounter
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
        this(real period)
        {
            period_ = Timer(period);
            start_time_ = get_time();
        }

        ///Destroy this EventCounter.
        void die(){update.disconnect_all();}

        ///Count one event.
        void event()
        {
            if(period_.expired())
            {
                events_period_ = events_total_ - events_total_last_period_;

                real updates_second = events_period_ / period_.age();
                update.emit(updates_second);

                events_total_last_period_ = events_total_;
                period_.reset();
            }
            ++events_total_;
        }

        ///Get number of events counted so far.
        uint events(){return events_total_;}

        ///Return a string containing statistics about events counted.
        string statistics()
        {
            real time_total = get_time() - start_time_;
            real events_second = events_total_ / time_total;

            alias std.string.toString to_string;
            return "Total events: " ~ to_string(events_total_) ~ "\n" 
                   ~ "Total Time: " ~ to_string(time_total) ~ "\n" 
                   ~ "Average events per second: " ~ to_string(events_second);
        }
}
