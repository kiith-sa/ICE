
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
 */
align(4) struct Vector(T)
{
    private:
        ///Manually allocated data storage. More storage than used can be allocated.
        T[] data_ = null;
        ///Used storage (number of items in the vector).
        size_t used_ = 0;

        @disable this(T[]);

        @disable this(Vector);

    public:
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
         * Foreach over values.
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
         * Foreach over indices and values.
         *
         * Foreach will iterate over all elements of the vector in linear order
         * from start to end.
         */
        int opApply(int delegate(size_t, ref T) dg)
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
        {
            //if out of space, reallocate.
            if(data_.length == used_){reserve((data_.length + 1) * 2);}
            data_[used_] = element;
            used_++;
        }

        ///Append contents of a vector or an array to the vector.
        void opCatAssign(A)(ref A array)
            if(is(typeof(A.init.ptr)) && is(typeof(A.init.length)) &&
               isImplicitlyConvertible!(T, ElementType!A))
        in
        {
            assert(array.ptr + array.length <= data_.ptr || 
                   array.ptr >= data_.ptr + data_.length,
                   "Can't append an overlapping array to a vector.");
        }
        body
        {
            //If out of space, reallocate.
            reserve(used_ + array.length);
            //Copy array data.
            data_[used_ .. used_ + array.length] = array.ptr[0 .. array.length];
            used_ += array.length;
        }

        ///Postblit constructor.
        this(this)
        {
            if(data_ is null){return;}
            auto otherData = data_;
            data_   = allocArray!T(otherData.length);
            data_[] = otherData[];
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
        auto ref inout(T) opIndex(const size_t index) inout pure nothrow
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
         * Copy an array to specified slice of the vector.
         *
         * Array and slice length must match.
         *
         * Params:  array = Array to copy.
         *          start = Start of the slice.
         *          end   = End of the slice.
         */
        void opSliceAssign(T[] array, const size_t start, const size_t end) 
        in
        {
            assert(array.length == end - start, "Slice lengths for assignment don't match");
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body
        {
            data_[start .. end] = array[0 .. $];
        }

        ///Set all elements in the vector to specified value.
        void opSliceAssign(T value) nothrow
        {
            data_[0 .. used_] = value;
        }

        /**
         * Get a slice of the vector as a D array.
         *
         * Params:  start = Start of the slice.
         *          end   = End of the slice.
         */
        inout(T[]) opSlice(const size_t start, const size_t end) inout pure nothrow
        in
        {
            assert(end <= used_, "Vector slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{return data_[start .. end];}

        ///Get a slice of the whole vector as a D array.
        inout(T[]) opSlice() inout pure nothrow {return this[0 .. used_];}

        ///Access the first element of the vector.
        ref inout(T) front() inout pure nothrow {return this[0];}

        ///Access the last element of the vector.
        ref inout(T) back() inout pure nothrow {return this[this.length - 1];}

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
        const(T*) ptr() const pure nothrow {return data_.ptr;}
        
        ///Access vector contents through a non-const pointer.
        T* ptrUnsafe() pure nothrow {return data_.ptr;}

        ///Get number of elements in the vector.
        @property size_t length() const pure nothrow {return used_;}

        ///Is the vector empty?
        @property bool empty() const pure nothrow {return length == 0;}

        /**
         * Change length of the vector.
         * 
         * If the length will be lower than current length, trailing elements will
         * be erased. If higher, the vector will be expanded. Values of the extra
         * elements after expansion are NOT defined.
         *
         * Params:  elements = length to set.
         */
        @property void length(const size_t elements)
        {
            used_ = elements;
            //Awkward control flow due to optimization. 
            //We realloc if elements > data_.length .
            if(elements <= data_.length)
            {
                static if(hasElaborateDestructor!T)
                {
                    foreach(ref elem; data_[elements .. $]){clear(elem);}
                }
                return;
            }
            data_ = (data_ !is null) ? realloc(data_, elements) 
                                     : allocArray!T(elements);
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
        @property size_t allocated() const pure nothrow {return data_.length;}
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
        assert(canFind(vector[], i));
        i++;
    }

    vector.length = 5;
    assert(vector.length == 5);
    assert(vector[].length == 5);

    uint[] array = [1, 2, 3];
    vector ~= array;
    assert(vector.length == 8);
    assert((vector[])[$ - array.length .. $] == array);

    vector[0 .. array.length] = array;
    assert(vector[0 .. array.length] == array);

    Vector!uint vector2;
    vector2 = array;
    assert(vector2[] == array);
}
