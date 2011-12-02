
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL texture handle.
module video.gltexture;
@safe


import math.vector2;
import math.rectangle;


///OpenGL texture struct. Texture data is stored by texture page the texture is on.
package struct GLTexture
{
    ///Texture coordinates.
    Rectanglef texcoords;
    ///Offset relative to the page.
    Vector2u offset;
    ///Index of the page.
    uint page_index;

    /**
     * Construct a GLTexture.
     *
     * Params:  texcoords  = Texture coordinates on the texture page.
     *          offset     = Offset from the origin of texture page.
     *          page_index = Index if the texture page.
     */
    this(Rectanglef texcoords, Vector2u offset, uint page_index)
    {
        this.texcoords = texcoords;
        this.offset = offset;
        this.page_index = page_index;
    }
}

