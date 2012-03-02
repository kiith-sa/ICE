
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Struct counting occurences of an event over time.
module time.eventcounter;


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
        real startTime_;
        ///Used for periodic updates.
        Timer period_;

        ///Number of events last period.
        uint eventsPeriod_ = 0;
        ///Total number of events.
        uint eventsTotal_ = 0;
        ///Total number of events until the end of the last period.
        uint eventsTotalLastPeriod_ = 0;

    public:
        ///Emitted when a period ends - passes events per second.
        mixin Signal!real update;

        /**
         * Construct an EventCounter. 
         * 
         * Params:  period = Update period.
         */
        this(const real period)
        {
            period_ = Timer(period);
            startTime_ = getTime();
        }

        ///Destroy this EventCounter.
        ~this(){update.disconnectAll();}

        ///Count one event.
        void event()
        {
            if(period_.expired())
            {
                eventsPeriod_ = eventsTotal_ - eventsTotalLastPeriod_;

                const real updatesSecond = eventsPeriod_ / period_.age();
                update.emit(updatesSecond);

                eventsTotalLastPeriod_ = eventsTotal_;
                period_.reset();
            }
            ++eventsTotal_;
        }

        ///Get number of events counted so far.
        @property uint events() const pure {return eventsTotal_;}

        ///Return a string containing statistics about events counted.
        @property string statistics() const
        {
            const real timeTotal = getTime() - startTime_;
            const real eventsSecond = eventsTotal_ / timeTotal;

            return "Total events: " ~ to!string(eventsTotal_) ~ "\n" 
                   ~ "Total Time: " ~ to!string(timeTotal) ~ "\n" 
                   ~ "Average events per second: " ~ to!string(eventsSecond);
        }
}
