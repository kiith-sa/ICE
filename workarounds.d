//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module workarounds;
@trusted


/**
 * Remove an element from the array.
 * 
 * All matching elements will be removed. 
 *
 * Params:  array = Array to remove from.
 *          elem  = Element to remove from the array.
 *          ident = If true, remove exactly elem (is elem) instead 
 *                  of anything equal to elem (== elem).
 *                  Only makes sense for reference types.
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove(1); //Removes the first and the third element.
 * --------------------
 * 
 * --------------------
 * //Assuming Foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * array ~= array[3];              //The last Foo is now in the array twice.
 * array.remove(array[3], true);   //Removes the last two elements (indices 3 and 4)
 * array.remove(new Foo(1), true); //Removes nothing.
 * array.remove(new Foo(1));       //Removes the first and third element.
 * --------------------
 */
void remove(T, bool ident = false)(ref T[] array, T element)
{
    static if(ident)
    {
        remove(array, (ref T elem){return cast(bool)(elem is element);}); 
    }
    else
    {
        remove(array, (ref T elem){return cast(bool)(elem == element);}); 
    }
}

/**
 * Remove elements from an array with a function.
 *
 * Params:  array = Array to remove from.
 *          deleg = Function determining whether to remove an element.
 *                  Any element for which this function returns true is removed.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove((ref int i){return i < 3;}); //Removes all elements smaller than 3.
 * --------------------
 */
void remove(T)(ref T[] array, bool delegate(ref T) deleg)
{
    foreach_reverse(index, ref elem; array)
    {
        if(deleg(elem)){array.remove_index(index);}
    }
}

/**
 * Remove element at the specified index from the array.
 *
 * Params:  array = Array to remove from.
 *          index = Index to remove at. Must be within bounds.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove_index(0); //Removes element at index 0.
 * --------------------
 */
void remove_index(T)(ref T[] array, in size_t index)
in{assert(index < array.length, "Array index to remove out of bounds");}
body
{
    //remove first element - no need to reallocate
    if(index == 0){array = array[1 .. $];}
    //remove last element - no need to reallocate
    else if(index + 1 == array.length){array = array[0 .. index];}
    //remove from the middle - ~ forces reallocate
    else{array = array[0 .. index] ~ array[index + 1 .. $];}
}
///Unittest for remove_first() and both versions of remove()
unittest
{
    class Element
    {
        int a_, b_;
        this(int a, int b){a_ = a; b_ = b;}

        override bool opEquals(Object o)
        {
            assert(o.classinfo is Element.classinfo);
            auto e = cast(Element)o;
            return a_ == e.a_ && b_ == e.b_;
        }

        //compares sums of both elements.
        override int opCmp(Object o)
        {
            assert(o.classinfo is Element.classinfo);
            auto e = cast(Element)o;
            return a_ + b_ - (e.a_ + e.b_);
        }
    }

    Element[] default_array = [new Element(0, 1),
                               new Element(1, 0),
                               new Element(1, 0),
                               new Element(0, 1),
                               new Element(0, 1)];


    //test remove
    Element[] array = default_array.dup;

    //these shouldn't remove anything
    array.remove(new Element(1, 1));
    assert(array == default_array);
    remove!(Element, true)(array, new Element(0, 1));
    assert(array == default_array);

    //ensure we remove the wanted element from all indices it is at
    array[4] = array[3];
    remove!(Element, true)(array, array[4]);
    assert(array == default_array[0 .. 3]);
    //ensure we remove all matching elements
    array.remove(new Element(1, 0));
    assert(array == default_array[0 .. 1]);


    //test function remove
    array = default_array.dup;
    //this shouldn't remove anything
    array.remove((ref Element e){return false;});
    assert(array == default_array);

    //should remove all elements as comparison compares sum of their members
    array.remove((ref Element e){return e < new Element(1, 1);});
    assert(array == cast(Element[])[]);

    //test remove_index
    array = default_array.dup;
    array.remove_index(0);
    assert(array == default_array[1 .. $]);
    array.remove_index(array.length - 1);
    assert(array == default_array[1 .. $ - 1]);
    array.remove_index(1);
    assert(array == default_array[1 .. 2] ~ default_array[3 .. $ - 1]);
}
