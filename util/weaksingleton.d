
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module util.weaksingleton;
@safe


/**
 * Singleton template mixin with support for polymorphism, without global access.
 *
 * It is recommended to use this instead of Singleton as there is no global access.
 *
 * Note: Any non-abstract weak singleton class must call singleton_ctor() in its ctor
 *       and singleton_dtor in its dtor or die() method.
 */
template WeakSingleton()
{
    protected:
        ///Singleton object itself.
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

