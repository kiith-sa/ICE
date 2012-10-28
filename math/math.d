
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Math functions.
module math.math;


import std.algorithm;
import std.math;
import std.traits;

import util.unittests;


///Get epsilon value for a numeric type.
template epsilon(T)
{
    static if(is(T == real))         {const T epsilon = T.epsilon * cast(T)5000;}
    else static if(isFloatingPoint!T){const T epsilon = T.epsilon * cast(T)500;}
    else static if(isIntegral!T)     {const T epsilon = 0;}
    else{static assert(false, "Unsupported type for epsilon: " ~ typeid(T).toString);}
}

/**
 * Fuzzy number equality test.
 *
 * Params:  a         = First number to compare.
 *          b         = Secont number to compare.
 *          tolerance = Comparison tolerance.
 *
 * Returns: True if the numbers are equal, false otherwise.
 */
bool equals(T)(const T a, const T b, const T tolerance = epsilon!T) pure
    if(isNumeric!T)
{
    return (a + tolerance >= b) && (a - tolerance <= b); 
}
void unittestEquals()
{
    assert(equals(7.0f / 5.0f, 1.4f));
    assert(!equals(7.0f / 5.0f, 1.4002f));
    assert(equals(7.0f, 5.0f, 2.0f));

    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}
mixin registerTest!(unittestEquals, "math.math.equals");

/**
 * Clamps a value to specified range.
 *
 * Params:  v       = Value to clamp.
 *          minimum = Minimum of the range. 
 *          maximum = Maximum of the range.
 *
 * Returns: Clamped value.
 */
T clamp(T)(const T v, const T minimum, const T maximum) pure
    if(isNumeric!T)
in{assert(minimum <= maximum, "Clamp range minimum greater than maximum");}
body{return min(maximum, max(minimum, v));}
///Unittest for clamp() .
void unittestClamp()
{
    assert(clamp(1.1, -1.0, 2.0) == 1.1);
    assert(clamp(1.1, 2.0, 3.0) == 2.0);
    assert(clamp(1.1, -1.0, 1.0) == 1.0);
}
mixin registerTest!(unittestClamp, "math.math.clamp");

/**
 * Round a number to the nearest integer of type U.
 *
 * Params:  f = Float to round.
 *
 * Returns: Nearest int to given value.
 */
U round(U, T)(const T f)
    if(isIntegral!U && isNumeric!T)
{
    return cast(U)std.math.round(f);
}

/**
 * Floor a number to an integer of type U.
 *
 * Params:  f = Float to round. Must be less than U.max and more or equal to U.min .
 *                                                                                   
 * Returns: Floor of given value as U.
 */
U floor(U, T)(T f)
    if(isIntegral!U && isNumeric!T)
{
    static if(is(U == ubyte) && is(T == float))
    {
        f += 256.0f;
        return cast(ubyte) (( (*cast(uint*)&f) & 0x7fffff) >> 15);
    }
    else static if(is(U == int) && is(T == double))
    {
        //2 ^ 36 * 1.5,  (52 - 16 == 36) uses limited precisicion to floor
        f += 68719476736.0*1.5; 
        return (*cast(int*)&f) >> 16;
    }
    else
    {
        return cast(U)std.math.floor(f);
    }
}
///Unittest for floor.
void unittestFloor()
{
    assert(floor!ubyte(255.001f) == 255);
    assert(floor!ubyte(8.001f) == 8);
    assert(floor!ubyte(7.999f) == 7);

    assert(floor!int(8.00001) == 8);
    assert(floor!int(7.99999) == 7);
    assert(floor!int(-0.00001) == -1);
}
mixin registerTest!(unittestFloor, "math.math.floor");

///Array of first 32 powers of 2.
uint[] powersOfTwo = generatePot();

///Generate the powersOfTwo array and return it.
private uint[] generatePot()
{
    uint[] pot;
    foreach(p; 0 .. 32){pot ~= cast(uint)pow(cast(real)2, p);}
    return pot;
}
///Unittest for generatePot().
void unittestGeneratePot()
{
    assert(powersOfTwo[0] == 1);
    assert(powersOfTwo[1] == 2);
    assert(powersOfTwo[8] == 256);
    assert(powersOfTwo[14] == 16384);
}
mixin registerTest!(unittestGeneratePot, "math.math.generatePot");

/**
 * Get the smallest power of two greater or equal to given number.
 *
 * Params:  num = Number to get ceiling power of two to.
 *
 * Returns: Smallest power of two greater or equal to given number.
 */
uint potCeil(const uint num) 
in{assert(num <= powersOfTwo[$ - 1], "Can't compute ceiling power of two for huge ints");}
body
{
    foreach(pot; powersOfTwo)
    {
        if(pot >= num){return pot;}
    }
    assert(false);
}
///Unittest for potCeil.
void unittestPotCeil()
{
    assert(potCeil(65535) == 65536);
    assert(potCeil(8) == 8);
    assert(potCeil(9) == 16);
    assert(potCeil(12486) == 16384);
}
mixin registerTest!(unittestPotCeil, "math.math.potCeil");

/**
 * Determine if the given number is a power of two.
 *
 * Params:  num = Number to check.
 *
 * Returns: True if the number is a power of two, false otherwise.
 */
bool isPot(const uint num)
{
    return powersOfTwo.canFind(num);
}

/**
 * Align an unsigned integer to upper multiple of mult.
 *
 * Examples:
 * --------------------
 * assert(alignToUpperMultipleOf(4u, 11u)  == 12);
 * assert(alignToUpperMultipleOf(4u, 12u)  == 12);
 * assert(alignToUpperMultipleOf(5u, 256u) == 260);
 * assert(alignToUpperMultipleOf(5u, 261u) == 265);
 * assert(alignToUpperMultipleOf(1u, 261u) == 261);
 * --------------------
 *
 * Params:  mult = Multiplier to align to. Must not be 0.
 *          num  = Number to align.
 *
 * Returns: Aligned result.
 */
T alignToUpperMultipleOf(T)(const T mult, const T num) pure nothrow
    if(isUnsigned!T)
{
    assert(mult != 0, "Can't align to a multiple of 0");
    return ((num + mult - 1) / mult) * mult;
}
void unittestAlignToUpperMultipleOf()
{
    assert(alignToUpperMultipleOf(4u, 11u)  == 12);
    assert(alignToUpperMultipleOf(4u, 12u)  == 12);
    assert(alignToUpperMultipleOf(5u, 256u) == 260);
    assert(alignToUpperMultipleOf(5u, 261u) == 265);
    assert(alignToUpperMultipleOf(1u, 261u) == 261);
}
mixin registerTest!(unittestAlignToUpperMultipleOf, "math.math.alignToUpperMultipleOf");

