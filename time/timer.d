
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module time.timer;
@safe


import time.time;


///A timer struct; handles timing of various delayed or periodic events.
align(1) struct Timer
{
    invariant()
    {
        assert(delay_ >= 0.0, "Can't have a Timer with negative delay");
        assert(start_ >= 0.0, "Can't have a Timer with negative start");
    }

    private:
        ///Start time of the timer.
        real start_ = 0.0;

        ///Delay of the timer (i.e. how long after start does the timer expire).
        real delay_ = 0.0;

    public:
        /**
         * Constructs a timer starting now.
         *
         * Params:  delay = Delay of the timer.
         */
        this(in real delay){this(delay, get_time());}

        /**
         * Constructs a timer starting at specified time.
         *
         * Params:  delay = Delay of the timer.
         *          time  = Start time of the timer.
         */
        this(in real delay, in real start)
        {               
            start_ = start;
            delay_ = delay; 
        }

        ///Get time when the timer was started.
        @property real start() const {return start_;}

        ///Get delay of this timer.
        @property real delay() const {return delay_;}

        /**
         * Returns time since start of the timer at specified time.
         *
         * Params:  time = Time relative to which to calculate the age.
         *
         * Returns: Age of the timer relative to specified time.
         */
        @property real age(in real time) const {return time - start_;}

        ///Returns time since start of the timer.
        @property real age() const {return age(get_time());}

        /**
         * Returns time since start of the timer at specified time divided by the timer's delay.
         *
         * Params:  time = Time relative to which to calculate the age.
         *
         * Returns: Age of the timer relative to specified time divided by the delay.
         *          This is 0.0 at the start of the timer, and 1.0 at its end, 
         *          so it can be used to get percentage of timer's delay that has elapsed.
         *
         */
        @property real age_relative(in real time) const {return age(time) / delay_;}

        /**
         * Returns time since start of the timer divided by the timer's delay. 
         *
         * Returns: Age of the timer divided by the delay.
         *          This is 0.0 at the start of the timer, and 1.0 at its end, 
         *          so it can be used to get percentage of timer's delay that has elapsed.
         */
        @property real age_relative() const {return age_relative(get_time());}

        /**
         * Determines if the timer has expired at specified time.
         *
         * Params:  time = Time relative to which to check for expiration.
         *
         * Returns: True if the timer has expired, false otherwise.
         */
        bool expired(in real time) const {return time - start_ > delay_;}

        ///Determines if the timer has expired.
        bool expired() const {return expired(get_time());}

        ///Resets the timer with specified start time.
        void reset(in real start){start_ = start;}

        ///Resets the timer.
        void reset(){reset(get_time());}
}
