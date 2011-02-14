
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module containers.array;


import std.math;
import std.string;


/**
 * Remove first occurence of an element from the array.
 *
 * Params: array = Array to remove from.
 *         elem  = Element to remove from the array.
 *         ident = If true, remove exactly elem (i.e. is elem) instead 
 *                 of anything equal to elem (== elem).
 *                 Only makes sense for reference types.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove_first(1); //Removes the first 1, other 1 stays in the array.
 * --------------------
 * 
 * --------------------
 * //Assuming foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * array.remove_first(array[3], true);   //Removes the last Foo.
 * array.remove_first(new Foo(1), true); //Removes nothing.
 * array.remove_first(new Foo(1));       //Removes the first Foo.
 * --------------------
 */
void remove_first(T)(ref T[] array, T element, bool ident = false)
{
    foreach(index, array_element; array)
    {
        if(ident ? array_element is element : array_element == element)
        {
            //remove the first element - no need to reallocate
            if(index == 0){array = array[1 .. $];}
            //remove the last element - no need to reallocate
            else if(index + 1 == array.length){array = array[0 .. index];}
            //remove from the middle - ~ forces reallocation
            else{array = array[0 .. index] ~ array[index + 1 .. $];}
            return;
        }
    }
}

/**
 * Remove element from the array.
 * 
 * All matching elements will be removed. 
 *
 * Params: array = Array to remove from.
 *         elem  = Element to remove from the array.
 *         ident = Remove exactly elem (i.e. is elem) instead of anything equal to elem (== elem).
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove(1); //Removes the first and the third element.
 * --------------------
 * 
 * --------------------
 * //Assuming foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * array ~= array[3];                    //The last Foo is now in the array twice.
 * array.remove(array[3], true);   //Removes the last two elements (indices 3 and 4)
 * array.remove(new Foo(1), true); //Removes nothing.
 * array.remove(new Foo(1));       //Removes the first and third element.
 * --------------------
 */
void remove(T)(ref T[] array, T element, bool ident = false)
{
    remove(array, ident ? (ref T elem){return cast(bool)(elem is element);} 
                        : (ref T elem){return cast(bool)(elem == element);});
}

/**
 * Remove elements from an array with a function.
 *
 * Params: array = Array to remove from.
 *         deleg = Function determining whether to remove an element.
 *                 Any element for which this function returns true is removed.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove((ref int i){return i < 3;}); //Removes all elements smaller than 3.
 * --------------------
 */
void remove(T)(ref T[] array, bool delegate(ref T) deleg)
{
    foreach_reverse(int index, ref elem; array)
    {
        if(deleg(elem))
        {
            //remove first element - no need to reallocate
            if(index == 0){array = array[1 .. $];}
            //remove last element - no need to reallocate
            else if(index + 1 == array.length){array = array[0 .. index];}
            //remove from the middle - ~ forces reallocate
            else{array = array[0 .. index] ~ array[index + 1 .. $];}
        }
    }
}
unittest
{
    class Element
    {
        int a_, b_;
        this(int a, int b){a_ = a; b_ = b;}
        bool opEquals(Element e){return a_ == e.a_ && b_ == e.b_;}
        //compares sums of both elements.
        int opCmp(Element e)
        {
            int s1 = a_ + b_;
            int s2 = e.a_ + e.b_;
            return s1 - s2;
        }
        //used for debugging
        string to_string(){return std.string.toString(a_) ~ "," ~ std.string.toString(b_);}
    }

    Element[] default_array = [new Element(0, 1),
                               new Element(1, 0),
                               new Element(1, 0),
                               new Element(0, 1),
                               new Element(0, 1)];


    //test remove_first
    Element[] array = default_array.dup;

    //these shouldn't remove anything
    array.remove_first(new Element(1, 1));
    assert(array == default_array);
    array.remove_first(new Element(0, 1), true);
    assert(array == default_array);

    //ensure we only remove the wanted element from the first index it is at
    array[4] = array[3];
    array.remove_first(array[4], true);
    assert(array == default_array[0 .. 4]);

    //ensure we only remove the first matching element
    array.remove_first(new Element(0, 1));
    assert(array == default_array[1 .. 4]);


    //test remove
    array = default_array.dup;
    //these shouldn't remove anything
    array.remove(new Element(1, 1));
    assert(array == default_array);
    array.remove(new Element(0, 1), true);
    assert(array == default_array);

    //ensure we remove the wanted element from all indices it is at
    array[4] = array[3];
    array.remove(array[4], true);
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
}

///Find an element in an array using a function.
/**
 * @param array Array to search in.
 * @param deleg Function determining if this is the element we're looking for.
 *              Element for which this function returns true will be found.
 *
 * @return Index of element if found.
 * @return -1 if not found.
 */
int find(T)(ref T[] array, bool delegate(ref T) deleg)
{
    foreach(index, ref element; array){if(deleg(element)){return index;}}
    return -1;
}

///Determine whether or not does an array contain an element.
/**
  * @param array Array to check.
  * @param elem Element to look for.
  * @param ident Look exactly for elem (i.e. is elem) instead of anything equal to elem (== elem).
  */
bool contains(T)(T[] array, T element, bool ident = false)
{
    foreach(array_element; array)
    {
        if(ident ? array_element is element : array_element == element)
        {
            return true;
        }
    }
    return false;
}

/**
 * Returns minimum value from an array.
 *
 * Uses the > operator (opCmp for structs and classes) to get the minimum.
 *
 * Params:  array = Array to find the minimum in. Must not be empty.
 *
 * Returns: Minimum of the array.
 */
T min(T) (T array []){return min(array, (ref T a, ref T b){return a > b;});}

/**
 * Returns minimum value from an array.
 *
 * Uses a function delegate to compare elements and get the minimum.
 *
 * Params:  array = Array to find the minimum in. Must not be empty.
 *          deleg = Function to use for comparison. Must take, by reference,
 *                  two parameters of the type stored in array and return a
 *                  bool value that is true when the first parameter is greater
 *                  than the second, false otherwise.
 *
 * Returns: Minimum of the array.
 */
T min(T) (T array [], bool delegate(ref T a, ref T b) deleg)
in{assert(array.length > 0, "Can't get minimum of an empty array");}
body
{
    //working with pointers to prevent copying when structs are used.
    T* minimum = &array[0];
    foreach(ref elem; array[1 .. $])
    {
        if(deleg(*minimum, elem)){minimum = &elem;}
    }
    return *minimum;
}
unittest
{
    int[5] ints = [2, 1, 4, 5, -5];
    assert(min(ints) == -5);
    assert(min(ints,(ref int a, ref int b){return abs(a) > abs(b);}) == 1);
}

/**
 * Returns maximum value from an array.
 *
 * Uses the > operator (opCmp for structs and classes) to get the maximum.
 *
 * Params:  array = Array to find the maximum in. Must not be empty.
 *
 * Returns: Maximum of the array.
 */
T max(T) (T array []){return max(array, (ref T a, ref T b){return a > b;});}

/**
 * Returns maximum value from an array.
 *
 * Uses a function delegate to compare elements and get the maximum.
 *
 * Params:  array = Array to find the maximum in. Must not be empty.
 *          deleg = Function to use for comparison. Must take, by reference,
 *                  two parameters of the type stored in array and return a
 *                  bool value that is true when the first parameter is greater
 *                  than the second, false otherwise.
 *
 * Returns: Maximum of the array.
 */
T max(T) (T array [], bool delegate(ref T a, ref T b) deleg)
in{assert(array.length > 0, "Can't get maximum of an empty array");}
body
{
    //pretty much the same code as minimum

    //working with pointers to prevent copying when structs are used.
    T* maximum = &array[0];
    foreach(ref elem; array[1 .. $])
    {
        if(deleg(elem, *maximum)){maximum = &elem;}
    }
    return *maximum;
}
unittest
{
    int[5] ints = [-2, 1, -4, -5, -5];
    assert(max(ints) == 1);
    assert(max(ints,(ref int a, ref int b){return abs(a) > abs(b);}) == -5);
}
