
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module spatial.volumeaabbox;
@safe


import spatial.volume;
import math.vector2;
import math.rectangle;


///2D axis aligned bounding box (aka rectangle).
final immutable class VolumeAABBox : Volume
{
    public:
        ///Bounding box rectangle in object space.
        Rectanglef rectangle;

    public:
        /**
         * Construct an axis aligned bounding box.
         *
         * Params:  offset = Position of the top-left corner of the box in object space.
         *          size   = Size of the bounding box.
         */
        this(in Vector2f offset, in Vector2f size)
        {
            rectangle = Rectanglef(offset, offset + size);
        }
}
