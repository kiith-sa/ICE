
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Fixed size bit array.
module util.bits;


/**
 * Fixed size bit array. 
 *
 * Used to pack many booleans together.
 * No dynamic storage at all is used - all data is stored directly in the 
 * struct.
 *
 * By default, all bits are set to 0.
 */
struct Bits(uint length)
{
    private:
        ///Data storage, in 64bit chunks.
        ulong[(length + 63) / 64] data_;

    public:
        ///Get bit at specified index.
        bool opIndex(const size_t index) const pure nothrow
        in
        {
            assert(index < length, "Bits index outside of bounds");
        }
        body
        {
            const dataIdx = index / 64;
            const bitIdx  = index % 64;

            return cast(bool)(data_[dataIdx] & (1L << bitIdx));
        }

        ///Set bit at specified index.
        void opIndexAssign(const bool value, const size_t index) pure nothrow
        in
        {
            assert(index < length, "Bits index outside of bounds");
        }
        out
        {
            assert(this[index] == value);
        }
        body
        {
            const dataIdx = index / 64;
            const bitIdx  = index % 64;

            data_[dataIdx] = value ? (data_[dataIdx] | (1L << bitIdx))
                                   : (data_[dataIdx] & ~(1L << bitIdx));
        }

        ///Set all bits to zero.
        void zeroOut() pure nothrow
        {
            data_[] = 0;
        }
}
unittest
{
    Bits!256 bits;
    foreach(b; 0 .. 256)
    {
        assert(bits[b] == false);
    }

    bits[175] = true;
    foreach(b; 0 .. 256)
    {
        assert((b == 175 ? bits[b] == true : bits[b] == false));
    }
    bits[175] = false;
    foreach(b; 0 .. 256)
    {
        assert(bits[b] == false);
    }
}

