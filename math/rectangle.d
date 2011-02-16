
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.rectangle;


import math.math;
import math.vector2;

///Rectangle defined by its limit points.
align(1) struct Rectangle(T)
{
    invariant
    {
        assert(min.x <= max.x && min.y <= max.y, "Min value/s of a Rectangle greater than max");
    }

    ///Upper-left corner of the rectangle.
    Vector2!(T) min;
    ///Lower-right corner of the rectangle.
    Vector2!(T) max;

    /**
     * Construct a rectangle from 4 bounds.
     *
     * Params:  min_x = Left bound of the rectangle.
     *          min_y = Top bound of the rectangle.
     *          max_x = Right bound of the rectangle.
     *          max_y = Bottom bound of the rectangle.
     *
     * Returns: Rectangle with specified bounds.
     */
    static Rectangle!(T) opCall(T min_x, T min_y, T max_x, T max_y)
    {
        return Rectangle!(T)(Vector2!(T)(min_x, min_y), Vector2!(T)(max_x, max_y));
    }
 
    /**
     * Construct a rectangle from 2 points.
     *
     * Params:  min = Upper-left corner of the rectangle.
     *          max = Lower-right corner of the rectangle.
     *
     * Returns: Rectangle with specified min and max coordinates.
     */
    static Rectangle!(T) opCall(Vector2!(T) min, Vector2!(T) max)
    {
        Rectangle rect;
        rect.min = min;
        rect.max = max;
        return rect;
    }
    
    ///Addition with a vector - used to move the rectangle. 
    Rectangle!(T) opAdd(Vector2!(T) v){return Rectangle!(T)(min + v, max + v);}

    ///Subtraction with a vector - used to move the rectangle. 
    Rectangle!(T) opSub(Vector2!(T) v){return Rectangle!(T)(min - v, max - v);}

    ///Addition-assignment with a vector - used to move the rectangle. 
    void opAddAssign(Vector2!(T) v)
    {
        min += v;
        max += v;
    }

    ///Subtraction-assignment with a vector - used to move the rectangle. 
    void opSubAssign(Vector2!(T) v)
    {
        min -= v;
        max -= v;
 
    }
    ///Returns center of the rectangle.
    Vector2!(T) center(){return (min + max) / cast(T)2;}
    
    ///Returns width of the rectangle.
    T width(){return max.x - min.x;}

    ///Returns height of the rectangle.
    T height(){return max.y - min.y;}
    
    ///Returns size of the rectangle.
    Vector2!(T) size(){return max - min;}

    ///Returns area of the rectangle.
    T area(){return size.x * size.y;}

    ///Returns the lower-left corner of the rectangle.
    Vector2!(T) min_max(){return Vector2!(T)(min.x, max.y);}

    ///Returns the upper-right corner of the rectangle.
    Vector2!(T) max_min(){return Vector2!(T)(max.x, min.y);}

    /**
     * Clamps point to be within the rectangle. (Returns the closest point in the rectangle)
     *
     * Params:  point = Point to clamp.
     *
     * Returns: Clamped point.
     */
    Vector2!(T) clamp(Vector2!(T) point)
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
    T distance(Vector2!(T) point){return (point - clamp(point)).length;}

    /**
     * Determines if a point intersects with the rectangle.
     *
     * Params:  point = Point to check intersection with.
     *
     * Returns: True in case of intersection, false otherwise.
     */
    bool intersect(Vector2!(T) point)
    {
        return point.x >= min.x && point.x <= max.x && 
               point.y >= min.y && point.y <= max.y;
    }

    ///If the point is not in this rectangle, grow the rectangle to include it.
    void add_internal_point(Vector2!(T) point)
    {
        min.x = math.math.min(min.x, point.x);
        min.y = math.math.min(min.y, point.y);
        max.x = math.math.max(max.x, point.x);
        max.y = math.math.max(max.y, point.y);
    }
}

///Rectangle of floats.
alias Rectangle!(float) Rectanglef;
///Rectangle of doubles.
alias Rectangle!(double) Rectangled;
///Rectangle of ints.
alias Rectangle!(int) Rectanglei;
///Rectangle of uints.
alias Rectangle!(uint) Rectangleu;
