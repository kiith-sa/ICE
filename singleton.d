module singleton;

///Singleton template mixin with support for polymorphism.
/**
 * @note: Any non-abstract singleton class must call singleton_ctor() in its ctor.
 */
template Singleton()
{
    protected:
        static typeof(this) _instance_ = null;

    public:
        ///Get access to the singleton.
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

        ///Initialize singleton with given subtype if it's not yet initialized.
        /**
         * This makes it possible to select implementation of a polymorphic
         * singleton on runtime, e.g. if we have an abstract singleton class
         * Interface and two implementations I1 and I2, we can initialize
         * either using Interface.initialize!(I1) or Interface.initialize(!I2)
         * to select implementation. This is useful for e.g. video driver.
         */
        static void initialize(T)()
        {
            if(_instance_ is null){_instance_ = new T;}
        }
}
