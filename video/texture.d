
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.texture;
@safe


import math.vector2;


///Exception thrown at texture related errors.
class TextureException : Exception{this(string msg){super(msg);}} 

///Opague and immutable texture handle struct used by code outside video subsystem.
align(1) struct Texture
{
    package:
        ///Size of the texture in pixels.
        Vector2u size;
        ///Index of the texture in the VideoDriver implementation.
        uint index;
}
