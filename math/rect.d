
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Rectangle struct.
module math.rect;


import std.algorithm;
import math.math;
import math.vector2;

///Rectangle defined by its extents.
struct Rect(T)
{
    ///Upper-left corner of the rectangle.
    Vector2!T min;
    ///Lower-right corner of the rectangle.
    Vector2!T max;

    /**
     * Construct a rectangle from 4 bounds.
     *
     * Params:  minX = Left bound of the rectangle.
     *          minY = Top bound of the rectangle.
     *          maxX = Right bound of the rectangle.
     *          maxY = Bottom bound of the rectangle.
     */
    this(const T minX, const T minY, const T maxX, const T maxY) pure
    {
        this(Vector2!T(minX, minY), Vector2!T(maxX, maxY));
    }
 
    /**
     * Construct a rectangle from 2 points.
     *
     * Params:  min = Upper-left corner of the rectangle.
     *          max = Lower-right corner of the rectangle.
     */
    this(const Vector2!T min, const Vector2!T max) pure
    {
        this.min = min;
        this.max = max;
    }

    ///Addition/subtraction with a vector - used to move the rectangle. 
    Rect opBinary(string op)(const Vector2!T v) const pure if(op == "+" || op == "-")
    {
        static if(op == "+")     {return Rect(min + v, max + v);}
        else static if(op == "-"){return Rect(min - v, max - v);}
    }

    ///Addition/subtraction with a vector - used to move the rectangle. 
    void opOpAssign(string op)(const Vector2!T v) pure if(op == "+" || op == "-")
    {
        this = opBinary!op(v);
    }

    ///Returns center of the rectangle.
    @property Vector2!T center() const pure {return (min + max) / cast(T)2;}
    
    ///Returns width of the rectangle.
    @property T width() const pure {return max.x - min.x;}

    ///Returns height of the rectangle.
    @property T height() const pure {return max.y - min.y;}
    
    ///Returns size of the rectangle.
    @property Vector2!T size() const pure {return max - min;}

    ///Returns area of the rectangle.
    @property T area() const pure {return size.x * size.y;}

    ///Returns the lower-left corner of the rectangle.
    @property Vector2!T minMax() const pure {return Vector2!T(min.x, max.y);}

    ///Returns the upper-right corner of the rectangle.
    @property Vector2!T maxMin() const pure {return Vector2!T(max.x, min.y);}

    /**
     * Clamps point to be within the rectangle. (Returns the closest point in the rectangle)
     *
     * Params:  point = Point to clamp.
     *
     * Returns: Clamped point.
     */
    Vector2!T clamp(const Vector2!T point) const pure
    {
        return Vector2!T(.clamp(point.x, min.x, max.x),
                         .clamp(point.y, min.y, max.y));
    }

    /**
     * Get distance from the point to the rectangle.
     *
     * Params:  point = Point to get distance from.
     *
     * Returns: Distance from the point to the rectangle.
     */
    T distance(const Vector2!T point) const pure {return (point - clamp(point)).length;}

    /**
     * Determines if a point intersects with the rectangle.
     *
     * Params:  point = Point to check intersection with.
     *
     * Returns: True in case of intersection, false otherwise.
     */
    bool intersect(const Vector2!T point) const pure
    {
        return point.x >= min.x && point.x <= max.x && 
               point.y >= min.y && point.y <= max.y;
    }

    ///If the point is not in this rectangle, grow the rectangle to include it.
    void addInternalPoint(const Vector2!T point) pure
    {
        min.x = .min(min.x, point.x);
        min.y = .min(min.y, point.y);
        max.x = .max(max.x, point.x);
        max.y = .max(max.y, point.y);
    }

    ///Is this rectangle valid?
    @property bool valid() const pure nothrow 
    {
        return min.x <= max.x && min.y <= max.y;
    }
}

///Rect of floats.
alias Rect!float  Rectf;
///Rect of doubles.
alias Rect!double Rectd;
///Rect of ints.
alias Rect!int    Recti;
///Rect of uints.
alias Rect!uint   Rectu;
