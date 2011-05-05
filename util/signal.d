
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module util.signal;
@safe


import std.algorithm;


/**
 * Signal template mixin for Qt-like signals/slots.
 *
 * Signals should always be documented in header class documentation,
 * and always disconnect all their slots (disconnect_all) at their
 * owner class destructor or die() method.
 * 
 * Examples:
 * --------------------
 * Signal:
 *     public mixin Signal!() back
 *
 *     Used to return back to parent menu.
 * --------------------
 */
template Signal(Args ...)    
{
    private:
        ///Slots of this signal.
        void delegate(Args)[] slots_;

    public:
        ///Emit the signal (call all slots with specified arguments).
        void emit(Args args)
        {
            foreach(deleg; slots_){deleg(args);}
        }

        /**
         * Connect a slot to the signal. 
         *
         * One slot can be connected more than once, resulting in multiple calls 
         * to that slot when the signal is emitted.
         *
         * Only embedded, class/struct member functions can be connected, 
         * global functions are not supported at the moment.
         *
         * Params:  slot = Slot to connect.
         */
        void connect(void delegate(Args) slot)
        in{assert(slot !is null, "Can't connect a null function to a signal");}
        body{slots_ ~= slot;}

        /**
         * Disconnect a slot from the signal. 
         *
         * If a slot is connected more than once, it must be disconnected
         * corresponding number of times.
         *
         * Params:  slot = Slot to disconnect. Must already be connected.
         */
        void disconnect(void delegate(Args) slot)
        in
        {
            assert(std.algorithm.canFind!"a is b"(slots_, slot),
                   "Can't disconnect a slot that is not connected");
        }
        body
        {
            //removing element this way due to a bug in std.algorithm.remove
            const uint i = std.algorithm.countUntil!("a is b", void delegate(Args)[], void delegate(Args))(slots_, slot);
            slots_ = slots_[0 .. i] ~ slots_[i + 1 .. $];
        }

        ///Disconnect all connected slots.
        void disconnect_all(){slots_ = [];}
}
