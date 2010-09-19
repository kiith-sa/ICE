module time.timer;


import time.time;


///A timer struct; handles timing of various delayed or periodic events.
struct Timer
{
    invariant
    {
        assert(delay_ >= 0.0, "Can't have a Timer with negative delay");
        assert(start_ >= 0.0, "Can't have a Timer with negative start");
    }

    private:
        //start_ time of the timer
        real start_ = 0.0;

        //delay_ of the timer (i.e. how long after start does the timer expire)
        real delay_ = 0.0;

    public:
        ///Fake constructor. Returns a timer with given delay starting now.
        static Timer opCall(real delay){return Timer(delay, get_time());}

        ///Fake constructor. Returns a timer with given delay starting at specified time.
        static Timer opCall(real delay, real time)
        {               
            Timer t;
            t.start_ = time;
            t.delay_ = delay; 
            return t;
        }

        /**
         * Returns time since start of the timer at given time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        real age(real time){return time - start_;}

        ///Returns time since start of the timer.
        real age(){return age(get_time());}

        /**
         * Returns time since start of the timer at given time, relative to the timer's delay.
         *
         * age_relative returns 0.0 at the start of the timer, and 1.0 at its
         * end, so it can be used to get percentage of timer's delay that has
         * elapsed.
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        real age_relative(real time){return age(time) / delay_;}

        /**
         * Returns time since start of the timer, relative to the timer's delay.
         *
         * age_relative returns 0.0 at the start of the timer, and 1.0 at its
         * end, so it can be used to get percentage of timer's delay that has
         * elapsed.
         */
        real age_relative(){return age_relative(get_time());}

        /**
         * Determines if the timer is expired at given time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        bool expired(real time){return time - start_ > delay_;}

        ///Determines if the timer is expired.
        bool expired(){return expired(get_time());}

        /**
         * Resets the timer with specified start time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        void reset(real start){start_ = start;}

        ///Resets the timer with specified start time.
        void reset(){reset(get_time());}
}
