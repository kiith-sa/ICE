module timer;


import time;

///A timer struct; handles timing of various delayed or periodic events.
struct Timer
{
    invariant
    {
        assert(Delay >= 0.0, "Can't have a Timer with negative delay");
        assert(Start >= 0.0, "Can't have a Timer with negative start");
    }

    private:
        //Start time of the timer
        real Start = 0.0;

        //Delay of the timer (i.e. how long after start does the timer expire)
        real Delay = 0.0;

    public:
        ///(Fake) constructor. Constructs a timer with given delay starting now.
        void opCall(real delay)
        {               
            opCall(delay, Time.get_time());
        }

        ///(Fake) constructor. Constructs a timer with given delay starting at specified time.
        void opCall(real delay, real time)
        {               
            Start = time;
            Delay = delay; 
        }

        /**
         * Returns time since start of the timer at given time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        real age(real time)
        {
            return time - Start;
        }

        ///Returns time since start of the timer.
        real age()
        {
            return age(Time.get_time());
        }

        /**
         * Returns time since start of the timer at given time, relative to the timer's delay.
         *
         * age_relative returns 0.0 at the start of the timer, and 1.0 at its
         * end, so it can be used to get percentage of timer's delay that has
         * elapsed.
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        real age_relative(real time)
        {
            return age(time) / Delay;
        }

        /**
         * Returns time since start of the timer, relative to the timer's delay.
         *
         * age_relative returns 0.0 at the start of the timer, and 1.0 at its
         * end, so it can be used to get percentage of timer's delay that has
         * elapsed.
         */
        real age_relative()
        {
            return age_relative(Time.get_time());
        }

        /**
         * Determines if the timer is expired at given time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        bool expired(real time)
        {
            if(time - Start > Delay)
            {
                return true;
            }
            return false;
        }

        ///Determines if the timer is expired.
        bool expired()
        {
            return expired(Time.get_time());
        }

        /**
         * Resets the timer with specified start time.
         *
         * Used for events that have to be synchronized (e.g. every event
         * during a frame must have time equal to start of that frame)
         */
        void reset(real start)
        {
            Start = start;
        }

        ///Resets the timer with specified start time.
        void reset()
        {
            reset(Time.get_time());
        }
}
