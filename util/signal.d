
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Qt-like signals.
module util.signal;
@safe


import std.algorithm;


/**
 * Signal template mixin for Qt-like signals/slots.
 *
 * Signals should always be documented in header class documentation,
 * and always disconnect all their slots (disconnect_all) at their
 * owner classes' destructor or die() method.
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
        alias void delegate(Args) Slot;

        ///Slots of this signal.
        Slot[] slots_;

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
        void connect(Slot slot)
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
        void disconnect(Slot slot)
        in
        {
            assert(std.algorithm.canFind!"a is b"(slots_, slot),
                   "Can't disconnect a slot that is not connected");
        }
        body
        {
            slots_ = std.algorithm.remove!((Slot a){return a is slot;})(slots_); 
        }

        ///Disconnect all connected slots.
        void disconnect_all(){slots_ = [];}
}
