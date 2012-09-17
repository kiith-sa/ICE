
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Texture handle.
module video.texture;
@safe


import math.vector2;


///Exception thrown at texture related errors.
class TextureException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @trusted nothrow 
    {
        super(msg, file, line);
    }
}

///Opague and immutable texture handle struct used by code outside video subsystem.
align(4) struct Texture
{
    package:
        ///Size of the texture in pixels.
        Vector2u size;
        ///Index of the texture in the VideoDriver implementation.
        uint index;
}
static assert(Texture.sizeof <= 12);
