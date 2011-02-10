module util.iterator;


/**
 * Not really an iterator in C++ or Java sense, rather just a base 
 * for classes that allow iterating over something with foreach.
 */
abstract class Iterator(T)
{
    public:
        int opApply(int delegate(ref T) dg);
}
