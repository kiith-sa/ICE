module math.rectangle;


import math.math;
import math.vector2;

///Rectangle defined by vectors of its limits.
struct Rectangle(T)
{
    invariant
    {
        assert(min.x <= max.x && min.y <= max.y, 
               "Min value/s of a Rectangle can not greater than max");
    }

    ///Upper-left corner of the rectangle.
    Vector2!(T) min;
    ///Lower-right corner of the rectangle.
    Vector2!(T) max;

    ///Fake constructor from 4 numbers
    static Rectangle!(T) opCall(T x1, T y1, T x2, T y2)
    {
        return Rectangle!(T)(Vector2!(T)(x1, y1), Vector2!(T)(x2, y2));
    }
 
    ///Fake constructor from 2 vectors
    static Rectangle!(T) opCall(Vector2!(T) v1, Vector2!(T) v2)
    {
        Rectangle rect;
        rect.min = v1;
        rect.max = v2;
        return rect;
    }
    
    ///Addition with a vector - used to move the rectangle. 
    Rectangle!(T) opAdd(Vector2!(T) v){return Rectangle!(T)(min + v, max + v);}

    ///Subtraction with a vector - used to move the rectangle. 
    Rectangle!(T) opSub(Vector2!(T) v){return Rectangle!(T)(min - v, max - v);}

    ///Returns the lower-left corner of the rectangle.
    Vector2!(T) min_max(){return Vector2!(T)(min.x, max.y);}

    ///Returns the upper-right corner of the rectangle.
    Vector2!(T) max_min(){return Vector2!(T)(max.x, min.y);}

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

    ///Clamps point to be within the rectangle. (Returns the closest point in the rectangle)
    Vector2!(T) clamp(Vector2!(T) point)
    {
        if(point.x < min.x) point.x = min.x;
        else if(point.x > max.x) point.x = max.x;
        if(point.y < min.y) point.y = min.y;
        else if(point.y > max.y) point.y = max.y;
        return point;
    }

    ///Returns distance from point to the rectangle.
    T distance(Vector2!(T) point){return (point - clamp(point)).length;}

    ///Determines if a point intersects with the rectangle.
    bool intersect(Vector2!(T) point)
    {
        return point.x >= min.x && point.x <= max.x && 
               point.y >= min.y && point.y <= max.y;
    }

    ///Returns center of the rectangle.
    Vector2!(T) center(){return (min + max) / cast(T)2;}
    
    ///Returns width of the rectangle.
    T width(){return max.x - min.x;}

    ///Returns height of the rectangle.
    T height(){return max.y - min.y;}
    
    ///Returns size of the rectangle.
    Vector2!(T) size(){return max - min;}
    
    ///If the point is not in this rectangle, grow the rectangle to include it.
    void add_internal_point(Vector2!(T) point)
    {
        min.x = math.math.min(min.x, point.x);
        min.y = math.math.min(min.y, point.y);
        max.x = math.math.max(max.x, point.x);
        max.y = math.math.max(max.y, point.y);
    }
}

alias Rectangle!(float) Rectanglef;
alias Rectangle!(double) Rectangled;
alias Rectangle!(int) Rectanglei;
alias Rectangle!(uint) Rectangleu;
