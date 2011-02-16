
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.math;


import std.math;
import std.random;


///Epsilon (acceptable error in fuzzy comparison/rounding) for 32bit floats.
const f32_epsilon = float.epsilon * 500.0;
///Epsilon (acceptable error in fuzzy comparison/rounding) for 64bit floats.
const f64_epsilon = double.epsilon * 500.0;
///Epsilon (acceptable error in fuzzy comparison/rounding) for widest floats (reals).
const fmax_epsilon = real.epsilon * 500.0;
///Epsilon (acceptable error in fuzzy comparison) for 32bit uints.
const uint uint_epsilon = 0;
///Epsilon (acceptable error in fuzzy comparison) for 32bit ints.
const int int_epsilon = 0;
///Epsilon (acceptable error in fuzzy comparison) for 16bit uints.
const ushort ushort_epsilon = 0;
///Epsilon (acceptable error in fuzzy comparison) for 16bit ints.
const short short_epsilon = 0;
///Epsilon (acceptable error in fuzzy comparison) for 8bit uints.
const ubyte ubyte_epsilon = 0;
///Epsilon (acceptable error in fuzzy comparison) for 8bit ints.
const byte byte_epsilon = 0;


/**
 * Fuzzy equality test for floats.
 *
 * Params:  f1        = First float to test.
 *          f2        = Second float to test.
 *          tolerance = Acceptable difference to consider f1 and f2 equal.
 *
 * Returns: True if f1 and f2 are equal, false otherwise.
 */
bool equals(float f1, float f2, float tolerance = f32_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
///Unittest for float equals() .
unittest
{
    assert(equals(7.0f / 5.0f, 1.4f));
    assert(!equals(7.0f / 5.0f, 1.4002f));
    assert(equals(7.0f, 5.0f, 2.0f));
}

/**
 * Fuzzy equality test for doubles.
 *
 * Params:  f1        = First double to test.
 *          f2        = Second double to test.
 *          tolerance = Acceptable difference to consider f1 and f2 equal.
 *
 * Returns: True if f1 and f2 are equal, false otherwise.
 */
bool equals(double f1, double f2, double tolerance = f64_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
///Unittest for double equals() .
unittest
{
    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}

/**
 * Fuzzy equality test for reals.
 *
 * Params:  f1        = First real to test.
 *          f2        = Second real to test.
 *          tolerance = Acceptable difference to consider f1 and f2 equal.
 *
 * Returns: True if f1 and f2 are equal, false otherwise.
 */
bool equals(real f1, real f2, real tolerance = f64_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
///Unittest for real equals() .
unittest
{
    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}

/**
 * Fuzzy equality test for uints.
 *
 * Params:  i1        = First uint to test.
 *          i2        = Second uint to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(uint i1, uint i2, uint tolerance = uint_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Fuzzy equality test for ints.
 *
 * Params:  i1        = First int to test.
 *          i2        = Second int to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(int i1, int i2, int tolerance = int_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Fuzzy equality test for ushorts.
 *
 * Params:  i1        = First ushort to test.
 *          i2        = Second ushort to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(ushort i1, ushort i2, ushort tolerance = ushort_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Fuzzy equality test for shorts.
 *
 * Params:  i1        = First short to test.
 *          i2        = Second short to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(short i1, short i2, short tolerance = short_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Fuzzy equality test for ubytes.
 *
 * Params:  i1        = First ubyte to test.
 *          i2        = Second ubyte to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(ubyte i1, ubyte i2, ubyte tolerance = ubyte_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Fuzzy equality test for bytes.
 *
 * Params:  i1        = First byte to test.
 *          i2        = Second byte to test.
 *          tolerance = Acceptable difference to consider i1 and i2 equal.
 *
 * Returns: True if i1 and i2 are equal, false otherwise.
 */
bool equals(byte i1, byte i2, byte tolerance = byte_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

/**
 * Accumulating function.
 *
 * For each element in array elems, expression seed = fun(seed, element)
 * is evaluated. The resulting value of seed is returned.
 * This is useful for e.g. computing the minimum value of an array,
 * sum, etc.
 *
 * Params:  fun   = (template alias) Function to process elems with.
 *          seed  = Starting value of seed.
 *          elems = Array to process.
 *
 * Returns: Resulting value of seed.
 */
T reduce(alias fun, T)(T seed, T elems [])
{
    foreach(elem; elems[]){seed = fun(seed, elem);}
    return seed;
}

/**
 * Clamps a value to specified range.
 *
 * Params:  v       = Value to clamp.
 *          minimum = Minimum of the range. 
 *          maximum = Maximum of the range.
 *
 * Returns: Clamped value.
 */
T clamp(T)(T v, T minimum, T maximum)
in{assert(minimum <= maximum, "Clamp range minimum greater than maximum");}
body{return min(maximum, max(minimum, v));}
///Unittest for clamp() .
unittest
{
    assert(clamp(1.1, -1.0, 2.0) == 1.1);
    assert(clamp(1.1, 2.0, 3.0) == 2.0);
    assert(clamp(1.1, -1.0, 1.0) == 1.0);
}

/**
 * Returns minimum of two values.
 *
 * Params:  a = First value.
 *          b = Second value.
 *
 * Returns: Smaller of the two values.
 */
T min(T) (T a, T b){return b < a ? b : a;}

/**
 * Returns minimum of a variable number of values.
 *
 * Params:  elems = Values to get minimum from. Must not be empty.
 *
 * Returns: Smallest of the values.
 */
T min(T) (T elems [] ...)
in{assert(elems.length != 0, "Can't get a minimum from an array of 0 elements");}
body
{
    if(elems.length == 1){return elems[0];}
    if(elems.length == 2){return min(elems[0], elems[1]);}
    return reduce!(min)(T.max, elems);
}

/**
 * Returns maximum of two values.
 *
 * Params:  a = First value.
 *          b = Second value.
 *
 * Returns: Greater of the two values.
 */
T max(T) (T a, T b){return b < a ? a : b;}

/**
 * Returns maximum of a variable number of values.
 *
 * Params:  elems = Values to get maximum from. Must not be empty.
 *
 * Returns: Greatest of the values.
 */
T max(T) (T elems [] ...)
in{assert(elems.length != 0, "Can't get a maximum from an array of 0 elements");}
body
{
    if(elems.length == 1){return elems[0];}
    if(elems.length == 2){return max(elems[0], elems[1]);}
    return reduce!(max)(T.min, elems);
}

/**
 * Round a float value to nearest signed 32-bit int.
 *
 * Params:  f = Float to round.
 *
 * Returns: Nearest int to given value.
 */
int round_s32(T) (T f){return cast(int)round(f);}

/**
 * Floor a float value to an unsigned 8-bit int.
 *
 * Params:  f = Float to round. Must be less than 256 and greater or equal to 0.
 *                                                                                   
 * Returns: Floor of given value as ubyte.
 */
ubyte floor_u8(float f)
{
    f += 256.0f;
    return cast(ubyte)(((*cast(uint*)&f)&0x7fffff)>>15);
}
///Unittest for floor_u8.
unittest
{
    assert(floor_u8(255.001) == 255);
    assert(floor_u8(8.001) == 8);
    assert(floor_u8(7.999) == 7);
}

/**
 * Floor a double value to a signed 32-bit int
 *
 * Params:  f = Double to round. Must be less than 2^31 and greater or equal to -(2^31).
 *
 * Returns: Floor of given value as int.
 */
int floor_s32(double f)
{
    //2 ^ 36 * 1.5,  (52 - 16 == 36) uses limited precisicion to floor
    f += 68719476736.0*1.5; 
    return (*cast(int*)&f) >> 16;
}                                                                                      
///Unittest for floor_s32.
unittest
{
    assert(floor_s32(8.00001) == 8);
    assert(floor_s32(7.99999) == 7);
    assert(floor_s32(-0.00001) == -1);
}

/**
 * Return a random real in specified range (minimum and maximum included).
 *
 * Params:  min = Minimum of the range. 
 *          max = Maximum of the range. 
 *
 * Returns: Random value in specified range.
 */
real random(real min, real max)
out(result){assert(result >= min && result <= max, "Random number out of range");}
body
{
    real scale = cast(real)std.c.stdlib.rand() / int.max;
    return min + (max - min) * scale;
}

///Array of first 32 powers of 2.
const uint[] powers_of_two = generate_pot();

///Generate the powers_of_two array and return it.
private uint[] generate_pot()
{
    uint[] pot;
    for(uint p = 0; p < 32; ++p){pot ~= cast(uint)pow(cast(real)2, p);}
    return pot;
}
///Unittest for generate_pot().
unittest
{
    assert(powers_of_two[0] == 1);
    assert(powers_of_two[1] == 2);
    assert(powers_of_two[8] == 256);
    assert(powers_of_two[14] == 16384);
}

/**
 * Get the smallest power of two greater or equal to given number.
 *
 * Params:  num = Number to get ceiling power of two to.
 *
 * Returns: Smallest power of two greater or equal to given number.
 */
uint pot_ceil(uint num)
in{assert(num <= powers_of_two[$ - 1], "Can't compute ceiling power of two for huge ints");}
body
{
    foreach(pot; powers_of_two)
    {
        if(pot >= num){return pot;}
    }
    assert(false);
}
///Unittest for pot_ceil.
unittest
{
    assert(pot_ceil(65535) == 65536);
    assert(pot_ceil(8) == 8);
    assert(pot_ceil(9) == 16);
    assert(pot_ceil(12486) == 16384);
}

/**
 * Determine if the given number is a power of two.
 *
 * Params:  num = Number to check.
 *
 * Returns: True if the number is a power of two, false otherwise.
 */
bool is_pot(uint num)
{
    foreach(pot; powers_of_two)
    {
        if(pot == num){return true;}
    }
    return false;
}
