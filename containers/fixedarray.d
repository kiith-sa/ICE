
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Fixed-size array struct.
module containers.fixedarray;


import core.stdc.string;
import std.algorithm;
import std.range;
import std.traits;

import memory.allocator;
import memory.memory;


///Simple fixed-size array with manually managed memory, with interface similar to D array.
struct FixedArray(T, Allocator = DirectAllocator)
    if(Allocator.canAllocate!T)
{
    private:
        ///Manually allocated data storage.
        T[] data_ = null;

    public:
        ///Construct a FixedArray with specified length.
        this(const size_t length) 
        out(result)
        {
            assert(this.length == length, "Unexpected FixedArray length");
        }
        body
        {
            data_ = Allocator.allocArray!T(length);
        }

        ///Destroy the array.
        ~this()
        {
            if(data_ !is null)
            {
                Allocator.free(data_);
                data_ = null;
            }
        }

        /**
         * Assign to another array. This will destroy any
         * data owned by this array and copy data to this array.
         *
         * Params:  v = Vector to assign.
         */
        void opAssign(FixedArray rhs)
        {
            //We can swap because a is copied by postblit since it's by-value.
            //Subsequently, rhs will own our original data and deallocate it at dtor.
            swap(data_, rhs.data_);
        }

        ///Postblit constructor.
        this(this)
        {
            if(data_ is null){return;}
            auto otherData = data_;
            data_   = Allocator.allocArray!T(otherData.length);
            data_[] = otherData[];
        }

        ///Compute a hash.
        hash_t toHash() const @trusted
        {
            static type = typeid(T);
            return type.getHash(&data_[0 .. $]);
        }

        /**
         * Foreach over values.
         *
         * Foreach will iterate over all elements of the array in linear order
         * from start to end.
         */
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            foreach(i; 0 .. data_.length)
            {
                result = dg(data_[i]);
                if(result){break;}
            }
            return result;
        }

        /**
         * Foreach over indices and values.
         *
         * Foreach will iterate over all elements of the array in linear order
         * from start to end.
         */
        int opApply(int delegate(ref size_t, ref T) dg)
        {
            int result = 0;
            foreach(i; 0 .. data_.length)
            {
                result = dg(i, data_[i]);
                if(result){break;}
            }
            return result;
        }

        /**
         * Get element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.
         *
         * Returns: Element at the specified index.
         */
        auto ref inout(T) opIndex(const size_t index) inout pure nothrow
        in{assert(index < data_.length, "FixedArray index out of bounds");}
        body{return data_[index];}

    /* Disable for non-copyable data types 
     *
     * We also require T.init here, but we already require that
     * for the FixedArray itself.
     */
    static if(__traits(compiles, FixedArray!T().data_[0] = T.init))
    {
        /**
         * Set element at the specified index.
         *
         * This method only exists if T is copyable.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, const size_t index)
        in{assert(index < data_.length, "FixedArray index out of bounds");}
        body
        {
            data_[index] = value;
        }

        /**
         * Assign a slice of the array from a D array.
         *
         * This method only exists if T is copyable.
         *
         * Params:  array = Array to assign to.
         *          start = Start of the slice.
         *          end   = End of the slice.
         */
        void opSliceAssign(T[] array, const size_t start, const size_t end) 
        in
        {
            assert(array.length == end - start, "Slice lengths for assignment don't match");
            assert(end <= data_.length, "Array slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body
        {
            data_[start .. end] = array[0 .. $];
        }
    }

        /**
         * Get a slice of the array as a D array.
         *
         * Params:  start = Start of the slice.
         *          end   = End of the slice.
         */
        inout(T[]) opSlice(const size_t start, const size_t end) inout pure nothrow
        in
        {
            assert(end <= data_.length, "FixedArray slice index out of bounds");
            assert(start <= end, "Slice start greater than slice end");
        }
        body{return data_[start .. end];}

        ///Get a slice of the whole array as a D array.
        inout(T)[] opSlice() inout pure nothrow {return data_[0 .. $];}

        ///Access the first element of the array.
        ref inout(T) front() inout pure nothrow {return data_[0];}

        ///Access the last element of the array.
        ref inout(T) back() inout pure nothrow {return data_[$ - 1];}

        ///Get number of elements in the array.
        @property size_t length() const pure nothrow {return data_.length;}

        ///Is the array empty?
        @property bool empty() const pure nothrow {return data_.length == 0;}
}
import util.unittests;
///Unittest for FixedArray.
void unittestFixedArray()
{
    {
        FixedArray!float scopeNull;
    }
    {
        alias FixedArray!float I;
        auto nested = FixedArray!I(5);
        nested[0] = FixedArray!float(5);
        nested[1] = FixedArray!float(5);
        nested[3] = FixedArray!float(5);
        nested[4] = FixedArray!float(5);

        auto newNested = FixedArray!I(11);

        newNested[0] = move(nested[0]);

        nested = move(newNested);
    }

    auto fixed = FixedArray!uint(4);
    assert(fixed.length == 4);
    fixed[0] = 1;
    fixed[1] = 2;
    fixed[2] = 3;
    fixed[3] = 4;
    assert(fixed.length == 4);

    assert(fixed[0] == 1);

    uint i = 1;
    foreach(elem; fixed)
    {
        assert(i == elem);
        assert(canFind(fixed[], i));
        i++;
    }
}
mixin registerTest!(unittestFixedArray, "FixedArray general");
