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
/*
 * Test for collision between two physics bodies.
 *
 * Params:    body_a  = First of the tested bodies.
 *            body_b  = Second of the tested bodies.
 *            contact = Contact struct to write to if there is a collision.
 *                      Is ref instead of out purely for performance reasons.
 *
 * Returns:    True if a collision is detected, false otherwise.
 */
bool detect_contact(PhysicsBody body_a, PhysicsBody body_b, ref Contact contact)
in
{
    assert(body_a !is body_b, "Trying to detect contact of an object with itself.");
}
body
{
    //if one of the bodies has no collision volume, there can't be a collision
    if(body_a.volume is null || body_b.volume is null){return false;}

    contact.body_a = body_a;
    contact.body_b = body_b;

    //determine types of collision volumes and test for intersection
    if(!intersection(body_a.position, body_b.position, 
       body_a.volume, body_b.volume, contact))
    {
        return false;
    }

    return true;
}


private: 
/*
 * Test for intersection between two collision volumes.
 *
 * Determines collision volume types and runs correct intersection tests.
 *
 * Params:    position1 = Position of the first collision volume in world space.
 *            position2 = Position of the second collision volume in world space. 
 *            volume1   = First of the tested volumes.
 *            volume2   = Second of the tested volumes.
 *            contact   = Contact struct to write to if there is an intersection. 
 *
 * Returns:    True if an intersection happened, false otherwise.
 */
bool intersection(Vector2f position1,
                  Vector2f position2,
                  Volume volume1, 
                  Volume volume2, 
                  ref Contact contact)
in
{
    auto class_a = volume1.classinfo;
    auto class_b = volume2.classinfo;

    static aabbox = VolumeAABBox.classinfo;
    static circle = VolumeCircle.classinfo;

    assert(class_a is aabbox || class_a is circle, "Unsupported collision volume type");
    assert(class_b is aabbox || class_b is circle, "Unsupported collision volume type");

    assert(volume1 !is volume2, "Can't test intersection of a collision volume with itself");
}
body
{
    auto class_a = volume1.classinfo;
    auto class_b = volume2.classinfo;

    static const aabbox = VolumeAABBox.classinfo;
    static const circle = VolumeCircle.classinfo;

    if(class_a is aabbox)
    {
        if(class_b is aabbox)
        {
            return aabbox_aabbox(position1, position2, 
                                 cast(VolumeAABBox)volume1, 
                                 cast(VolumeAABBox)volume2,
                                 contact);
        }
        else if(class_b is circle)
        {
            return aabbox_circle(position1, position2, 
                                 cast(VolumeAABBox)volume1, 
                                 cast(VolumeCircle)volume2,
                                 contact);
        }
        assert(false, "Unsupported collision volume");
    }
    else if(class_a is circle)
    {
        if(class_b is aabbox)
        {
            //swapping volumes for test, then swapping them back in the contact
            bool result = aabbox_circle(position1, position2, 
                                        cast(VolumeAABBox)volume2,
                                        cast(VolumeCircle)volume1, 
                                        contact);
            contact.swap_bodies();
            return result;
        }
        else if(class_b is circle)
        {
            return circle_circle(position1, position2, 
                                 cast(VolumeCircle)volume1, 
                                 cast(VolumeCircle)volume2,
                                 contact);
        }
        assert(false, "Unsupported collision volume");
    }
    assert(false, "Unsupported collision volume");
}

/*
 * Test for intersection between two axis aligned bounding boxes.
 *
 * Params:    box1_position = Top-left corner of the first bounding box in world space.
 *            box2_position = Top-left corner of the second bounding box in world space.
 *            box1          = First of the tested bounding boxes.
 *            box2          = Second of the tested bounding boxes.
 *            contact       = Contact struct to write to if there is an intersection. 
 *
 * Returns:    True if an intersection happened, false otherwise.
 */
bool aabbox_aabbox(Vector2f box1_position,
                   Vector2f box2_position,
                   VolumeAABBox box1, 
                   VolumeAABBox box2, 
                   ref Contact contact)
{
    //combined half-widths/half-heights of the rectangles.
    Vector2f combined = (box1.rectangle.size + box2.rectangle.size) * 0.5;

    //distance between centers of the rectangles
    Vector2f distance = (box2_position + box2.rectangle.center) - 
                        (box1_position + box1.rectangle.center);
 
    //calculate absolute distance coords
    //this is used to determine collision
    Vector2f distance_abs = Vector2f(abs(distance.x), abs(distance.y));

    //aabboxes are not intersecting if both of the following are false:
    //their x distance is less than their combined halfwidths
    //their y distance is less than their combined halfheights
    if(!((distance_abs.x < combined.x) && (distance_abs.y < combined.y))) {return false;}

    //magnitude of the normal vector is determined by the overlap of aabboxes
    Vector2f normal_mag = combined - distance_abs;
 
    contact.contact_normal.zero();
    //only adjust the contact normal in the direction of the smallest overlap
    if(normal_mag.x < normal_mag.y)
    {
        contact.penetration = abs(normal_mag.x);
        contact.contact_normal.x = (distance.x > 0) ? 1.0f : -1.0f;
    }
    else
    {
        contact.penetration = abs(normal_mag.y);
        contact.contact_normal.y = (distance.y > 0) ? 1.0f : -1.0f;
    }
    return true;
}
unittest
{
    //default initialized to zero vector
    Vector2f zero;

    auto box1 = new VolumeAABBox(zero, Vector2f(4.0f, 3.0f));
    auto box2 = new VolumeAABBox(Vector2f(3.0f, 1.0f), Vector2f(3.0f, 1.0f));
    auto box3 = new VolumeAABBox(Vector2f(4.1f, 1.0f), Vector2f(3.0f, 1.0f));

    Contact contact;
    assert(aabbox_aabbox(zero, zero, box1, box2, contact) == true);
    assert(contact.contact_normal == Vector2f(1.0, 0.0));
    assert(aabbox_aabbox(zero, zero, box1, box3, contact) == false);
    assert(aabbox_aabbox(zero, Vector2f(1.0f, 0.0f), box1, box2, contact) == false);
    assert(aabbox_aabbox(zero, Vector2f(-1.0f, 0.0f), box1, box3, contact) == true);
}

/*
 * Test for intersection between two circles.
 *
 * Params:    circle1_position = Center of the first circle in world space.
 *            circle2_position = Center of the second circle in world space. 
 *            circle1          = First of the tested circles.
 *            circle2          = Second of the tested circles.
 *            contact          = Contact struct to write to if there is an intersection. 
 *
 * Returns:    True if an intersection happened, false otherwise.
 */
bool circle_circle(Vector2f circle1_position,
                   Vector2f circle2_position,
                   VolumeCircle circle1, 
                   VolumeCircle circle2, 
                   ref Contact contact)
{
    //difference of circle positions in world space
    Vector2f difference = (circle2.offset + circle2_position) - 
                          (circle1.offset + circle1_position);

    float radius_total = circle1.radius + circle2.radius;

    //will be positive if the objects are interpenetrating
    float penetration_sq = radius_total * radius_total - difference.length_squared;

    if(penetration_sq < 0.0){return false;}

    contact.penetration = sqrt(penetration_sq);

    //degenerate case when the circles are at the same position
    if(difference == Vector2f(0.0f, 0.0f)){difference.x = 1.0;}

    difference.normalize_safe();
    contact.contact_normal = difference;

    return true;
}
unittest
{
    //default initialized to zero vector
    Vector2f zero;

    auto circle1 = new VolumeCircle(zero, 4.0f);
    auto circle2 = new VolumeCircle(Vector2f(0.0f, 6.7f), 3.0f);
    auto circle3 = new VolumeCircle(Vector2f(0.1f, 7.0f), 3.0f);

    Contact contact;
    assert(circle_circle(zero, zero, circle1, circle2, contact) == true);
    assert(contact.contact_normal == Vector2f(0.0, 1.0));
    assert(circle_circle(zero, zero, circle1, circle3, contact) == false);
    assert(circle_circle(zero, Vector2f(0.0f, 1.0f), circle1, circle2, contact) == false);
    assert(circle_circle(zero, Vector2f(0.0f, -1.0f), circle1, circle3, contact) == true);
}

/*
 * Test for intersection between an axis aligned bounding box and a circle.
 *
 * Params:    box_position    = Top-left corner of the bounding box in world space.
 *            circle_position = Center of the circle in world space. 
 *            box             = Tested bounding box.
 *            circle          = Tested circle.
 *            contact         = Contact struct to write to if there is an intersection. 
 *
 * Returns:    True if an intersection happened, false otherwise.
 */
bool aabbox_circle(Vector2f box_position,
                   Vector2f circle_position,
                   VolumeAABBox box, 
                   VolumeCircle circle, 
                   ref Contact contact)
{
    //convert to box space
    Vector2f circle_center = circle.offset + circle_position - box_position;

    //closest point to the circle on the box 
    Vector2f closest = box.rectangle.clamp(circle_center);

    //distance from the center of the circle to the box
    Vector2f difference = circle_center - closest;

    //will be positive if the objects are interpenetrating
    float penetration_sq = circle.radius * circle.radius - difference.length_squared;

    if(penetration_sq < 0.0){return false;}

    //degenerate case when the circle is exactly on the border of the box
    if(difference == Vector2f(0.0f, 0.0f)){difference.x = 1.0;}

    contact.penetration = sqrt(penetration_sq);
    difference.normalize_safe();
    contact.contact_normal = difference;

    return true;
}
unittest
{
    //default initialized to zero vector
    Vector2f zero;

    auto circle1 = new VolumeCircle(zero, 4.0f);
    auto circle2 = new VolumeCircle(Vector2f(0.0f, 6.5f), 3.0f);
    auto box1 = new VolumeAABBox(zero, Vector2f(4.0f, 3.0f));
    auto box2 = new VolumeAABBox(Vector2f(-2.0f, -6.9f), Vector2f(4.0f, 3.0f));

    Contact contact;
    assert(aabbox_circle(zero, zero, box2, circle1, contact) == true);
    assert(contact.contact_normal == Vector2f(0.0, 1.0));
    assert(aabbox_circle(zero, zero, box1, circle2, contact) == false);
    assert(aabbox_circle(zero, Vector2f(0.0f, 1.0f), box2, circle1, contact) == false);
    assert(aabbox_circle(zero, Vector2f(0.0f, -1.0f), box1, circle2, contact) == true);
}
