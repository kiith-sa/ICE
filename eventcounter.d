module eventcounter;


import std.string;

import time;
import timer;
import signal;


///Generalization of an FPS counter - i.e. counts how frequently an event happens
class EventCounter
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
            StartTime = Time.get_time();
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
            real time_total = Time.get_time() - StartTime;
            real events_second = EventsTotal / time_total;

            return "Total events: " ~ std.string.toString(EventsTotal) ~ "\n" 
                   ~ "Total Time: " ~ std.string.toString(time_total) ~ "\n" 
                   ~ "Average events per second: " 
                   ~ std.string.toString(events_second);
        }
}
