module weaksingleton;

/**
 * Singleton template mixin with support for polymorphism, without global access.
 *
 * Note: Any non-abstract singleton class must call singleton_ctor() in its ctor
 *       and singleton_dtor in its dtor or die() method.
 */
template WeakSingleton()
{
    protected:
        static typeof(this) _instance_ = null;

    public:
        ///Enforce only single instance at any given time.
        void singleton_ctor()
        {
            assert(_instance_ is null, 
                  "Trying to construct a weak singleton that is already constructed: "
                  ~ typeid(typeof(this)).toString);
            _instance_ = this;
        }

        ///Enforce only single instance at any given time.
        void singleton_dtor()
        {
            assert(_instance_ !is null, 
                  "Trying to destroy a weak singleton that is not constructed: "
                  ~ typeid(typeof(this)).toString);
            _instance_ = null;
        }
}

