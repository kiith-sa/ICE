module array2d;


import allocator;


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
        body{return data[y * x_ + x];}

        /**
         * Set an element of the array.
         * 
         * Params:  x = X coordinate of the element to set.
         *          y = Y coordinate of the element to set.
         */
        void opIndexAssign(T value, uint x, uint y)
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{data[y * x_ + x] = value;}

        ///Destroy the array.
        void die(){free(data);}

        ///Get width of the array.
        uint x(){return x_;}

        ///Get height of the array.
        uint y(){return y_;}
}
