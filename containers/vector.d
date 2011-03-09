
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module containers.vector;


import std.c.string;

import memory.memory;
import math.math;


/**
 * Simple dynamic array with manually managed memory, with interface similar to D array.
 *
 *
 * Only bare requirements are implemented. Can be improved if needed.
 *
 * If storing references to classes, arrays or pointers to garbage collected 
 * memory, it should be ensured that these don't accidentally get collected 
 * as the garbage collector does not see manually allocated memory.
 * This could be done for instance by having other references to
 * those classes/arrays/memory outside manually allocated memory.
 */
align(1) struct Vector(T)
{
    invariant(){assert(data_ !is null, "Vector data is null - probably not constructed");}
    private:
        ///Manually allocated data storage. More storage than used can be allocated.
        T[] data_;
        ///Used storage (number of items in the vector).
        uint used_;

    public:
        ///Construct an empty vector.
        static Vector opCall()
        out(result){assert(result.used_ == 0, "Constructed vector expected to be empty");}
        body
        {
            Vector!(T) result;
            result.data_ = alloc!(T)(2);
            return result;
        }

        ///Construct a vector from an array.
        static Vector opCall(T[] array)
        out(result){assert(result.used_ == array.length, "Unexpected vector length");}
        body
        {
            Vector!(T) result;
            result.data_ = alloc!(T)(max(2u, array.length));
            //copy array data
            result.data_[] = array;
            result.used_ = array.length;
            return result;
        }

        ///Destroy the vector.
        void die()
        {
            used_ = 0;
            free(data_);
        }

        /**
         * Used by foreach.
         *
         * Foreach will iterate over all elements of the vector in linear order
         * from start to end.
         */
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            for(uint i = 0; i < used_; i++)
            {
                result = dg(data_[i]);
                if(result){break;}
            }
            return result;
        }

        /**
         * Used by foreach.
         *
         * Foreach will iterate over all elements of the vector in linear order
         * from start to end.
         */
        int opApply(int delegate(ref uint, ref T) dg)
        {
            int result = 0;
            for(uint i = 0; i < used_; i++)
            {
                result = dg(i, data_[i]);
                if(result){break;}
            }
            return result;
        }

        ///Append an element to the vector. (~= operator)
        void opCatAssign(T element)
        out
        {
            assert(opIndex(length - 1) == element, 
                   "Appended element isn't at the end of vector");
        }
        body
        {
            //if out of space, reallocate.
            reserve(used_ + 1);
            data_[used_] = element;
            used_++;
        }

        ///Append contents of an array to the vector. (~= operator)
        void opCatAssign(T[] array)
        in
        {
            assert(array.ptr + array.length <= data_.ptr || 
                   array.ptr >= data_.ptr + data_.length,
                   "Can't append an overlapping array to a vector.");
        }
        body
        {
            //if out of space, reallocate.
            reserve(used_ + array.length);
            //copy array data
            data_[used_ .. used_ + array.length] = array;
            used_ += array.length;
        }

        ///Append contents of a vector to the vector. (~= operator)
        void opCatAssign(Vector!(T) vector){opCatAssign(vector.array);}

        /**
         * Assign array to the vector. This will destroy any
         * data owned by this vector and copy array data to this vector.
         *
         * Params:  array = Array to assign.
         */
        void opAssign(T[] array)
        {
            reserve(array.length);
            data_[0 .. array.length] = array;
            used_ = array.length;
        }

        /**
         * Get element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.
         *
         * Returns: Element at the specified index.
         */
        T opIndex(size_t index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{return data_[index];}

        /**
         * Set element at the specified index.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, size_t index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{data_[index] = value;}

        /**
         * Copy array to specified slice of the vector.
         *
         * Array and slice length must match.
         *
         * Params:  array = Array to copy.
         *          start = Start of the slice.
         *          end   = End of the slice.
         */
        void opSliceAssign(T[] array, size_t start, size_t end)
        in
        {
            assert(array.length == end - start, "Slice lengths for assignment don't match");
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{data_[start .. end] = array;}

        /**
         * Get a slice of the vector as a D array.
         *
         * Params:  start = Start of the slice.
         *          end   = End of the slice.
         */
        T[] opSlice(size_t start, size_t end)
        in
        {
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{return data_[start .. end];}

        //In D2, this should return const if possible
        /**
         * Get a pointer to element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.  
         *
         * Returns: Pointer to the element at the specified index.
         */
        T* ptr(size_t index)
        in{assert(index < used_, "Vector index out of bounds");}
        out(result)
        {
            assert(result >= data_.ptr && result < data_.ptr + data_.length,
                   "Pointer returned by vector access is out of bounds");
        }
        body{return &data_[index];}

        ///Access vector contents as an array.
        T[] array(){return data_[0 .. used_];}

        ///Access vector contents through a pointer.
        T* ptr(){return data_.ptr;}

        /**
         * Remove element from the vector.
         *
         * All matching elements will be removed. 
         *
         * Params:  element = Element to remove.
         *          ident   = If true, remove exactly elem (is elem) instead 
         *                    of anything equal to elem (== elem). 
         *                    Only makes sense for reference types.
         */
        void remove(T element, bool ident = false)
        {
            foreach_reverse(i, ref elem; data_[0 .. used_])
            {
                if(ident ? elem is element : elem == element){remove_at_index(i);}
            }
        }

        /**
         * Remove elements from vector with a function.
         *
         * Params:  deleg = Function determining whether to remove an element.
         *                  Any element for which this function returns true is removed.
         */
        void remove(bool delegate(ref T) deleg)
        {
            for(int i = used_ - 1; i >= 0; i--)
            {
                if(deleg(data_[i])){remove_at_index(i);}
            }
        }

        /**
         * Remove element at specified index.
         *
         * Params:  index = Index to remove at. Must be within bounds.
         */
        void remove_at_index(uint index)
        in{assert(index < used_, "Index of element to remove from vector out of bounds");}
        body
        {
            for(uint i = index + 1; i < used_; i++){data_[i - 1] = data_[i];}
            used_--;
        }

        /**
         * Determine whether or not does the vector contain an element.
         *
         * Params:  element = Element to look for.
         *          ident   = If true, look exactly for elem (is elem) instead 
         *                    of anything equal to elem (== elem).
         *                    Only makes sense for reference types.
         *
         * Returns: True if the vector contains the element, false otherwise.
         */
        bool contains(T element, bool ident = false)
        {
            for(uint i = 0; i < used_; i++)
            {
                if(ident ? data_[i] is element : data_[i] == element){return true;}
            }
            return false;
        }

        ///Get number of elements in the vector.
        uint length(){return used_;}

        /**
         * Change length of the vector.
         * 
         * If the length will be lower than current length, trailing elements will
         * be erased. If higher, the vector will be expanded. Values of the extra
         * elements after expansion are NOT defined.
         *
         * Params:  length = length to set.
         */
        void length(uint length)
        {
            reserve(length);
            used_ = length;
        }

        ///Reserve space for at least specified number of elements.
        void reserve(uint elements)
        {
            if(elements > data_.length){data_ = realloc(data_, elements);}
        }

        ///Get currently allocated capacity.
        size_t allocated(){return data_.length;}
}
///Unittest for Vector.
unittest
{
    auto vector = Vector!(uint)();
    scope(exit){vector.die();}
    vector ~= 1;
    vector ~= 2;
    vector ~= 3;
    vector ~= 4;
    assert(vector.length == 4);

    assert(vector[0] == 1 && *vector.ptr(0) == 1);

    uint i = 1;
    foreach(elem; vector)
    {
        assert(i == elem);
        assert(vector.contains(i));
        i++;
    }

    vector.remove(1);
    assert(vector.length == 3);
    i = 2;
    foreach(elem; vector)
    {
        assert(i == elem);
        assert(vector.contains(i));
        i++;
    }

    vector.remove(4);
    i = 2;
    foreach(elem; vector)
    {
        assert(i == elem);
        assert(vector.contains(i));
        i++;
    }
    assert(vector.length == 2);

    vector.length = 5;
    assert(vector.length == 5);
    assert(vector.array.length == 5);

    uint[] array = [1, 2, 3];
    vector ~= array;
    assert(vector.length == 8);
    assert(vector.array[$ - array.length .. $] == array);

    vector[0 .. array.length] = array;
    assert(vector[0 .. array.length] == array);

    vector = array;
    assert(vector.array == array);

    auto vector2 = Vector!(uint)(array);
    scope(exit){vector2.die();}
    assert(vector2.array == array);
}
