
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module containers.array;


import std.math;


/**
 * Remove first occurence of an element from the array.
 *
 * Params:  array = Array to remove from.
 *          elem  = Element to remove from the array.
 *          ident = If true, remove exactly elem (is elem) instead 
 *                  of anything equal to elem (== elem).
 *                  Only makes sense for reference types.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * array.remove_first(1); //Removes the first 1, other 1 stays in the array.
 * --------------------
 * 
 * --------------------
 * //Assuming Foo is a class defined somewhere prior with a constructor
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
    foreach(index, ref array_element; array)
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
void remove(T)(ref T[] array, T element, bool ident = false)
{
    remove(array, ident ? (ref T elem){return cast(bool)(elem is element);} 
                        : (ref T elem){return cast(bool)(elem == element);});
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
///Unittest for remove_first() and both versions of remove()
unittest
{
    class Element
    {
        int a_, b_;
        this(int a, int b){a_ = a; b_ = b;}
        bool opEquals(Element e){return a_ == e.a_ && b_ == e.b_;}
        //compares sums of both elements.
        int opCmp(Element e){return a_ + b_ - (e.a_ + e.b_);}
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

/**
 * Find an element in an array with a function.
 *
 * Params:  array = Array to search in.
 *          deleg = Function determining if this is the element we're looking for.
 *                  Index of the first element for which this function returns true
 *                  will be returned.
 *
 * Returns: Index of the element if found, -1 otherwise.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 4, 3];
 * size_t i = array.find((ref int i){return i >= 3;}); //i is 3 (fourth element).
 * i = array.find((ref int i){return i > 4;});      //i is -1 (no element is greater than 4).
 * --------------------
 */
int find(T)(ref T[] array, bool delegate(ref T) deleg)
out(result){assert(result < cast(int)array.length, "Find result out of bounds");}
body
{
    foreach(index, ref element; array){if(deleg(element)){return cast(int)index;}}
    return -1;
}
///Unittest for find().
unittest
{
    int[] array = [1, 2, 1, 4, 3];
    assert(array.find((ref int i){return i >= 3;}) == 3);
    assert(array.find((ref int i){return i > 4;}) == -1);
}

/**
 * Determine whether or not does an array contain an element.
 *
 * Params:  array = Array to check.
 *          elem  = Element to look for.
 *          ident = If true, look exactly for elem (is elem) instead 
 *                  of anything equal to elem (== elem).
 *                  Only makes sense for reference types.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * bool c = array.contains(1); //c is true.
 * c = array.contains(5);      //c is false.
 * --------------------
 * 
 * --------------------
 * //Assuming Foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * bool c = array.contains(array[3], true); //c is true.
 * c = array.contains(new Foo(1), true);    //c is false.
 * c = array.contains(new Foo(1));          //c is true.
 * --------------------
 */
bool contains(T)(T[] array, T element, bool ident = false)
{
    foreach(array_element; array)
    {
        if(ident ? array_element is element : array_element == element){return true;}
    }
    return false;
}
///Unittest for contains().
unittest
{
    class Element
    {
        int a_, b_;
        this(int a, int b){a_ = a; b_ = b;}
        int opEquals(Element e){return a_ == e.a_ && b_ == e.b_;}
    }

    Element[] array = [new Element(0, 1),
                       new Element(1, 0),
                       new Element(1, 0),
                       new Element(0, 1),
                       new Element(0, 1)];


    assert(!array.contains(new Element(1, 1)));
    assert(!array.contains(new Element(0, 1), true));
    assert(array.contains(array[3], true));
    assert(array.contains(new Element(0, 1)));
}

/**
 * Returns minimum value of an array.
 *
 * Uses the > operator (opCmp for structs and classes) to get the minimum.
 * If more than one element in the array is the minimum, any one of them could
 * be returned.
 *
 * Params:  array = Array to find the minimum in. Must not be empty.
 *
 * Returns: Minimum of the array.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * int minimum = array.min(); //minimum is 1
 * array = [];
 * minimum = array.min();     //ERROR, can't get minimum of an empty array.
 * --------------------
 *
 * --------------------
 * //Assuming Foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters,
 * //and has an opCmp operator result of which is integer comparison of parameters
 * //passed to constructors of the instances.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * Foo minimum = array.min(); //minimum is the first or third element of the array.
 * --------------------
 */
T min(T) (T array []){return min(array, (ref T a, ref T b){return a > b;});}

/**
 * Returns minimum value of an array using a function to compare elements.
 *
 * If more than one element in the array is the minimum, any one of them could
 * be returned.
 *
 * Params:  array = Array to find the minimum in. Must not be empty.
 *          deleg = Comparison function. Takes two parameters of the type stored 
 *                  in the array by reference and returns a bool that is true 
 *                  when the first parameter is greater than second, false otherwise.
 *
 * Returns: Minimum of the array.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * int minimum = array.min((ref int a, ref int b){return a < b;}); //minimum is 3
 * array = [];
 * minimum = array.min(); //ERROR, can't get minimum of an empty array.
 * --------------------
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

/**
 * Returns maximum value of an array.
 *
 * Uses the > operator (opCmp for structs and classes) to get the maximum.
 * If more than one element in the array is the maximum, any one of them could
 * be returned.
 *
 * Params:  array = Array to find the maximum in. Must not be empty.
 *
 * Returns: Maximum of the array.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * int maximum = array.max; //maximum is 3
 * array = [];
 * maximum = array.max();   //ERROR, can't get maximum of an empty array.
 * --------------------
 *
 * --------------------
 * //Assuming Foo is a class defined somewhere prior with a constructor
 * //that always constructs identical instance when given identical parameters,
 * //and has an opCmp operator result of which is integer comparison of parameters
 * //passed to constructors of the instances.
 *
 * Foo[] array = [new Foo(1), new Foo(2), new Foo(1), new Foo(2)];
 * Foo maximum = array.max(); //maximum is the second or fourth element of the array.
 * --------------------
 */
T max(T) (T array []){return max(array, (ref T a, ref T b){return a > b;});}

/**
 * Returns maximum value of an array using a function to compare elements.
 *
 * If more than one element in the array is the maximum, any one of them could
 * be returned.
 *
 * Params:  array = Array to find the maximum in. Must not be empty.
 *          deleg = Comparison function. Takes two parameters of the type stored 
 *                  in the array by reference and returns a bool that is true 
 *                  when the first parameter is greater than second, false otherwise.
 *
 * Returns: Maximum of the array.
 *
 * Examples:
 * --------------------
 * int[] array = [1, 2, 1, 3];
 * int maximum = array.max((ref int a, ref int b){return a > b;}); //maximum is 3
 * array = [];
 * maximum = array.max(); //ERROR, can't get maximum of an empty array.
 * --------------------
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
///Unittest for all min() and max() functions.
unittest
{
    class Element
    {
        int a_, b_;
        this(int a, int b){a_ = a; b_ = b;}
        //compares sums of both elements.
        int opCmp(Element e){return a_ + b_ - (e.a_ + e.b_);}
    }

    Element[] array = [new Element(5, 1),
                       new Element(1, 6),
                       new Element(3, -2),
                       new Element(9, -1),
                       new Element(5, 2)];

    int[] array_ints = [2, 1, 4, 5, -5];
    assert(array_ints.min() == -5);
    assert(array.min() is array[2]);
    assert(array_ints.min((ref int a, ref int b){return abs(a) > abs(b);}) == 1);
    assert(array_ints.min((ref int a, ref int b){return a < b;}) == 5);

    array_ints = [-2, 1, -4, -5, -5];
    assert(array_ints.max() == 1);
    assert(array.max() is array[3]);
    assert(array_ints.max((ref int a, ref int b){return abs(a) > abs(b);}) == -5);
    assert(array_ints.max((ref int a, ref int b){return a > b;}) == 1);
}
