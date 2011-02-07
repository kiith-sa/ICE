module iterator;


///Base class for Java-style iterators.
abstract class Iterator(T)
{
    public:
        ///Get next element.
        T next();
        ///Do we have another element?
        bool has_next();
}
