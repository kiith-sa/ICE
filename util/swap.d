
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.swap;


/**
 * Swap two objects.
 *
 * Params:  a = First object.
 *          b = Second object.
 */
void swap(T)(ref T a, ref T b)
{
    T temp = a;
    a = b;
    b = temp;
}
