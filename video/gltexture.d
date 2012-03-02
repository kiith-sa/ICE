
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL texture handle.
module video.gltexture;


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
    uint pageIndex;

    /**
     * Construct a GLTexture.
     *
     * Params:  texcoords  = Texture coordinates on the texture page.
     *          offset     = Offset from the origin of texture page.
     *          pageIndex = Index if the texture page.
     */
    this(const Rectanglef texcoords, const Vector2u offset, const uint pageIndex) pure
    {
        this.texcoords = texcoords;
        this.offset    = offset;
        this.pageIndex = pageIndex;
    }
}

