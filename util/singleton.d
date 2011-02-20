
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.singleton;


/**
 * Singleton template mixin with support for polymorphism.
 *
 * This is a typical singleton. Single instance and global access.
 * It is recommended to use WeakSingleton instead.
 *
 * Note: Any non-abstract singleton class must call singleton_ctor() in its ctor.
 */
template Singleton()
{
    protected:
        ///Singleton object itself.
        static typeof(this) _instance_ = null;

    public:
        ///Access the singleton.
        static typeof(this) get()
        out(result){assert(result !is null);}
        body
        {
            assert(_instance_ !is null, "Trying to access an uninitialized singleton: " 
                  ~ typeid(typeof(this)).toString);
            return _instance_;
        }            

        ///Check for errors caused by explicit calls of singleton constructors.
        static void singleton_ctor()
        {
            assert(_instance_ is null, 
                   "Trying to construct a singleton that is already constructed: "
                   ~ typeid(typeof(this)).toString);
        }

        /**
         * Initialize singleton with given subtype if it's not yet initialized.
         *
         * This makes it possible to select implementation of a polymorphic
         * singleton on construction, e.g. if we have an abstract singleton class
         * Interface and two implementations I1 and I2, we can initialize
         * either using Interface.initialize!(I1) or Interface.initialize(!I2)
         * to select implementation.
         */
        static void initialize(T)()
        {
            if(_instance_ is null){_instance_ = new T;}
        }
}
