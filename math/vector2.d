
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///2D vector struct.
module math.vector2;


import std.math;
import std.random;
import std.traits;

import math.math;


///2D vector or point.
struct Vector2(T)
    if(isNumeric!T)
{
    //initialized to null vector by default
    ///X component of the vector.
    T x = 0;
    ///Y component of the vector.
    T y = 0;

    ///Negation.
    Vector2 opNeg() const pure {return Vector2(-x, -y);}

    ///Equality with a vector.
    bool opEquals(const ref Vector2 v) const pure
    {
        return equals(x, v.x) && equals(y, v.y);
    }

    ///Addition/subtraction with a vector.
    Vector2 opBinary(string op)(const Vector2 v) const pure 
        if(op == "+" || op == "-" || op == "/")
    {
        static if(op == "+")     {return Vector2(cast(T)(x + v.x), cast(T)(y + v.y));}
        else static if(op == "-"){return Vector2(cast(T)(x - v.x), cast(T)(y - v.y));}
        else static if(op == "/")
        {
            assert(v.x != 0 && v.y != 0,
                   "Vector can not be divided by a vector with a zero component");
            return Vector2(cast(T)(x / v.x), cast(T)(y / v.y));
        }
    }

    ///Multiplication/division with a scalar.
    Vector2 opBinary(string op, U)(const U m) const pure
        if(isNumeric!U && (op == "*" || op == "/"))
    {
        static if(op == "*"){return Vector2(cast(T)(x * m), cast(T)(y * m));}
        else static if(op == "/")
        {
            assert(m != cast(U)0, "Vector can not be divided by zero");
            return Vector2(cast(T)(x / m), cast(T)(y / m));
        }
    }

    ///Multiplication/division with a scalar.
    Vector2 opBinaryRight(string op, U)(const U m) const pure
        if(isNumeric!U && (op == "*" || op == "/"))
    {
        return opBinary!op(m);
    }

    ///Addition/subtraction with a vector.
    void opOpAssign(string op)(const Vector2 v) pure if(op == "+" || op == "-")
    {
        static if(op == "+")     {x += v.x; y += v.y;}
        else static if(op == "-"){x -= v.x; y -= v.y;}
    }

    ///Multiplication/division with a scalar.
    void opOpAssign(string op, U)(const U m)
        if(isNumeric!U && (op == "*" || op == "/"))
    {
        static if(op == "*")     {x *= m; y *= m;}
        else static if(op == "/")
        {
            assert(m != cast(U)0, "Vector can not be divided by zero");
            x /= m; y /= m;
        }
    }
    
    ///Get angle of this vector in radians.
    @property F angle(F = T)() const pure
        if(isFloatingPoint!F)       
    in
    {
        assert(!isZero, "Trying to get angle of a zero vector");
    }
    body
    {
        const F angle = atan2(cast(double)x, cast(double)y);
        if(angle < 0.0){return angle + 2 * PI;}
        return angle;
    }

    ///Set angle of this vector in radians, preserving its length.
    @property void angle(F)(const F angle) pure
        if(isFloatingPoint!F)
    {
        const length = length();
        y = cast(T)cos(cast(double)angle);
        x = cast(T)sin(cast(double)angle);
        this *= length;
    }
    unittest
    {
        auto v = Vector2f(1.0f, 0.0f);
        v.angle = 1.0f;
        assert(equals(v.angle, 1.0f));
    }

    ///Rotate by specified angle, in radians.
    void rotate(F)(const F angle) pure
        if(isFloatingPoint!F)
    {
        if(isZero){return;}
        this.angle = this.angle + angle;
    }

    ///Return this vector rotated by specified angle, in radians.
    Vector2!T rotated(F)(const F angle) pure const nothrow
        if(isFloatingPoint!F)
    {
        if(isZero){return this;}
        Vector2 result = this;
        result.angle = result.angle + angle;
        return result;
    }

    ///Get squared length of the vector.
    @property T lengthSquared() const pure nothrow {return cast(T)(x * x + y * y);}

    ///Get length of the vector.
    @property T length() const pure nothrow {return cast(T)(sqrt(cast(real)lengthSquared));}

    ///Set length of the vector, resizing it but preserving its direction.
    @property void length(T length) pure nothrow 
    {
        const thisLength = this.length;
        assert(!equals(thisLength, cast(T)0), "Cannot set length of a zero vector!");
        const ratio = length / thisLength;
        x *= ratio;
        y *= ratio;
    }

    /**
     * Dot (scalar) product with another vector.
     *
     * Params:  v = Vector to get dot product with.
     *
     * Returns: Dot product of this and the other vector.
     */
    T dotProduct(const Vector2 v) const pure nothrow {return cast(T)(x * v.x + y * v.y);}

    ///Get normal of this vector (a pependicular vector).
    @property Vector2 normal() const pure nothrow {return Vector2(-y, x);}

    /**
     * Turns this into a unit vector.
     */
    void normalize() pure nothrow
    {
        const len = length();
        if(equals(length, cast(T)0)){return;}
        x /= len;
        y /= len;
        return;
    }

    ///Get unit vector of this vector. Result is undefined if this is a zero vector.
    @property Vector2 normalized() const pure nothrow
    {
        Vector2 normalized = this;
        normalized.normalize();
        return normalized;
    }

    ///Turn this vector into a zero vector.
    void setZero() pure nothrow {x = y = cast(T)0;}

    ///Is this a zero vector?
    bool isZero() pure const nothrow {return equals(x, cast(T)0) && equals(y, cast(T)0);}

    /**
     * Convert a Vector2 of one type to other. 
     *
     * Examples: 
     * --------------------
     * Vector2u v_uint = Vector2u(4, 2);
     * //convert to Vector2f
     * Vector2f V_float = v_uint.to!float
     * --------------------
     */                  
    @property Vector2!T to(T)() const pure nothrow if(isNumeric!T)
    {
        return Vector2!T(cast(T)x, cast(T)y);
    }
    unittest
    {
        assert(Vector2f(1.1f, 1.1f).to!int == Vector2i(1,1));
    }
}

/**
 * Return a random position in a circle.
 *
 * Params:  center = Center of the circle.
 *          radius = Radius of the circle.
 *
 * Returns: Random position in the specified circle.
 */
Vector2!T randomPosition(T)(Vector2!T center, T radius)
    if(isNumeric!T)
{
    return center + randomDirection!T  * uniform(cast(T)0, radius);
}

///Get a unit vector with a random direction.
Vector2!T randomDirection(T)()
    if(isNumeric!T)
{
    return angleToVector(uniform(0, 2.0 * PI));
}

///Get a unit vector in direction of specified angle.
Vector2!(Unqual!T) angleToVector(T)(T angle) pure
    if(isFloatingPoint!T)
{
    auto v = Vector2!(Unqual!T)(cast(Unqual!T)1, cast(Unqual!T)0);
    v.angle = angle;
    return v;
}

///Vector2 of bytes.
alias Vector2!byte   Vector2b;
///Vector2 of ubytes.
alias Vector2!ubyte  Vector2ub;
///Vector2 of shorts.
alias Vector2!short  Vector2s;
///Vector2 of ushorts.
alias Vector2!ushort Vector2us;
///Vector2 of ints.
alias Vector2!int    Vector2i;
///Vector2 of uints.
alias Vector2!uint   Vector2u;
///Vector2 of floats.
alias Vector2!float  Vector2f;
///Vector2 of doubles.
alias Vector2!double Vector2d;
