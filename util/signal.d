module util.signal;


import containers.array;


///Signal template mixin for the signals/slot system.
template Signal(Args ...)	
{
    private:
        //Slots of this signal
        void delegate(Args)[] slots_;

    public:
        ///Emit the signal (call all slots with given arguments).
        void emit(Args args)
        {
            foreach (deleg; slots_){deleg(args);}
        }

        /**
         * Connect a slot to the signal. 
         * The same slot can be connected more than once. 
         * This will result in multiple calls to that slot when the signal is
         * emitted.
         */
        void connect(void delegate(Args) deleg)
        in{assert(deleg !is null, "Can't connect a null function to a signal");}
        body{slots_ ~= deleg;}

        /**
         * Disconnect a slot from the signal. 
         * If a slot is connected more than once, it must be disconnected
         * corresponding number of times.
         */
        void disconnect(void delegate(Args) deleg)
        in
        {
            alias containers.array.contains contains;
            assert(slots_.contains(deleg, true), 
                   "Can't disconnect a slot that is not connected");
        }
        body
        {
            alias containers.array.remove_first remove_first;
            slots_.remove_first(deleg, true);
        }
}
