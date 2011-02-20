
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.signal;


import containers.array;


///Signal template mixin for Qt-like signals/slots.
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
            alias containers.array.contains contains;
            assert(slots_.contains(slot, true), 
                   "Can't disconnect a slot that is not connected");
        }
        body
        {
            alias containers.array.remove_first remove_first;
            slots_.remove_first(slot, true);
        }
}
