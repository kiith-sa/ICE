
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module containers.vector;
@trusted


import std.algorithm;
import std.c.string;

import memory.memory;


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
    //commented out due to compiler bug
    //invariant(){assert(data_ !is null, "Vector data is null - probably not constructed");}

    private:
        //using dummy array for default initialization as we can't redefine default ctor
        ///Manually allocated data storage. More storage than used can be allocated.
        T[] data_ = [];
        ///Used storage (number of items in the vector).
        size_t used_ = 0;

    public:
        ///Construct an empty vector with allocated space for specified number of elements.
        this(in size_t reserve)
        out(result){assert(result.used_ == 0, "Constructed vector expected to be empty");}
        body
        {
            data_ = alloc_array!(T)(cast(uint)max(2, reserve));
        }

        ///Construct a vector from an array.
        this(in T[] array)
        out(result){assert(result.used_ == array.length, "Unexpected vector length");}
        body
        {
            data_ = alloc_array!(T)(cast(uint)max(2, array.length));
            //copy array data
            data_[] = array;
            used_ = array.length;
        }

        ///Destroy the vector.
        ~this()
        {
            used_ = 0;
            if(data_ != [] && data_ !is null)
            {
                free(data_);
                data_ = null;
            }
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
            if(data_.length == used_){reserve((data_.length + 1) * 2);}
            data_[used_] = element;
            used_++;
        }

        ///Append contents of an array to the vector. (~= operator)
        void opCatAssign(in T[] array)
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
        void opCatAssign(ref Vector!(T) vector){opCatAssign(vector.array);}

        /**
         * Assign array to the vector. This will destroy any
         * data owned by this vector and copy array data to this vector.
         *
         * Params:  array = Array to assign.
         */
        void opAssign(in T[] array)
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
        const(T)opIndex(in size_t index) const
        in{assert(index < used_, "Vector index out of bounds");}
        body{return data_[index];}

        /**
         * Set element at the specified index.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, in size_t index)
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
        void opSliceAssign(in T[] array, in size_t start, in size_t end)
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
        T[] opSlice(in size_t start, in size_t end)
        in
        {
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{return data_[start .. end];}

        /**
         * Get a const pointer to element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.  
         *
         * Returns: Pointer to the element at the specified index.
         */
        const(T*) ptr(in size_t index) const
        in{assert(index < used_, "Vector index out of bounds");}
        out(result)
        {
            assert(result >= data_.ptr && result < data_.ptr + data_.length,
                   "Pointer returned by vector access is out of bounds");
        }
        body{return &data_[index];}

        ///Access vector contents as a const array.
        @property const(T[]) array() const {return data_[0 .. used_];}

        ///Access vector contents as a non-const array.
        @property T[] array_unsafe(){return data_[0 .. used_];}
        
        ///Access vector contents through a const pointer.
        const(T*) ptr() const {return data_.ptr;}
        
        ///Access vector contents through a non-const pointer.
        T* ptr_unsafe(){return data_.ptr;}

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
        void remove(in T element, in bool ident = false)
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
        void remove(in bool delegate(ref T) deleg)
        {
            for(long i = cast(long)used_ - 1; i >= 0; i--)
            {
                if(deleg(data_[cast(size_t)i])){remove_at_index(cast(size_t)i);}
            }
        }

        /**
         * Remove element at specified index.
         *
         * Params:  index = Index to remove at. Must be within bounds.
         */
        void remove_at_index(in size_t index)
        in{assert(index < used_, "Index of element to remove from vector out of bounds");}
        body
        {
            for(size_t i = index + 1; i < used_; i++){data_[i - 1] = data_[i];}
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
        bool contains(in T element, in bool ident = false) const
        {
            for(uint i = 0; i < used_; i++)
            {
                if(ident ? data_[i] is element : data_[i] == element){return true;}
            }
            return false;
        }

        ///Get number of elements in the vector.
        @property size_t length() const {return used_;}

        /**
         * Change length of the vector.
         * 
         * If the length will be lower than current length, trailing elements will
         * be erased. If higher, the vector will be expanded. Values of the extra
         * elements after expansion are NOT defined.
         *
         * Params:  length = length to set.
         */
        @property void length(in size_t length)
        {
            used_ = length;
            //awkward control flow due to optimization. we realloc if elements > data_.length
            if(length <= data_.length){return;}
            data_ = (data_ != []) ? realloc(data_, cast(uint)length) 
                                  : alloc_array!T(cast(uint)length);
        }

        ///Reserve space for at least specified number of elements.
        void reserve(in size_t elements)
        {
            //awkward control flow due to optimization. we realloc if elements > data_.length
            if(elements <= data_.length){return;}

            data_ = (data_ != []) ? realloc(data_, cast(uint)elements) 
                                  : alloc_array!T(cast(uint)elements);
        }

        ///Get currently allocated capacity.
        @property size_t allocated() const {return data_.length;}
}
///Unittest for Vector.
unittest
{
    Vector!(uint) vector = Vector!(uint)();
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
    assert(vector2.array == array);
}
