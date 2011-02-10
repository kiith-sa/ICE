module containers.array;


import std.math;


///Remove first occurence of an element from the array.
/**
  * @param array Array to remove from.
  * @param elem Element to remove.
  * @param ident Remove exactly elem (i.e. is elem) instead of anything equal to elem (== elem).
  */
void remove_first(T)(ref T[] array, T element, bool ident = false)
{
    foreach(index, array_element; array)
    {
        if(ident ? array_element is element : array_element == element)
        {
            //remove first element - no need to reallocate
            if(index == 0){array = array[1 .. $];}
            //remove last element - no need to reallocate
            else if(index + 1 == array.length){array = array[0 .. index];}
            //remove from the middle - ~ forces reallocate
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
 *         elem  = Element to remove.
 *         ident = Remove exactly elem (i.e. is elem) instead of anything equal to elem (== elem).
 */
void remove(T)(ref T[] array, T element, bool ident = false)
{
    remove(array, ident ? (ref T elem){return cast(bool)(elem == element);} 
                        : (ref T elem){return elem is element;});
}

///Remove elements from an array according to a function.
/**
  * @param array Array to remove from.
  * @param deleg Function determining whether to remove an element.
  *              Any element for which deleg returns true is removed.
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
