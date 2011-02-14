
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module containers.vector;


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
            if(used_ >= data_.length){data_ = realloc(data_, data_.length * 2);}

            data_[used_] = element;
            used_++;
        }

        /**
         * Get element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.
         *
         * Returns: Element at the specified index.
         */
        T opIndex(uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{return data_[index];}

        /**
         * Set element at the specified index.
         *
         * Params:  index = Index of the element to set. Must be within bounds. 
         */
        void opIndexAssign(T value, uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{data_[index] = value;}

        //In D2, this should return const if possible
        /**
         * Get a pointer to element at the specified index.
         *
         * Params:  index = Index of the element to get. Must be within bounds.  
         *
         * Returns: Pointer to the element at the specified index.
         */
        T* ptr(uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        out(result)
        {
            assert(result >= data_.ptr && result < data_.ptr + data_.length,
                   "Pointer returned by vector access is out of bounds");
        }
        body{return &data_[index];}

        //In D2, this should return const if possible
        ///Access vector contents as an array.
        T[] array(){return data_[0 .. used_];}

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
            if(length > data_.length){data_ = realloc(data_, length);}
            used_ = length;
        }
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
}
