module spatial.volumeaabbox;


import spatial.volume;
import math.vector2;
import math.rectangle;


///2D axis aligned bounding box (aka rectangle).
final class VolumeAABBox : Volume
{
    public:
        //Bounding box rectangle in object space.
        Rectanglef rectangle;

    public:
        /**
         * Construct an axis aligned bounding box with specified parameters.
         *
         * Params:    offset = Position of the top-left corner of the box in object space.
         *            size   = Size of the bounding box.
         */
        this(Vector2f offset, Vector2f size)
        {
            rectangle.min = offset;
            rectangle.max = offset + size;
        }

        ///Returns bounding box rectangle in world space - to be used by non-physics code
        Rectanglef bounding_box(){return rectangle;}
}
