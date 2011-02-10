module containers.array2d;


import memory.memory;


///Fixed size 2D array struct with manually managed memory.
struct Array2D(T)
{
    private:
        //Width of the array.
        uint x_;
        //Height of the array.
        uint y_;
        //Manually allocated data storage of the array.
        T[] data_;

    public:
        /**
         * Construct a 2D array.
         *
         * Params:  x = Width of the array.
         *          y = Height of the array.
         *
         * Returns: 2D Array with specified dimensions.
         */
        static Array2D opCall(uint x, uint y)
        {
            Array2D!(T) result;
            result.x_ = x;
            result.y_ = y;
            result.data_ = alloc!(T)(x * y);
            result.data_.length = x * y;
            return result;
        }

        ///Destroy the array.
        void die()
        {
            x_ = y_ = 0;
            free(data_);
        }

        ///Used by foreach.
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            for(uint i = 0; i < data_.length; i++)
            {
                result = dg(data_[i]);
                if(result){break;}
            }
            return result;
        }

        /**
         * Get an element of the array.
         * 
         * Params:  x = X coordinate of the element to get.
         *          y = Y coordinate of the element to get.
         *
         * Returns: Element at the specified coordinates.
         */
        T opIndex(uint x, uint y)
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{return data_[y * x_ + x];}

        /**
         * Get a pointer to an element of the array.
         * 
         * Params:  x = X coordinate of the element to get pointer to.
         *          y = Y coordinate of the element to get pointer to.
         *
         * Returns: Element at the specified coordinates.
         */
        T* ptr(uint x, uint y)
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{return &(data_[y * x_ + x]);}

        /**
         * Set an element of the array.
         * 
         * Params:  x = X coordinate of the element to set.
         *          y = Y coordinate of the element to set.
         */
        void opIndexAssign(T value, uint x, uint y)
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{data_[y * x_ + x] = value;}

        ///Get width of the array.
        uint x(){return x_;}

        ///Get height of the array.
        uint y(){return y_;}
}
unittest
{
    auto array = Array2D!(uint)(4,4);
    scope(exit){array.die();}
    assert(array[0,0] == 0);
    array[1,1] = 1;
    assert(array[1,1] == 1);
    assert(*array.ptr(1,1) == 1);
}
