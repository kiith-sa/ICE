module util;


///Remove element from the array.
/**
  * Only the first occurence of elem will be removed.
  * @param array Array to remove from.
  * @param elem Element to remove.
  * @param ident Remove exactly elem (i.e. is elem) instead of anything equal to elem (== elem).
  */
void remove(T)(ref T[] array, T element, bool ident = false)
{
    foreach(index, array_element; array)
    {
        if(ident ? array_element is element : array_element == element)
        {
            //remove the slot from slots
            if(index == 0)
            {
                array = array[1 .. $];
            }
            else if(index + 1 == array.length)
            {
                array = array[0 .. index];
            }
            else
            {
                array = array[0 .. index] ~ array[index + 1 .. $];
            }
            return;
        }
    }
    assert(0, "Trying to remove an element not present in the array");
}


///Remove elements from an array according to a function.
/**
  * @param array Array to remove from.
  * @param deleg Function determining whether to remove an element.
  *              Any element for which deleg returns true is removed.
  */
void remove(T)(ref T[] array, bool delegate(ref T) deleg)
{
    uint elems = array.length;
    for(int elem = elems - 1; elem >= 0; --elem)
    {
        if(deleg(array[elem]))
        {
            if(elem == 0)
            {
                array = array[1 .. $];
            }
            else if(elem + 1 == array.length)
            {
                array = array[0 .. elem];
            }
            else
            {
                array = array[0 .. elem] ~ array[elem + 1 .. $];
            }
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
    foreach(index, ref element; array)
    {
        if(deleg(element)){return index;}
    }
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
