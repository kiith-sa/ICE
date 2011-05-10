
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Rectangle struct.
module math.rectangle;
@safe


import std.algorithm;
import math.vector2;

///Rectangle defined by its extents.
align(1) struct Rectangle(T)
{
    invariant()
    {
        assert(min.x <= max.x && min.y <= max.y, "Min value/s of a Rectangle greater than max");
    }

    ///Upper-left corner of the rectangle.
    Vector2!T min;
    ///Lower-right corner of the rectangle.
    Vector2!T max;

    /**
     * Construct a rectangle from 4 bounds.
     *
     * Params:  min_x = Left bound of the rectangle.
     *          min_y = Top bound of the rectangle.
     *          max_x = Right bound of the rectangle.
     *          max_y = Bottom bound of the rectangle.
     */
    this(in T min_x, in T min_y, in T max_x, in T max_y)
    {
        this(Vector2!T(min_x, min_y), Vector2!T(max_x, max_y));
    }
 
    /**
     * Construct a rectangle from 2 points.
     *
     * Params:  min = Upper-left corner of the rectangle.
     *          max = Lower-right corner of the rectangle.
     */
    this(in Vector2!T min, in Vector2!T max)
    {
        this.min = min;
        this.max = max;
    }
    
    ///Addition with a vector - used to move the rectangle. 
    Rectangle!T opAdd(in Vector2!T v) const {return Rectangle!T(min + v, max + v);}

    ///Subtraction with a vector - used to move the rectangle. 
    Rectangle!T opSub(in Vector2!T v) const {return Rectangle!T(min - v, max - v);}

    ///Addition-assignment with a vector - used to move the rectangle. 
    void opAddAssign(in Vector2!T v)
    {
        min += v;
        max += v;
    }

    ///Subtraction-assignment with a vector - used to move the rectangle. 
    void opSubAssign(in Vector2!T v)
    {
        min -= v;
        max -= v;
    }

    ///Returns center of the rectangle.
    @property Vector2!T center() const {return (min + max) / cast(T)2;}
    
    ///Returns width of the rectangle.
    @property T width() const {return max.x - min.x;}

    ///Returns height of the rectangle.
    @property T height() const {return max.y - min.y;}
    
    ///Returns size of the rectangle.
    @property Vector2!T size() const {return max - min;}

    ///Returns area of the rectangle.
    @property T area() const {return size.x * size.y;}

    ///Returns the lower-left corner of the rectangle.
    @property Vector2!T min_max() const {return Vector2!T(min.x, max.y);}

    ///Returns the upper-right corner of the rectangle.
    @property Vector2!T max_min() const {return Vector2!T(max.x, min.y);}

    /**
     * Clamps point to be within the rectangle. (Returns the closest point in the rectangle)
     *
     * Params:  point = Point to clamp.
     *
     * Returns: Clamped point.
     */
    Vector2!T clamp(Vector2!T point) const
    {
        if(point.x < min.x) point.x = min.x;
        else if(point.x > max.x) point.x = max.x;
        if(point.y < min.y) point.y = min.y;
        else if(point.y > max.y) point.y = max.y;
        return point;
    }

    /**
     * Get distance from the point to the rectangle.
     *
     * Params:  point = Point to get distance from.
     *
     * Returns: Distance from the point to the rectangle.
     */
    T distance(in Vector2!T point) const {return (point - clamp(point)).length;}

    /**
     * Determines if a point intersects with the rectangle.
     *
     * Params:  point = Point to check intersection with.
     *
     * Returns: True in case of intersection, false otherwise.
     */
    bool intersect(in Vector2!T point) const
    {
        return point.x >= min.x && point.x <= max.x && 
               point.y >= min.y && point.y <= max.y;
    }

    ///If the point is not in this rectangle, grow the rectangle to include it.
    void add_internal_point(in Vector2!T point)
    {
        min.x = std.algorithm.min(min.x, point.x);
        min.y = std.algorithm.min(min.y, point.y);
        max.x = std.algorithm.max(max.x, point.x);
        max.y = std.algorithm.max(max.y, point.y);
    }
}

///Rectangle of floats.
alias Rectangle!float Rectanglef;
///Rectangle of doubles.
alias Rectangle!double Rectangled;
///Rectangle of ints.
alias Rectangle!int Rectanglei;
///Rectangle of uints.
alias Rectangle!uint Rectangleu;
