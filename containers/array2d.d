
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///2D array struct.
module containers.array2d;
@trusted


import memory.memory;


/**
 * Fixed size 2D array struct with manually managed memory.
 *
 * If storing references to classes, arrays or pointers to garbage collected 
 * memory, it should be ensured that these don't accidentally get collected 
 * as the garbage collector does not see manually allocated memory.
 * This could be done for instance by having other references to
 * those classes/arrays/memory outside manually allocated memory.
 *
 * Examples:
 * --------------------
 * //Construct a 4*4 2D array of uints. Contents will be default initialized,
 * //i.e. 0 for uints.
 * Array2D array = Array2D!(uint)(4, 4);
 * //Destroy the array at exit.
 *
 * //Set element at coords X1,Y1 to 1
 * array[1, 1] = 1;
 *
 * //Get the value at X1,Y1, to a, i.e. a is now 1.
 * uint a = array[1, 1]; 
 * --------------------
 */
align(1) struct Array2D(T)
{
    private:
        static enum T[] dummy_data_ = [];

        ///Manually allocated data storage.
        T[] data_ = dummy_data_;
        ///Array width.
        uint x_ = 0;
        ///Array height.
        uint y_ = 0;

    public:
        /**
         * Construct a 2D array.
         *
         * Contents of the array will be default-initialized, e.g., if the 
         * array stores uints, each element will be 0. 
         *
         * Params:  x = Array width.
         *          y = Array height.
         */
        this(in uint x, in uint y)
        out(result)
        {
            assert(x_ == x && y == y && data_.length == x * y,
                   "Error in Array2D construction");
        }
        body
        {
            x_ = x;
            y_ = y;
            data_ = alloc_array!(T)(x * y);
        }

        ///Destroy the array.
        ~this()
        {
            if(data_ !is null){free(data_);}
        }

        /**
         * Used by foreach. 
         *
         * Foreach will iterate over all elements of the array, but in undefined order.
         */
        int opApply(int delegate(ref T) dg)
        {
            int result = 0;
            for(size_t i = 0; i < data_.length; i++)
            {
                result = dg(data_[i]);
                if(result){break;}
            }
            return result;
        }

        /**
         * Get a reference to an element of the array.
         * 
         * Params:  x = X coordinate of the element.
         *          y = Y coordinate of the element.
         *
         * Returns: Element at the specified coordinates.
         */
        ref inout(T) opIndex(in uint x, in uint y) inout
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{return data_[y * x_ + x];}

        /**
         * Set an element of the array.
         * 
         * Params:  x = X coordinate of the element.
         *          y = Y coordinate of the element.
         */
        void opIndexAssign(T value, in uint x, in uint y)
        in{assert(x < x_ && y < y_, "2D array access out of bounds");}
        body{data_[y * x_ + x] = value;}

        ///Get width of the array.
        @property uint x() const {return x_;}

        ///Get height of the array.
        @property uint y() const {return y_;}
}
///Unittest for Array2D.
unittest
{
    auto array = Array2D!(uint)(4,4);

    //default initialization
    assert(array[0,0] == 0);

    //setting and getting of elements
    array[1,1] = 1;
    assert(array[1,1] == 1);

    //iteration over all the elements
    uint elems = 0;
    foreach(elem; array){elems++;}
    assert(elems == 16);
}
