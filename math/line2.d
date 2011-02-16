
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

    ///Addition with a vector - used in translation.
    Line2!(T) opAdd(Vector2!(T) s){return Line2!(T)(start + s, end + s);}
    
    ///Addition-assignment with a vector - used in translation.
    void opAddAssign(Vector2!(T) s)
    {
        start += s;
        end += s;
    }

    ///Get direction vector of the line segment.
    Vector2!(T) vector(){return end - start;}

    ///Get normal vector of the line segment.
    Vector2!(T) normal(){return vector.normal;}
    
    ///Get length of the line segment.
    T length(){return vector.length;}
    
    ///Get squared length of the line segment.
    T length_squared(){return vector.length_squared;}
    
    /**
     * Determines if point is to the right, left or on the line.
     *
     * Params:  point = Point to determine orientation of.
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
     * Calculates closest point on this line segment to given point.
     *
     * Params:  point = Point to find the closest point to.
     *
     * Returns: Closest point on the line to the specified point.
     */
    Vector2!(T) closest_point(Vector2!(T) point) 
    {
        auto c = point - start;
        auto v = vector();

        T l = v.length;
        v /= l;
        T t = v.dot_product(c);

        return t < 0.0 ? start : t > l ? end : start + v * t;
    }
    //Unittest for closest_point().
    unittest
    {
        Line2f line = Line2f(Vector2f(0.0, 0.0), Vector2f(1.0, 1.0));
        Vector2f point = Vector2f(1.0, 0.0);
        assert(line.closest_point(point) == Vector2f(0.5, 0.5));
        point = Vector2f(-1.0, -1.0);
        assert(line.closest_point(point) == Vector2f(0.0, 0.0));
        point = Vector2f(2.0, 2.0);
        assert(line.closest_point(point) == Vector2f(1.0, 1.0));
    }

    /**
     * Calculates distance from the line segment to given point.
     *
     * Params:  point = Point to calculate distance to.
     *
     * Returns: Distance to the specified point.
     */
    T distance(Vector2!(T) point){return (point - closest_point(point)).length;}
    //Unittest for distance().
    unittest
    {
        Line2f line = Line2f(Vector2f(0.0, 0.0), Vector2f(1.0, 1.0));
        Vector2f point = Vector2f(1.0, 0.0);
        float sqrt_1_2 = cast(float)std.math.SQRT1_2;
        assert(equals(line.distance(point), sqrt_1_2, 0.00001f));
        point = Vector2f(-1.0, -1.0);
        assert(equals(line.distance(point), sqrt_1_2 * 2.0f, 0.0001f));
        point = Vector2f(2.0, 2.0);
        assert(equals(line.distance(point), sqrt_1_2 * 2.0f, 0.0001f));
    }

    ///Get the point symmetric to given point according to line of this segment.
    Vector2!(T) symmetric_point(Vector2!(T) point)
    {
        auto closest = closest_point(point);
        auto normal_distance = closest - point;
        return point + 2 * normal_distance;
    }
    //Unittest for symmetric_point().
    unittest
    {
        Line2f line = Line2f(Vector2f(0.0, 0.0), Vector2f(1.0, 1.0));
        Vector2f point = Vector2f(1.0, 0.0);
        assert(line.symmetric_point(point) == Vector2f(0.0, 1.0));
        point = Vector2f(0.5, 0.5);
        assert(line.symmetric_point(point) == Vector2f(0.5, 0.5));
    }

    //Code based on the Irrlicht engine: irrlicht.sourceforge.net
    /**
     * Tests for intersection with another line segment.
     *
     * Params:  l = Line segment to test for intersection with.
     *          i = Vector to write intersection point to.
     *
     * Returns: Type of intersection.
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
                //but we can't get a perfect solution either way.
                
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
            }
            //parallel but not coincident
            return LineIntersection.NoIntersection; 
        }

        //get the point of intersection on this line, checking that
        //it is within the line segment.
        T u_a = numerator_a / common_denominator;
        //outside the line segment
        if(u_a < 0.0 || u_a > 1.0){return LineIntersection.NoIntersection;}

        T u_b = numerator_b / common_denominator;
        //outside the line segment
        if(u_b < 0.0 || u_b > 1.0){return LineIntersection.NoIntersection;}

        //calculate the intersection point.
        i.x = start.x + u_a * (end.x - start.x);
        i.y = start.y + u_a * (end.y - start.y);
        return LineIntersection.Intersection;
    }
    //Unittest for intersect().
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

///Line of floats.
alias Line2!(float) Line2f;
