
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.texture;


import math.vector2;


///Opague and immutable texture handle struct used by code outside video subsystem.
align(1) struct Texture
{
    package:
        Vector2u size;
        uint index;
}
