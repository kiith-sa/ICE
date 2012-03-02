
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Functions detecting contacts between physics bodies.
module physics.contactdetect;


import std.math;

import physics.physicsbody;
import physics.contact;
import spatial.volume;
import spatial.volumeaabbox;
import spatial.volumecircle;
import math.vector2;
import math.rectangle;

package:
/**
 * Test for collision between two bodies.
 *
 * Params:  bodyA  = First body.
 *          bodyB  = Second body.
 *          contact = Contact struct to write collision to, if any.
 *
 * Returns: True if a collision is detected, false otherwise.
 */
bool detectContact(PhysicsBody bodyA, PhysicsBody bodyB, out Contact contact)
in{assert(bodyA !is bodyB, "Trying to detect contact of an object with itself.");}
body
{
    //if a body has no collision volume, there can't be a collision
    if(bodyA.volume is null || bodyB.volume is null){return false;}

    contact.bodyA = bodyA;
    contact.bodyB = bodyB;

    //determine types of collision volumes and test for intersection
    return intersection(bodyA.position, bodyB.position, 
                        bodyA.volume, bodyB.volume, contact);
}


private: 
/**
 * Test for intersection between two collision volumes.
 *
 * Determines collision volume types and runs correct intersection tests.
 *
 * Params:  position1 = Position of the first volume in world space.
 *          position2 = Position of the second volume in world space. 
 *          volume1   = First volume.
 *          volume2   = Second volume.
 *          contact   = Contact struct to write any intersection to.
 *
 * Returns: True if an intersection happened, false otherwise.
 */
bool intersection(const Vector2f position1, const Vector2f position2,
                  const Volume volume1, const Volume volume2, 
                  ref Contact contact)
in
{
    const classA = volume1.classinfo;
    const classB = volume2.classinfo;

    static aabbox = VolumeAABBox.classinfo;
    static circle = VolumeCircle.classinfo;

    assert(classA is aabbox || classA is circle, "Unsupported collision volume type");
    assert(classB is aabbox || classB is circle, "Unsupported collision volume type");

    assert(volume1 !is volume2, "Can't test intersection of a collision volume with itself");
}
body
{
    const classA = volume1.classinfo;
    const classB = volume2.classinfo;

    static const aabbox = VolumeAABBox.classinfo;
    static const circle = VolumeCircle.classinfo;

    if(classA is aabbox)
    {
        if(classB is aabbox)
        {
            return aabboxAabbox(position1, position2, 
                                 cast(VolumeAABBox)volume1, 
                                 cast(VolumeAABBox)volume2,
                                 contact);
        }
        else if(classB is circle)
        {
            return aabboxCircle(position1, position2, 
                                 cast(VolumeAABBox)volume1, 
                                 cast(VolumeCircle)volume2,
                                 contact);
        }
        assert(false, "Unsupported collision volume type");
    }
    else if(classA is circle)
    {
        if(classB is aabbox)
        {
            //swapping volumes for test, then swapping them back in the contact
            bool result = aabboxCircle(position1, position2, 
                                        cast(VolumeAABBox)volume2,
                                        cast(VolumeCircle)volume1, 
                                        contact);
            contact.swapBodies();
            return result;
        }
        else if(classB is circle)
        {
            return circleCircle(position1, position2, 
                                 cast(VolumeCircle)volume1, 
                                 cast(VolumeCircle)volume2,
                                 contact);
        }
        assert(false, "Unsupported collision volume type");
    }
    assert(false, "Unsupported collision volume type");
}

/**
 * Test for intersection between two axis aligned bounding boxes.
 *
 * Params:  box1Position = Top-left corner of the first bounding box in world space.
 *          box2Position = Top-left corner of the second bounding box in world space.
 *          box1          = First bounding box.
 *          box2          = Second bounding box.
 *          contact       = Contact struct to write any intersection to.
 *
 * Returns: True if an intersection happened, false otherwise.
 */
bool aabboxAabbox(const Vector2f box1Position, const Vector2f box2Position,
                   const VolumeAABBox box1, const VolumeAABBox box2, 
                   ref Contact contact)
{
    //combined half-widths/half-heights of the rectangles.
    const Vector2f combined = (box1.rectangle.size + box2.rectangle.size) * 0.5f;

    //distance between centers of the rectangles
    const Vector2f distance = (box2Position + box2.rectangle.center) - 
                              (box1Position + box1.rectangle.center);
 
    //calculate absolute distance coords
    //this is used to determine collision
    const distanceAbs = Vector2f(abs(distance.x), abs(distance.y));

    //aabboxes are not intersecting if both of the following are false:
    //their x distance is less than their combined halfwidths
    //their y distance is less than their combined halfheights
    if(!((distanceAbs.x < combined.x) && (distanceAbs.y < combined.y))) {return false;}

    //magnitude of the normal vector is determined by the overlap of aabboxes
    const normalMag = combined - distanceAbs;
 
    contact.contactNormal.zero();
    //only adjust the contact normal in the direction of the smallest overlap
    if(normalMag.x < normalMag.y)
    {
        contact.penetration = abs(normalMag.x);
        contact.contactNormal.x = (distance.x > 0) ? 1.0f : -1.0f;
    }
    else
    {
        contact.penetration = abs(normalMag.y);
        contact.contactNormal.y = (distance.y > 0) ? 1.0f : -1.0f;
    }
    return true;
}
///Unittest for aabboxAabbox().
unittest
{
    //default initialized to zero vector
    Vector2f zero;

    auto box1 = new VolumeAABBox(zero, Vector2f(4.0f, 3.0f));
    auto box2 = new VolumeAABBox(Vector2f(3.0f, 1.0f), Vector2f(3.0f, 1.0f));
    auto box3 = new VolumeAABBox(Vector2f(4.1f, 1.0f), Vector2f(3.0f, 1.0f));

    Contact contact;
    assert(aabboxAabbox(zero, zero, box1, box2, contact) == true);
    assert(contact.contactNormal == Vector2f(1.0, 0.0));
    assert(aabboxAabbox(zero, zero, box1, box3, contact) == false);
    assert(aabboxAabbox(zero, Vector2f(1.0f, 0.0f), box1, box2, contact) == false);
    assert(aabboxAabbox(zero, Vector2f(-1.0f, 0.0f), box1, box3, contact) == true);
}

/**
 * Test for intersection between two circles.
 *
 * Params:  circle1Position = Center of the first circle in world space.
 *          circle2Position = Center of the second circle in world space. 
 *          circle1          = First circle.
 *          circle2          = Second circle.
 *          contact          = Contact struct to write any intersection to.
 *
 * Returns: True if an intersection happened, false otherwise.
 */
bool circleCircle(const Vector2f circle1Position, const Vector2f circle2Position,
                   const VolumeCircle circle1, const VolumeCircle circle2, 
                   ref Contact contact)
{
    //difference of circle positions in world space
    Vector2f difference = (circle2.offset + circle2Position) - 
                          (circle1.offset + circle1Position);

    const float radiusTotal = circle1.radius + circle2.radius;

    //will be positive if the objects are interpenetrating
    const float penetrationSq = radiusTotal * radiusTotal - difference.lengthSquared;

    if(penetrationSq < 0.0){return false;}

    contact.penetration = sqrt(penetrationSq);

    //degenerate case when the circles are at the same position
    if(difference == Vector2f(0.0f, 0.0f)){difference.x = 1.0;}

    difference.normalize();
    contact.contactNormal = difference;

    return true;
}
///Unittest for circleCircle().
unittest
{
    //default initialized to zero vector
    Vector2f zero;

    auto circle1 = new VolumeCircle(zero, 4.0f);
    auto circle2 = new VolumeCircle(Vector2f(0.0f, 6.7f), 3.0f);
    auto circle3 = new VolumeCircle(Vector2f(0.1f, 7.0f), 3.0f);

    Contact contact;
    assert(circleCircle(zero, zero, circle1, circle2, contact) == true);
    assert(contact.contactNormal == Vector2f(0.0, 1.0));
    assert(circleCircle(zero, zero, circle1, circle3, contact) == false);
    assert(circleCircle(zero, Vector2f(0.0f, 1.0f), circle1, circle2, contact) == false);
    assert(circleCircle(zero, Vector2f(0.0f, -1.0f), circle1, circle3, contact) == true);
}

/**
 * Test for intersection between an axis aligned bounding box and a circle.
 *
 * Params:  boxPosition    = Top-left corner of the bounding box in world space.
 *          circlePosition = Center of the circle in world space. 
 *          box             = Bounding box.
 *          circle          = Circle.
 *          contact         = Contact struct to write any intersection to.
 *
 * Returns: True if an intersection happened, false otherwise.
 */
bool aabboxCircle(const Vector2f boxPosition, const Vector2f circlePosition,
                   const VolumeAABBox box, const VolumeCircle circle, 
                   ref Contact contact)
{
    //convert to box space
    const Vector2f circleCenter = circle.offset + circlePosition - boxPosition;

    //closest point to the circle on the box 
    const Vector2f closest = box.rectangle.clamp(circleCenter);

    //distance from the center of the circle to the box
    Vector2f difference = circleCenter - closest;

    //will be positive if the objects are interpenetrating
    const float penetrationSq = circle.radius * circle.radius - difference.lengthSquared;

    if(penetrationSq < 0.0){return false;}

    //degenerate case when the circle is exactly on the border of the box
    if(difference == Vector2f(0.0f, 0.0f)){difference.x = 1.0;}

    contact.penetration = sqrt(penetrationSq);
    difference.normalize();
    contact.contactNormal = difference;

    return true;
}
///Unittest for aabboxCircle().
unittest
{
    //default-initialized to zero vector
    Vector2f zero;

    auto circle1 = new VolumeCircle(zero, 4.0f);
    auto circle2 = new VolumeCircle(Vector2f(0.0f, 6.5f), 3.0f);
    auto box1 = new VolumeAABBox(zero, Vector2f(4.0f, 3.0f));
    auto box2 = new VolumeAABBox(Vector2f(-2.0f, -6.9f), Vector2f(4.0f, 3.0f));

    Contact contact;
    assert(aabboxCircle(zero, zero, box2, circle1, contact) == true);
    assert(contact.contactNormal == Vector2f(0.0, 1.0));
    assert(aabboxCircle(zero, zero, box1, circle2, contact) == false);
    assert(aabboxCircle(zero, Vector2f(0.0f, 1.0f), box2, circle1, contact) == false);
    assert(aabboxCircle(zero, Vector2f(0.0f, -1.0f), box1, circle2, contact) == true);
}
