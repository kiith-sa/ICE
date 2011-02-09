module vector;


import allocator;


/**
 * Simple dynamic array with manually managed memory, similar to C++ vector.
 *
 * Only bare requirements are implemented. Can be improved if needed.
 */
struct Vector(T)
{
    private:
        //Manually allocated data storage. More storage than used can be allocated.
        T[] data_;

        //Used storage (number of items in the vector).
        uint used_;

    public:
        ///Construct an empty vector.
        static Vector opCall()
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

        ///Used by foreach.
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

        ///Append an element to the vector.
        void opCatAssign(T element)
        {
            //if out of space, reallocate.
            if(used_ >= data_.length){data_ = realloc(data_, data_.length * 2);}

            data_[used_] = element;
            used_++;
        }

        /**
         * Get element at the specified index.
         *
         * Index must not be out of bounds.
         *
         * Params:  index = Index of the element to get.
         *
         * Returns: Element at the specified index.
         */
        T opIndex(uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{return data_[index];}

        /**
         * Set element at the specified index.
         *
         * Index must not be out of bounds.
         *
         * Params:  index = Index of the element to set.
         */
        void opIndexAssign(T value, uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{data_[index] = value;}

        /**
         * Get a pointer to element at the specified index.
         *
         * Index must not be out of bounds.
         *
         * Params:  index = Index of the element to get.
         *
         * Returns: Pointer to the element at the specified index.
         */
        T* ptr(uint index)
        in{assert(index < used_, "Vector index out of bounds");}
        body{return &data_[index];}

        //In D2, this should return const
        ///Access vector contents as an array.
        T[] array(){return data_[0 .. used_];}

        /**
         * Remove element from the vector.
         *
         * If more elements match specified element, all of them will be removed.
         *
         * Params:  element = Element to remove.
         *          ident   = Remove exactly specified element (i.e. is element)
         *                    instead of just anything equal to element (== element).
         */
        void remove(T element, bool ident = false)
        {
            for(int i = used_ - 1; i >= 0; i--)
            {
                if(ident ? data_[i] is element : data_[i] == element)
                {
                    remove_at_index(i);
                }
            }
        }

        ///Remove elements from vector according to a function.
        /**
         * Params:  deleg = Function determining whether to remove an element.
         *                  Any element for which deleg returns true is removed.
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
         * Must be within bounds.
         *
         * Params:  index = Index to remove at.
         */
        void remove_at_index(uint index)
        in{assert(index < used_, "Index of element to remove from vector out of bounds");}
        body
        {
            for(uint i = index + 1; i < used_; i++){data_[i - 1] = data_[i];}
            used_--;
        }

        /**
         * Determine whether or not the vector contains specified element.
         *
         * Params:  element = Element to look for.
         *          ident   = Look exactly for specified element (i.e. is element)
         *                    instead of just anything equal to element (== element).
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
         * be erased. If higher, the vector will be expanded.
         *
         * Params:  length = length to set.
         */
        void length(uint length)
        {
            if(length > data_.length){data_ = realloc(data_, length);}
            used_ = length;
        }
}
unittest
{
    auto vector = Vector!(uint)();
    vector ~= 1;
    vector ~= 2;
    vector ~= 3;
    vector ~= 4;
    assert(vector.length == 4);

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
    vector.die();
}
