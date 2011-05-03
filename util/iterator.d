
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module util.iterator;
@trusted


/**
 * Not really an iterator in C++ or Java sense, rather just a base 
 * for classes that allow iterating over something with foreach.
 */
abstract class Iterator(T)
{
    public:
        ///Used by foreach.
        int opApply(int delegate(ref T) visitor);
}
