
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Timer struct.
module time.timer;


import time.time;


///A timer struct; handles timing of various delayed or periodic events.
struct Timer
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
        this(const real delay){this(delay, getTime());}

        /**
         * Constructs a timer starting at specified time.
         *
         * Params:  delay = Delay of the timer.
         *          time  = Start time of the timer.
         */
        this(const real delay, const real start)
        {               
            start_ = start;
            delay_ = delay; 
        }

        ///Get time when the timer was started.
        @property real start() const pure {return start_;}

        ///Get delay of this timer.
        @property real delay() const pure {return delay_;}

        /**
         * Returns time since start of the timer at specified time.
         *
         * Params:  time = Time relative to which to calculate the age.
         *
         * Returns: Age of the timer relative to specified time.
         */
        @property real age(const real time) const pure {return time - start_;}

        ///Returns time since start of the timer.
        @property real age() const {return age(getTime());}

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
        @property real ageRelative(const real time) const pure 
        {
            return age(time) / delay_;
        }

        /**
         * Returns time since start of the timer divided by the timer's delay. 
         *
         * Returns: Age of the timer divided by the delay.
         *          This is 0.0 at the start of the timer, and 1.0 at its end, 
         *          so it can be used to get percentage of timer's delay that has elapsed.
         */
        @property real ageRelative() const {return ageRelative(getTime());}

        /**
         * Determines if the timer has expired at specified time.
         *
         * Params:  time = Time relative to which to check for expiration.
         *
         * Returns: True if the timer has expired, false otherwise.
         */
        bool expired(const real time) const pure {return time - start_ > delay_;}

        ///Determines if the timer has expired.
        bool expired() const {return expired(getTime());}

        ///Resets the timer with specified start time.
        void reset(const real start) pure {start_ = start;}

        ///Resets the timer.
        void reset(){reset(getTime());}
}
