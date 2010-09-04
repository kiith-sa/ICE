module singleton;


///Base interface for singletons
interface Singleton
{
    static Singleton get();
}


///Singleton mixin - singletons must include this and have a protected ctor. 
template SingletonMixin () 
{
    public:
        ///Returns reference to instance of the singleton.
        static typeof(this) get() 
        out(result)
        {
            assert(result !is null);
        }
        body
        {
            static typeof(this) instance = null;
            if(instance is null)
            {
                instance = new typeof(this);
            }

            return instance;
        }
}
