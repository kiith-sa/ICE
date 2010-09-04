module math.vector2;


import std.string;
import std.math;
import std.random;

import math.math;
                   
///2D vector struct.
align(1) struct Vector2(T)
{
    //initialized to null vector by default
    ///X value of the vector.
    T x = 0;
    ///Y value of the vector.
    T y = 0;
    
    //operators

    ///Negation.
    Vector2!(T) opNeg()
    {
        return Vector2!(T)(-x, -y);
    }

    ///Equality with a vector.
    bool opEquals(Vector2!(T) v)
    {
        return equals(x, v.x) && equals(y, v.y);
    }

    ///Addition with a vector.
    Vector2!(T) opAdd(Vector2!(T) v)
    {
        return Vector2!(T)(x + v.x, y + v.y);
    }

    ///Subtraction with a vector.
    Vector2!(T) opSub(Vector2!(T) v)
    {
        return Vector2!(T)(x - v.x, y - v.y);
    }

    ///Multiplication by a scalar.
    Vector2!(T) opMul(T m)
    {
        return Vector2!(T)(x * m, y * m);
    }

    ///Division by a scalar. 
    Vector2!(T) opDiv(T d)
    in
    {
        assert(d != 0.0, "Vector can not be divided by zero");
    }
    body
    {
        return Vector2!(T)(x / d, y / d);
    }

    ///Addition-assignment with a vector.
    void opAddAssign(Vector2!(T) v)
    {
        x += v.x;
        y += v.y;
    }

    ///Subtraction-assignment with a vector.
    void opSubAssign(Vector2!(T) v)
    {
        x -= v.x;
        y -= v.y;
    }

    ///Multiplication-assignment by a scalar.
    void opMulAssign(T m)
    {
        x *= m;
        y *= m;
    }

    ///Division-assignment by a scalar. 
    void opDivAssign(T d)
    in
    {
        assert(d != 0.0, "Vector can not be divided by zero");
    }
    body
    {
        x /= d;
        y /= d;
    }

    ///String conversion for printing, serialization.
    string opCast()
    {
        return "Vector2, " ~ std.string.toString(x) ~ ", " 
                           ~ std.string.toString(y);
    }
    
    ///Returns length of the vector.
    T length()
    {
        return cast(T)(sqrt(cast(real)length_squared));
    }
    
    ///Get angle of this vector.
    real angle()
    {
        real angle = atan2(cast(double)x, cast(double)y);
        if(angle < 0.0)
        {
            return angle + 2 * PI;
        }
        return angle;
    }

    ///Set angle of this vector (preserving length)
    void angle(real angle)
    {
        T length = length();
        y = cast(T)cos(cast(double)angle);
        x = cast(T)sin(cast(double)angle);
        *this *= length;
    }

    ///Returns squared length of the vector.
    T length_squared()
    {
        return x * x + y * y;
    }

    ///Dot product with another vector.
    T dot_product(Vector2!(T) v) 
    {
        return x * v.x + y * v.y;
    }

    ///Returns normal of this vector (a pependicular vector).
    Vector2!(T) normal()
    {
        return Vector2!(T)(-y, x);
    }

    ///Returns unit vector of this vector.
    Vector2!(T) normalized()
    {
        T len = length();
        if(equals(len, cast(T)0))
        {
            return Vector2!(T)(0, 0);
        }
        return Vector2!(T)(x / len, y / len);
    }

    ///Turns this vector into a random (unit) direction vector
    void random_direction()
    {
        long x_int = std.random.rand();
        long y_int = std.random.rand();
        x = cast(T)(x_int % 2 ? x_int / 2 : -x_int / 2);
        y = cast(T)(y_int % 2 ? y_int / 2 : -y_int / 2);
        *this = normalized;
    }
}

alias Vector2!(byte) Vector2b;
alias Vector2!(ubyte) Vector2ub;
alias Vector2!(short) Vector2s;
alias Vector2!(ushort) Vector2us;
alias Vector2!(int) Vector2i;
alias Vector2!(uint) Vector2u;
alias Vector2!(float) Vector2f;
alias Vector2!(double) Vector2d;
