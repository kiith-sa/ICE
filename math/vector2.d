
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.vector2;


import std.math;
import std.random;
import std.traits;

import math.math;


///2D vector or point.
align(1) struct Vector2(T)
    if(isNumeric!T)
{
    //initialized to null vector by default
    ///X component of the vector.
    T x = 0;
    ///Y component of the vector.
    T y = 0;

    ///Negation.
    Vector2!T opNeg() const {return Vector2!T(-x, -y);}

    ///Equality with a vector.
    bool opEquals(const ref Vector2!T v) const
    {
        return equals(x, v.x) && equals(y, v.y);
    }

    ///Addition with a vector.
    Vector2!T opAdd (in Vector2!T v) const 
    {
        return Vector2!T(cast(T)(x + v.x), cast(T)(y + v.y));
    }

    ///Subtraction with a vector.
    Vector2!T opSub(in Vector2!T v) const
    {
        return Vector2!T(cast(T)(x - v.x), cast(T)(y - v.y));
    }

    ///Multiplication with a scalar.
    Vector2!T opMul(in T m) const
    {
        return Vector2!T(cast(T)(x * m), cast(T)(y * m));
    }

    ///Division by a scalar. 
    Vector2!T opDiv(in T d) const
    in{assert(d != 0, "Vector can not be divided by zero");}
    body{return Vector2!T(cast(T)(x / d), cast(T)(y / d));}

    ///Division by a vector. 
    Vector2!T opDiv(in Vector2!T v) const
    in{assert(v.x != 0 && v.y != 0, "Vector can not be divided by a vector with a zero component");}
    body{return Vector2!T(cast(T)(x / v.x), cast(T)(y / v.y));}

    ///Addition-assignment with a vector.
    void opAddAssign(in Vector2!T v)
    {
        x += v.x;
        y += v.y;
    }

    ///Subtraction-assignment with a vector.
    void opSubAssign(in Vector2!T v)
    {
        x -= v.x;
        y -= v.y;
    }

    ///Multiplication-assignment by a scalar.
    void opMulAssign(in T m)
    {
        x *= m;
        y *= m;
    }

    ///Division-assignment by a scalar. 
    void opDivAssign(in T d)
    in{assert(d != 0.0, "Vector can not be divided by zero");}
    body
    {
        x /= d;
        y /= d;
    }
    
    ///Get angle of this vector in radians.
    real angle() const
    {
        const real angle = atan2(cast(double)x, cast(double)y);
        if(angle < 0.0){return angle + 2 * PI;}
        return angle;
    }

    ///Set angle of this vector in radians, preserving its length.
    void angle(in real angle)
    {
        const length = length();
        y = cast(T)cos(cast(double)angle);
        x = cast(T)sin(cast(double)angle);
        this *= length;
    }

    ///Get squared length of the vector.
    T length_squared() const {return cast(T)(x * x + y * y);}
    
    ///Get length of the vector fast at cost of some precision.
    T length() const {return length_safe();}

    ///Get length of the vector with better precision.
    T length_safe() const {return cast(T)(sqrt(cast(real)length_squared));}

    /**
     * Dot (scalar) product with another vector.
     *
     * Params:  v = Vector to get dot product with.
     *
     * Returns: Dot product of this and the other vector.
     */
    T dot_product(in Vector2!T v) const {return cast(T)(x * v.x + y * v.y);}

    ///Get normal of this vector (a pependicular vector).
    Vector2!T normal() const {return Vector2!T(-y, x);}

    /**
     * Turns this into a unit vector fast at cost of some precision. 
     *
     * Result is undefined if this is a zero vector.
     */
    void normalize()
    {
        const len = length();
        x /= len;
        y /= len;
        return;
    }

    ///Normalize with better precision, or don't do anything if this is a zero vector.
    void normalize_safe()
    {
        const len = length_safe();
        if(equals(length, cast(T)0)){return;}
        x /= len;
        y /= len;
        return;
    }

    ///Get unit vector of this vector. Result is undefined if this is a zero vector.
    Vector2!T normalized() const
    {
        Vector2!T normalized = this;
        normalized.normalize();
        return normalized;
    }

    ///Turn this vector into a zero vector.
    void zero(){x = y = cast(T)0;}
}

///Get a unit vector with a random direction.
Vector2!T random_direction(T)()
    if(isNumeric!T)
{
    Vector2!T v = Vector2!T(cast(T)1, cast(T)0);
    v.angle(uniform(0, 2 * PI));
    return v;
}

/**
 * Return a random position in a circle.
 *
 * Params:  center = Center of the circle.
 *          radius = Radius of the circle.
 *
 * Returns: Random position in the specified circle.
 */
Vector2!T random_position(T)(Vector2!T  center, T radius)
    if(isNumeric!T)
{
    return center + random_direction!T  * uniform(cast(T)0, radius);
}

/**
 * Convert a Vector2 of one type to other. 
 *
 * Examples: 
 * --------------------
 * Vector2u v_uint = Vector2u(4, 2);
 * //convert to Vector2f
 * Vector2f V_float = to!(float)v_uint;
 * --------------------
 */                  
Vector2!T to(T, U)(Vector2!U v)
    if(isNumeric!T)
{
    return Vector2!T(cast(T)v.x, cast(T)v.y);
}
unittest
{
    assert(to!int(Vector2f(1.1f, 1.1f)) == Vector2i(1,1));
}

///Vector2 of bytes.
alias Vector2!byte Vector2b;
///Vector2 of ubytes.
alias Vector2!ubyte Vector2ub;
///Vector2 of shorts.
alias Vector2!short Vector2s;
///Vector2 of ushorts.
alias Vector2!ushort Vector2us;
///Vector2 of ints.
alias Vector2!int Vector2i;
///Vector2 of uints.
alias Vector2!uint Vector2u;
///Vector2 of floats.
alias Vector2!float Vector2f;
///Vector2 of doubles.
alias Vector2!double Vector2d;
