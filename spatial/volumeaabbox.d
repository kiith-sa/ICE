
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///2D axis aligned bounding box.
module spatial.volumeaabbox;


import spatial.volume;
import math.vector2;
import math.rect;


///2D axis aligned bounding box (aka rectangle).
final immutable class VolumeAABBox : Volume
{
    public:
        ///Bounding box rectangle in object space.
        Rectf rectangle;

    public:
        /**
         * Construct an axis aligned bounding box.
         *
         * Params:  offset = Position of the top-left corner of the box in object space.
         *          size   = Size of the bounding box.
         */
        this(const Vector2f offset, const Vector2f size)
        {
            rectangle = Rectf(offset, offset + size);
        }
}
