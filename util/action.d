
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.action;

  
///Base class for Actions (Needed due to templating).
abstract class ActionBase
{
    public void opCall(){assert(false);};
}

///Wrapper of a function and its arguments. Might be replaceable by closures in D2.
class Action(Args ...) :ActionBase
{
    private:
        ///Function to execute.
        void delegate(Args) action_;

        ///Arguments of the function.
        Args args_;

    public:
        /**
         * Construct an Action.
         *
         * Params:  action = Function to wrap.
         *          args   = Arguments to pass to the function once it's executed.
         */
        this(void delegate(Args) action, Args args)
        {
            action_ = action;
            args_ = args;
        }

        ///Execute the action.
        override void opCall(){action_(args_);}
}
