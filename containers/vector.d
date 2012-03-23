
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Dynamic array struct.
module containers.vector;


import core.stdc.string;
import std.algorithm;
import std.range;
import std.traits;

import memory.memory;


/**
 * Simple dynamic array with manually managed memory, with interface similar to D array.
 *
 *
 * Only bare requirements are implemented. Can be improved if needed.
 *
 * Note:
 *
 * Vector is buggy, in particular with respect to copying. It will be rewritten
 * or replaced by std.containers.array in future. Use FixedArray if possible.
 */
align(4) struct Vector(T)
{
    private:
        ///Manually allocated data storage. More storage than used can be allocated.
        T[] data_ = null;
        ///Used storage (number of items in the vector).
        size_t used_ = 0;

    public:
        ///Construct a vector from a range.
        this(R)(R range)
            if(is(typeof(R.init.ptr)) && is(typeof(R.init.length)) &&
               isImplicitlyConvertible!(T, ElementType!R))
        out(result){assert(result.used_ == range.length, "Unexpected vector length");}
        body
        {
            data_ = allocArray!T(max(2, range.length));
            //copy array data
            data_[] = range.ptr[0 .. range.length];
            used_ = range.length;
        }

        ///Destroy the vector.
        ~this()
        {
            if(data_ !is null)
            {
                free(data_);
                data_ = null;
            }
        }

        ///Compute a hash.
        hash_t toHash() const
        {
            static type = typeid(T);
            return type.getHash(&data_[0 .. used_]);
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
            foreach(i; 0 .. used_)
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
        int opApply(int delegate(ref size_t, ref T) dg)
        {
            int result = 0;
            foreach(i; 0 .. used_)
            {
                result = dg(i, data_[i]);
                if(result){break;}
            }
            return result;
        }

        ///Append an element to the vector. (operator ~=)
        void opCatAssign(U : T)(U element) 
               if(isImplicitlyConvertible!(T, U))
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

        ///Append contents of a range to the vector. (~= operator)
        void opCatAssign(R)(ref R range)
            if(is(typeof(R.init.ptr)) && is(typeof(R.init.length)) &&
               isImplicitlyConvertible!(T, ElementType!R))
        in
        {
            assert(range.ptr + range.length <= data_.ptr || 
                   range.ptr >= data_.ptr + data_.length,
                   "Can't append an overlapping array to a vector.");
        }
        body
        {
            //if out of space, reallocate.
            reserve(used_ + range.length);
            //copy array data
            data_[used_ .. used_ + range.length] = range.ptr[0 .. range.length];
            used_ += range.length;
        }

        /**
         * Assign another vector to the vector. This will destroy any
         * data owned by this vector and copy data to this vector.
         *
         * Params:  v = Vector to assign.
         */
        void opAssign(ref Vector v)
        {
            opAssign(v.data_[0 .. v.used_]);
        }

        /**
         * Assign an array to the vector. This will destroy any
         * data owned by this vector and copy data to this vector.
         *
         * Params:  array = Array to assign.
         */
        void opAssign(T[] array)
        {
            reserve(array.length);
            static if(hasElaborateDestructor!T) if(array.length < data_.length) 
            {
                foreach(ref elem; data_[array.length .. $]){clear(elem);}
            }
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
        ref const(T) opIndex(const size_t index) const pure
        in{assert(index < used_, "Vector index out of bounds");}
        body{return data_[index];}

        /**
         * Set element at the specified index.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, const size_t index)
        in{assert(index < used_, "Vector index out of bounds");}
        body
        {
            data_[index] = value;
        }

        /**
         * Copy range to specified slice of the vector.
         *
         * Range and slice length must match.
         *
         * Params:  range = Range to copy.
         *          start = Start of the slice.
         *          end   = End of the slice.
         */
        void opSliceAssign(R)(R range, const size_t start, const size_t end) 
            if(is(typeof(R.init.ptr)) && is(typeof(R.init.length)) &&
               isImplicitlyConvertible!(T, ElementType!R))
        in
        {
            assert(range.length == end - start, "Slice lengths for assignment don't match");
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body
        {
            data_[start .. end] = range.ptr[0 .. range.length];
        }

        ///Set all elements in the vector to specified value.
        void opSliceAssign()(T value)
        {
            data_[0 .. used_] = value;
        }

        /**
         * Get a slice of the vector as a D array.
         *
         * Params:  start = Start of the slice.
         *          end   = End of the slice.
         */
        const(T[]) opSlice(const size_t start, const size_t end) const
        in
        {
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{return data_[start .. end];}

        ///Get a slice of the whole vector as a D array.
        const(T[]) opSlice() const {return this[0 .. used_];}

        ///Access the first element of the vector.
        ref const(T) front() const pure {return this[0];}

        ///Access the last element of the vector.
        ref const(T) back() const pure {return this[this.length - 1];}

        ///Remove the last element of the vector.
        void popBack() {length = length - 1;}

        /**
         * Get a const pointer to element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.  
         *
         * Returns: Pointer to the element at the specified index.
         */
        const(T*) ptr(const size_t index) const pure
        in{assert(index < used_, "Vector index out of bounds");}
        out(result)
        {
            assert(result >= data_.ptr && result < data_.ptr + data_.length,
                   "Pointer returned by vector access is out of bounds");
        }
        body{return &data_[index];}

        ///Access vector contents through a const pointer.
        const(T*) ptr() const pure {return data_.ptr;}
        
        ///Access vector contents through a non-const pointer.
        T* ptrUnsafe() pure {return data_.ptr;}

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
        void remove(T element, const bool ident = false)
        {
            foreach_reverse(i, ref elem; data_[0 .. used_])
            {
                if(ident ? elem is element : elem == element){removeAtIndex(i);}
            }
        }

        /**
         * Remove elements from vector with a function.
         *
         * Params:  deleg = Function determining whether to remove an element.
         *                  Any element for which this function returns true is removed.
         */
        void remove(const bool delegate(ref T) deleg)
        {
            for(long i = cast(long)used_ - 1; i >= 0; i--)
            {
                if(deleg(data_[cast(size_t)i])){removeAtIndex(cast(size_t)i);}
            }
        }

        /**
         * Remove element at specified index.
         *
         * Params:  index = Index to remove at. Must be within bounds.
         */
        void removeAtIndex(const size_t index)
        in{assert(index < used_, "Index of element to remove from vector out of bounds");}
        body
        {
            foreach(i; index + 1 .. used_)
            {
                data_[i - 1] = data_[i];
            }
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
        bool contains(T element, const bool ident = false) const
        {
            foreach(i; 0 .. used_)
            {
                if(ident ? data_[i] is element : data_[i] == element){return true;}
            }
            return false;
        }

        ///Get number of elements in the vector.
        @property size_t length() const pure {return used_;}

        ///Is the vector empty?
        @property bool empty() const pure {return length == 0;}

        /**
         * Change length of the vector.
         * 
         * If the length will be lower than current length, trailing elements will
         * be erased. If higher, the vector will be expanded. Values of the extra
         * elements after expansion are NOT defined.
         *
         * Params:  length = length to set.
         */
        @property void length(const size_t length)
        {
            used_ = length;
            //awkward control flow due to optimization. we realloc if elements > data_.length
            if(length <= data_.length)
            {
                static if(hasElaborateDestructor!T)
                {
                    foreach(ref elem; data_[length .. $]){clear(elem);}
                }
                return;
            }
            data_ = (data_ !is null) ? realloc(data_, length) 
                                     : allocArray!T(length);
        }

        ///Reserve space for at least specified number of elements.
        void reserve(const size_t elements)
        {
            //Awkward control flow due to optimization. 
            //We realloc if elements > data_.length .
            if(elements <= data_.length){return;}

            data_ = (data_ !is null) ? realloc(data_, elements) 
                                     : allocArray!T(elements);
        }

        ///Get currently allocated capacity.
        @property size_t allocated() const pure {return data_.length;}
}
///Unittest for Vector.
unittest
{
    auto vector = Vector!uint();
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
    assert(vector[].length == 5);

    uint[] array = [1, 2, 3];
    vector ~= array;
    assert(vector.length == 8);
    assert((vector[])[$ - array.length .. $] == array);

    vector[0 .. array.length] = array;
    assert(vector[0 .. array.length] == array);

    auto vector2 = Vector!(uint)(array);
    assert(vector2[] == array);
}
