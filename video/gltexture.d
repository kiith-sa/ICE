
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
    Rectanglef texCoords;
    ///Offset relative to the page.
    Vector2u offset;
    ///Index of the page.
    uint pageIndex;

    /**
     * Construct a GLTexture.
     *
     * Params:  pageArea  = Area taken by the texture on the texture page.
     *          pageSize  = Size of the page in pixels.
     *          pageIndex = Index if the texture page.
     */
    this(ref const Rectangleu pageArea, const Vector2u pageSize, const uint pageIndex) pure
    {
        this.texCoords = Rectanglef((cast(float)pageArea.min.x) / pageSize.x, 
                                    (cast(float)pageArea.min.y) / pageSize.y,  
                                    (cast(float)pageArea.max.x) / pageSize.x,  
                                    (cast(float)pageArea.max.y) / pageSize.y);
        this.offset    = pageArea.min;
        this.pageIndex = pageIndex;
    }
}

