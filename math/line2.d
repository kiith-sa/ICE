
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module math.line2;


import math.math;
import math.vector2;
import math.rectangle;

///Describes types of intersection between line segments.
enum LineIntersection
{
    ///Segments intersect.
    Intersection,
    ///Segments intersect and their lines are coincident. 
    CoincidentIntersection,
    ///Segments don't intersect.
    NoIntersection
}

///2D line segment between two points.
align(1) struct Line2(T)
{
    ///Start point of the line segment.
    Vector2!(T) start;
    ///End point of the line segment.
    Vector2!(T) end;

    ///Fake constructor from 4 numbers
    static Line2!(T) opCall(T x1, T y1, T x2, T y2)
    {
        return Line2!(T)(Vector2!(T)(x1, y1), Vector2!(T)(x2, y2));
    }
 
    ///Fake constructor from 2 vectors
    static Line2!(T) opCall(Vector2!(T) v1, Vector2!(T) v2)
    {
        Line2!(T) line;
        line.start = v1;
        line.end = v2;
        return line;
    }

    ///Subtraction with a vector - used in translation.
    Line2!(T) opSub(Vector2!(T) s){return Line2!(T)(start - s, end - s);}
    
    ///Subtraction-assignment with a vector - used in translation.
    void opSubAssign(Vector2!(T) s)
    {
        start -= s;
        end -= s;
    }

    ///Returns direction vector of the line.
    Vector2!(T) vector(){return end - start;}

    ///Returns normal vector of the line.
    Vector2!(T) normal(){return vector.normal;}
    
    ///Returns length of the line segment.
    T length(){return vector.length;}
    
    ///Returns squared length of the line segment.
    T length_squared(){return vector.length_squared;}
    
    /**
     * Determines if point is to the right, left or on the line.
     *
     * Params:    point = Point to determine orientation of.
     *
     * Returns: Less than 0 if the point is to the left of line,
     *          more than 0 if the point is to the right of line,
     *          0 of the point is on the line.
     */
    T point_orientation(Vector2!(T) point)
    {
        return (end.x - start.x) * (point.y - start.y) -
               (point.x - start.x) * (end.y - start.y);   
    }

    //Code based on the Irrlicht engine: irrlicht.sourceforge.net
    /**
     * Calculates closest _point on this line or line segment to given _point.
     *
     * Params:    point     = Point to find the closest _point to.
     *            full_line = Find the closest _point of full line of this
     *                        segment or just on the segment itself?
     *
     * Returns: Closest _point to point.
     */
    Vector2!(T) closest_point(Vector2!(T) point, bool full_line = true) 
    {
        Vector2!(T) c = point - start;
        Vector2!(T) v = vector();

        T l = v.length;
        v /= l;
        T t = v.dot_product(c);

        if(!full_line)
        {
            if (t < 0.0){return start;}
            if (t > l){return end;}
        }

        v *= t;
        return start + v;
    }
    unittest
    {
        Vector2f start = Vector2f(0.0, 0.0);
        Vector2f end = Vector2f(1.0, 1.0);
        Line2f line = Line2f(start, end);
        Vector2f point = Vector2f(1.0, 0.0);
        assert(line.closest_point(point) == Vector2f(0.5, 0.5));
        assert(line.closest_point(point, false) == Vector2f(0.5, 0.5));
        point = Vector2f(-1.0, -1.0);
        assert(line.closest_point(point) == Vector2f(-1.0, -1.0));
        assert(line.closest_point(point, false) == Vector2f(0.0, 0.0));
        point = Vector2f(2.0, 2.0);
        assert(line.closest_point(point) == Vector2f(2.0, 2.0));
        assert(line.closest_point(point, false) == Vector2f(1.0, 1.0));
    }

    /**
     * Calculates distance from this line or line segment to given _point.
     *
     * Params:    point     = Point to calculate distance to.
     *            full_line = Calculate distance to full line of this segment 
     *                        or just on the segment itself?
     *
     * Returns: Distance to point.
     */
    T distance(Vector2!(T) point, bool full_line = true)
    out(result){assert(result >= 0.0, "Negative distance of point from line");}
    body{return (point - closest_point(point, full_line)).length;}
    unittest
    {
        Vector2f start = Vector2f(0.0, 0.0);
        Vector2f end = Vector2f(1.0, 1.0);
        Line2f line = Line2f(start, end);
        Vector2f point = Vector2f(1.0, 0.0);
        float sqrt_1_2 = cast(float)std.math.SQRT1_2;
        assert(equals(line.distance(point), sqrt_1_2, 0.00001f));
        assert(equals(line.distance(point, false), sqrt_1_2, 0.00001f));
        point = Vector2f(-1.0, -1.0);
        assert(equals(line.distance(point), 0.0f, 0.00001f));
        assert(equals(line.distance(point, false), sqrt_1_2 * 2.0f, 0.0001f));
        point = Vector2f(2.0, 2.0);
        assert(equals(line.distance(point), 0.0f, 0.00001f));
        assert(equals(line.distance(point, false), sqrt_1_2 * 2.0f, 0.0001f));
    }

    ///Returns the _point symmetric to given _point according to line defined by this segment.
    Vector2!(T) symmetric_point(Vector2!(T) point)
    {
        auto closest = closest_point(point);
        auto normal_distance = closest - point;
        return point + 2 * normal_distance;
    }
    unittest
    {
        Vector2f start = Vector2f(0.0, 0.0);
        Vector2f end = Vector2f(1.0, 1.0);
        Line2f line = Line2f(start, end);
        Vector2f point = Vector2f(1.0, 0.0);
        assert(line.symmetric_point(point) == Vector2f(0.0, 1.0));
        point = Vector2f(0.5, 0.5);
        assert(line.symmetric_point(point) == Vector2f(0.5, 0.5));
    }

    //Code based on the Irrlicht engine: irrlicht.sourceforge.net
    /**
      * Tests for intersection with another line segment.
      *
      * Params:    l = Line segment to test intersection with.
      *            i = Vector to write intersection point to.
      *
      * Returns: true if line segments intersect, false otherwise.
      */
    LineIntersection intersect(Line2!(T) l, out Vector2!(T) i)
    {
        T common_denominator = (l.end.y - l.start.y) * (end.x - start.x) -
                               (l.end.x - l.start.x) * (end.y - start.y);

        T numerator_a = (l.end.x - l.start.x) * (start.y - l.start.y) -
                        (l.end.y - l.start.y) * (start.x -l.start.x);

        T numerator_b = (end.x - start.x) * (start.y - l.start.y) -
                        (end.y - start.y) * (start.x -l.start.x);

        if(equals(common_denominator, cast(T)0.0))
        {
            //if lines are coincident
            if(equals(numerator_a, cast(T)0.0) && equals(numerator_b, cast(T)0.0))
            {
                //if the lines are coincident, we return the
                //end on this line that is the closest to
                //start of given line

                //this will of course result in strange behavior
                //if the given line starts within this line,
                //but this is usually used to check for collision
                //with lines coming from outside.
                
                T other_length = l.length;
                T start_distance = (start - l.start).length;
                T end_start_distance = (end - l.start).length;
                //is start of this line within the other line?
                bool start_in_line = start_distance <= other_length 
                                     && (start - l.end).length <= other_length;
                //is end of this line within the other line?
                bool end_in_line = end_start_distance <= other_length 
                                   && (end - l.end).length <= other_length;
                //only other way the lines can intersect is for one
                //of them to start and end within other:
                bool contained = start_distance <= length 
                                 && end_start_distance <= length;
                //if lines intersect
                if(start_in_line || end_in_line || contained)
                {
                    if((l.start - start).length < (l.start - end).length){i = start;}
                    else{i = end;}                                                
                    //coincident and intersect
                    return LineIntersection.CoincidentIntersection; 
                }                                        
                //coincident but no intersection
                return LineIntersection.NoIntersection; 
                /++
                //find a common endpoint
                if(l.start == start || l.end == start)
                {
                    i = start;
                }
                else if(l.end == end || l.start == end)
                {
                    i = end;
                }
                else
                {
                    //one line is contained in the other, so get the average 
                    //of both lines
                    i = ((start + end + l.start + l.end) * 0.25);
                }
                ++/

            }
            //parallel but not coincident
            return LineIntersection.NoIntersection; 
        }

        //get the point of intersection on this line, checking that
        //it is within the line segment.
        T u_a = numerator_a / common_denominator;
        if(u_a < 0.0 || u_a > 1.0)
        {    
            //outside the line segment
            return LineIntersection.NoIntersection; 
        }

        T u_b = numerator_b / common_denominator;
        if(u_b < 0.0 || u_b > 1.0)
        {
            //outside the line segment
            return LineIntersection.NoIntersection; 
        }

        //calculate the intersection point.
        i.x = start.x + u_a * (end.x - start.x);
        i.y = start.y + u_a * (end.y - start.y);
        return LineIntersection.Intersection;
    }
    unittest
    {
        Line2f l1 = Line2f(Vector2f(0.0, 0.0), Vector2f(2.0, 2.0));
        Line2f l2 = Line2f(Vector2f(0.0, 2.0), Vector2f(2.0, 0.0));
        Line2f l3 = Line2f(Vector2f(-1.0, 2.0), Vector2f(2.0, 5.0));
        Vector2f intersection;
        //perpendicular
        assert(l1.intersect(l2, intersection) == LineIntersection.Intersection);
        assert(intersection == Vector2f(1.0, 1.0));
        //parallel
        assert(l1.intersect(l3, intersection) == LineIntersection.NoIntersection);
        //perpendicular but segments don't intersect - only lines do
        assert(l2.intersect(l3, intersection) == LineIntersection.NoIntersection);
    }
}

alias Line2!(float) Line2f;
