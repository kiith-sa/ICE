
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Dynamic array struct that never moves its contents in memory.
module containers.segmentedvector;


import core.stdc.string;
import std.algorithm;
import std.range;
import std.traits;

import memory.memory;

import containers.fixedarray;
import containers.vector;


/**
 * Dynamic array with manually managed memory that never moves its contents in memory.
 *
 * Pointers to elements of a SegmentedVector are safe, unlike Vector which can
 * move its contents on reallocation.
 *
 * To simplify its implementation, SegmentedVector is not copyable at the moment.
 * This could be changed if needed, however.
 */
struct SegmentedVector(T, long segmentSize = 1024)
    if(segmentSize > 0)
{
    private:
        Vector!(FixedArray!T) segments_;

        //segmentSize means we need to allocate a new segment (which we do need at start).
        uint usedInLastSegment_ = segmentSize;

        @disable this(T[]);

        @disable this(SegmentedVector);

        @disable this(this);

        @disable void opAssign(T[]);

        @disable void opAssign(SegmentedVector);

        @disable hash_t toHash;

    public:
        /**
         * Foreach over values.
         *
         * Foreach will iterate over all elements in linear order from start to end.
         */
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            const s = segments_.length;
            if(s > 1) foreach(ref seg; segments_[0 .. s - 1]) foreach(ref elem; seg)
            {
                result = dg(elem);
                if(result){break;}
            }
            if(s > 0) foreach(ref elem; segments_.back[0 .. usedInLastSegment_])
            {
                result = dg(elem);
                if(result){break;}
            }
            return result;
        }

        /**
         * Foreach over indices and values.
         *
         * Foreach will iterate over all elements in linear order from start to end.
         */
        int opApply(int delegate(size_t, ref T) dg)
        {
            int result = 0;
            const s = segments_.length;
            size_t i = 0;
            if(s > 1) foreach(ref seg; segments_[0 .. s - 1]) foreach(ref elem; seg)
            {
                result = dg(i, elem);
                if(result){break;}
                ++i;
            }
            if(s > 0) foreach(ref elem; segments_.back[0 .. usedInLastSegment_])
            {
                result = dg(i, elem);
                if(result){break;}
                ++i;
            }
            return result;
        }

        ///Append an element to the vector. (operator ~=)
        void opCatAssign(U : T)(U element) 
               if(isImplicitlyConvertible!(T, U))
        in
        {
            assert(usedInLastSegment_ <= segmentSize,
                   "More items than segmentSize used in the last segment");
        }
        body
        {
            if(usedInLastSegment_ == segmentSize)
            {
                segments_ ~= FixedArray!T(segmentSize);
                usedInLastSegment_ = 0;
            }
            segments_.back[usedInLastSegment_] = element;
            ++usedInLastSegment_;
        }

        /**
         * Get element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.
         *
         * Returns: Element at the specified index.
         */
        auto ref inout(T) opIndex(const size_t index) inout pure nothrow
        in{assert(index < length, "Vector index out of bounds");}
        body
        {
            return segments_[index / segmentSize][index % segmentSize];
        }

        /**
         * Set element at the specified index.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, const size_t index)
        in{assert(index < length, "Vector index out of bounds");}
        body
        {
            segments_[index / segmentSize][index % segmentSize] = value;
        }

        ///Access the first element of the vector.
        ref inout(T) front() inout pure nothrow {return this[0];}

        ///Access the last element of the vector.
        ref inout(T) back() inout pure nothrow {return this[this.length - 1];}

        ///Remove the last element of the vector.
        void popBack() {length = length - 1;}

        ///Get number of elements in the vector.
        @property size_t length() const pure nothrow 
        {
            const result = segmentSize * (cast(long)segments_.length - 1) + usedInLastSegment_;
            assert(result >= 0, "SegmentedVector returned length is less than 0");
            return cast(size_t)result;
        }

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
            if(elements > length)
            {
                auto elementsLeft = elements - length;
                const lastSegmentFree = segmentSize - usedInLastSegment_;
                const addedToLastSegment = min(elementsLeft, lastSegmentFree);

                usedInLastSegment_ += addedToLastSegment;
                elementsLeft -= addedToLastSegment;

                while(elementsLeft > 0)
                {
                    segments_ ~= FixedArray!T(segmentSize);
                    usedInLastSegment_ = cast(uint)min(elementsLeft, segmentSize);
                    elementsLeft -= usedInLastSegment_;
                }
            }
            else if(elements < length)
            {
                auto elementsLeft = length - elements;
                const removedFromLastSegment = min(elementsLeft, usedInLastSegment_);
                const oldLastSegmentUsed = usedInLastSegment_;
                usedInLastSegment_ -= removedFromLastSegment;
                elementsLeft -= removedFromLastSegment;

                //Destroy removed elements.
                foreach(ref elem; segments_.back[usedInLastSegment_ .. oldLastSegmentUsed])
                {
                    clear(elem);
                }

                while(elementsLeft > 0)
                {
                    //Destroys elements automatically.
                    segments_.length = segments_.length - 1;
                    usedInLastSegment_ = cast(uint)max(0, segmentSize - cast(long)elementsLeft);
                    elementsLeft -= (segmentSize - usedInLastSegment_);
                }
            }
        }
}
import util.unittests;
///Unittest for SegmentedVector.
void unittestSegmentedVector()
{
    SegmentedVector!(uint, 3) vector;
    vector ~= 1;
    vector ~= 2;
    vector ~= 3;
    vector ~= 4;
    assert(vector.length == 4);

    assert(vector[0] == 1);

    uint i = 1;
    foreach(elem; vector)
    {
        assert(i == elem);
        i++;
    }

    vector.length = 58;
    assert(vector.length == 58);

    vector.length = 2;
    assert(vector.length == 2);
}
mixin registerTest!(unittestSegmentedVector, "SegmentedVector general");

