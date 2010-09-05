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
        real StartTime;

        //used for periodic updates
        Timer Period;

        //number of events last period
        uint EventsPeriod = 0;

        //total number of events
        uint EventsTotal = 0;
        
        //total number of events until the end of the last period
        uint EventsTotalLastPeriod = 0;

    public:
        ///Emitted when a period ends - passes events per second.
        mixin Signal!(real) update;

        ///Construct an EventCounter with specified update period.
        this(real period)
        {
            Period(period);
            StartTime = get_time();
        }

        ///Count one event.
        void event()
        {
            if(Period.expired())
            {
                EventsPeriod = EventsTotal - EventsTotalLastPeriod;

                real updates_second = EventsPeriod / Period.age();
                update.emit(updates_second);

                EventsTotalLastPeriod = EventsTotal;
                Period.reset();
            }
            ++EventsTotal;
        }

        ///Return a string containing statistics about events counted.
        string statistics()
        {
            real time_total = get_time() - StartTime;
            real events_second = EventsTotal / time_total;

            alias std.string.toString to_string;
            return "Total events: " ~ to_string(EventsTotal) ~ "\n" 
                   ~ "Total Time: " ~ to_string(time_total) ~ "\n" 
                   ~ "Average events per second: " ~ to_string(events_second);
        }
}
