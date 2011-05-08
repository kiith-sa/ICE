
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module util.iterable;
@trusted


///Base for classes that support iteration over objects of specified type with foreach.
abstract class Iterable(T)
{
    public:
        ///Used by foreach.
        int opApply(int delegate(ref T) visitor);
}
