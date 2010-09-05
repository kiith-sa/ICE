module math.math;


import std.math;
import std.random;

const f32_epsilon = float.epsilon * 100.0;
const f64_epsilon = double.epsilon * 100.0;
const fmax_epsilon = real.epsilon * 100.0;
const uint uint_epsilon = 0;
const int int_epsilon = 0;
const ushort ushort_epsilon = 0;
const short short_epsilon = 0;
const ubyte ubyte_epsilon = 0;
const byte byte_epsilon = 0;

///Fuzzy equality test for floats.
bool equals(float f1, float f2, float tolerance = f32_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
unittest
{
    assert(equals(7.0f / 5.0f, 1.4f));
    assert(!equals(7.0f / 5.0f, 1.4001f));
    assert(equals(7.0f, 5.0f, 2.0f));
}

///Fuzzy equality test for doubles.
bool equals(double f1, double f2, double tolerance = f64_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
unittest
{
    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}

///Fuzzy equality test for reals.
bool equals(real f1, real f2, real tolerance = f64_epsilon)
{
    return (f1 + tolerance >= f2) && (f1 - tolerance <= f2); 
}
unittest
{
    assert(equals(7.0 / 5.0, 1.4));
    assert(!equals(7.0 / 5.0, 1.40001));
    assert(equals(7.0, 5.0, 2.0));
}

///Fuzzy equality test for uints.
bool equals(uint i1, uint i2, uint tolerance = uint_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Fuzzy equality test for ints.
bool equals(int i1, int i2, int tolerance = int_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Fuzzy equality test for ushorts.
bool equals(ushort i1, ushort i2, ushort tolerance = ushort_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Fuzzy equality test for ushorts.
bool equals(short i1, short i2, short tolerance = short_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Fuzzy equality test for ubytes.
bool equals(ubyte i1, ubyte i2, ubyte tolerance = ubyte_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Fuzzy equality test for bytes.
bool equals(byte i1, byte i2, byte tolerance = byte_epsilon)
{
    return (i1 + tolerance >= i2) && (i1 - tolerance <= i2); 
}

///Accumulating function.
/**
  * For each element in array elems, expression seed = fun(seed, element)
  * is evaluated. The resulting value of seed is returned.
  * This is useful for e.g. computing the minimum value of an array,
  * sum, etc.
  */
T reduce(alias fun, T)(T seed, T elems [])
{
    foreach(elem; elems[]){seed = fun(seed, elem);}
    return seed;
}

///Returns minimum of two values.
T min(T) (T a, T b)
{
    if(b < a){return b;}
    return a;
}

///Returns minimum of three or more values.
T min(T) (T elems [] ...)
in
{
    assert(elems.length > 2, "Variadic min can't process less than 3 elements");
}
body
{
    return reduce!(min)(T.max, elems);
}

///Returns maximum of two values.
T max(T) (T a, T b)
{
    if(b > a){return b;}
    return a;
}

///Returns maximum of three or more values.
T max(T) (T elems [] ...)
in
{
    assert(elems.length > 2, "Variadic max can't process less than 3 elements");
}
body{return reduce!(max)(T.min, elems);}

///Round a float value to a 32-bit int.
int round32(T) (T f){return cast(int)round(f);}

///Return a random real between given numbers
real random(real min, real max)
{
    real scale = cast(real)std.c.stdlib.rand() / int.max;
    return min + (max - min) * scale;
}

const uint[32] powers_of_two = generate_pot().pot;

private struct pot_container{uint[32] pot;}

private pot_container generate_pot()
{
    uint[32] pot;
    pot[0] = 1;
    for(uint p = 1; p < 32; ++p){pot[p] = pot[p - 1] * 2;}
    return pot_container(pot);
}

unittest
{
    assert(powers_of_two[0] == 1);
    assert(powers_of_two[1] == 2);
    assert(powers_of_two[8] == 256);
    assert(powers_of_two[14] == 16384);
    assert(powers_of_two[16] == 65536);
}

uint pot_greater_equal(uint num)
in
{
    assert(num <= powers_of_two[$ - 1], "Can't compute greater or equal power "
                                        "of two for huge ints");
}
body
{
    foreach(pot; powers_of_two)
    {
        if(pot >= num){return pot;}
    }
    assert(false);
}
unittest
{
    assert(pot_greater_equal(65535) == 65536);
    assert(pot_greater_equal(8) == 8);
    assert(pot_greater_equal(9) == 16);
    assert(pot_greater_equal(12486) == 16384);
}

///Determines if the given number is a power of two.
bool is_pot(uint num)
{
    foreach(pot; powers_of_two)
    {
        if(pot == num){return true;}
    }
    return false;
}
