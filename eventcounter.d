module eventcounter;


import std.string;

import time;
import timer;
import signal;


///Generalization of an FPS counter - i.e. counts how frequently an event happens
final class EventCounter
{
    private:
        //time when this eventcounter started
        real start_time_;

        //used for periodic updates
        Timer period_;

        //number of events last period
        uint events_period_ = 0;

        //total number of events
        uint events_total_ = 0;
        
        //total number of events until the end of the last period
        uint events_total_last_period_ = 0;

    public:
        ///Emitted when a period ends - passes events per second.
        mixin Signal!(real) update;

        ///Construct an EventCounter with specified update period.
        this(real period)
        {
            period_ = Timer(period);
            start_time_ = get_time();
        }

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
