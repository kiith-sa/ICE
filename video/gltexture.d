
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module video.gltexture;


import math.vector2;
import math.rectangle;


///OpenGL texture struct. Texture data is stored by texture page the texture is on.
package align(1) struct GLTexture
{
    Rectanglef texcoords;
    //offset relative to page this texture is on
    Vector2u offset;
    uint page_index;
}

