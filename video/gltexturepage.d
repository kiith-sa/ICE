
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL texture page.
module video.gltexturepage;


import std.conv;

import derelict.opengl.gl;

import video.binarytexturepacker;
import math.math;
import math.vector2;
import math.rectangle;
import color;
import image;
import memory.memory;


/**
 * Convert a ColorFormat to OpenGL color format parameters.
 *
 * Params:  format          = ColorFormat to convert.
 *          glFormat       = GL format of the data (RGBA, luminance, etc) will be written here.
 *          type            = GL data type (unsigned byte, etc) will be written here.
 *          internalFormat = GL internal format (RGBA8, etc) will be written here.
 */
package void glColorFormat(const ColorFormat format, out GLenum glFormat,
                             out GLenum type, out GLint internalFormat) pure
{
    final switch(format)
    {
        case ColorFormat.RGB_565:
            assert(false, "Unsupported texture format: RGB_565");
        case ColorFormat.RGB_8:
            internalFormat = GL_RGB8;
            glFormat = GL_RGB;
            type = GL_UNSIGNED_BYTE;
            break;
        case ColorFormat.RGBA_8:
            internalFormat = GL_RGBA8;
            glFormat = GL_RGBA;
            type = GL_UNSIGNED_INT_8_8_8_8;
            break;
        case ColorFormat.GRAY_8:
            internalFormat = GL_RED;
            glFormat = GL_RED;
            type = GL_UNSIGNED_BYTE;
            break;
    }
}

/**
 * Determine OpenGL packing/unpacking alignment needed for specified color format.
 *
 * GL only supports 1, 2, 4, 8, so using bytes per pixel doesn't work for e.g. RGB8.
 *
 * Params:  format = Format to get alignment for.
 *
 * Returns: Alignment for specified format.
 */
package GLint packAlignment(const ColorFormat format) pure
{
    final switch(format)
    {
        case ColorFormat.RGB_565: return 2;
        case ColorFormat.RGB_8:   return 1;
        case ColorFormat.RGBA_8:  return 4;
        case ColorFormat.GRAY_8:  return 1;
    }
}

//Parts of this code could be abstracted to a more general TexturePage
//struct that could be "inherited" in D2 using alias this, but that would only 
//make sense if we added more texture page implementations.
///OpenGL texture page with customizable texture packer.
package struct GLTexturePage(TexturePacker) 
{
    private:
        alias std.conv.to to;

        ///Texture packer, handles allocation of texture space.
        TexturePacker packer_;
        ///Size of the page in pixels.
        Vector2u size_;
        ///OpenGL texture of the page.
        GLuint texture_;
        ///Color format of the page.
        ColorFormat format_;

    public:
        /**
         * Construct a GLTexturePage.
         *
         * Params:  size   = Dimensions of the page in pixels.
         *          format = Color format of the page.
         */
        this(const Vector2u size, const ColorFormat format)
        in
        {
            assert(isPot(size.x) && isPot(size.y), 
                   "Non-power-of-two texture page size");
        }
        body
        {
            size_   = size;
            format_ = format;
            packer_ = TexturePacker(size);

            //create blank image to use as initial texture data
            auto image = Image(size.x, size.y, format);
            glGenTextures(1, &texture_);
            
            glBindTexture(GL_TEXTURE_2D, texture_);

            GLenum glFormat;
            GLenum type;
            GLint internalFormat;
            glColorFormat(format, glFormat, type, internalFormat);
            
            glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, size_.x, size_.y, 
                         0, glFormat, type, image.dataUnsafe.ptr);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
        
        ///Destroy the page.
        ~this()
        {
            glDeleteTextures(1, &texture_);
        }
        
        /**
         * Try to insert an image to this page and use it as a texture.
         *
         * Params:  image     = Image to insert.
         *          texcoords = Texture coords of the texture will be written here.
         *          offset    = Offset of the texture on the page will be written here.
         *
         * Returns: True on success, false on failure.
         */
        bool insertTexture(const ref Image image, 
                            out Rectanglef texcoords, out Vector2u offset)
        {
            //image format must match
            if(image.format != format_){return false;}
            if(packer_.allocateSpace(image.size, texcoords, offset))
            {                                  
                //get opengl color format parameters
                GLenum glFormat, type;
                GLint internalFormat;
                glColorFormat(format_, glFormat, type, internalFormat);

                glBindTexture(GL_TEXTURE_2D, texture_);
                
                //default GL alignment is 4 bytes which messes up less than
                //4 Bpp textures (e.g. grayscale) when their row sizes are not
                //divisible by 4. So we force alignment here.
                glPixelStorei(GL_UNPACK_ALIGNMENT, packAlignment(image.format));
                //write to texture
                glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, 
                                image.size.x, image.size.y, 
                                glFormat, type, image.data.ptr);
                return true;
            }
            return false;
        }

        ///Use this page to draw textured geometry from now on.
        void start(){glBindTexture(GL_TEXTURE_2D, texture_);}

        ///Remove texture with specified bounds from this page.
        void removeTexture(const ref Rectangleu bounds){packer_.freeSpace(bounds);}

        ///Determine if this page is empty (i.e. there are no textures on it).
        @property bool empty() const pure {return packer_.empty();}

        ///Get size of the page in pixels.
        @property Vector2u size() const pure {return size_;}

        /**
         * Return a string containing information about the page.
         *
         * Format of this string might change, it is used strictly for debugging
         * purposes and not meant to be parsed.
         *
         * Returns: String with information about the page.
         */
        @property string info() const
        {
            return ("width: "   ~ to!string(size_.x) ~ "\n" ~
                    "height: "  ~ to!string(size_.y) ~ "\n" ~
                    "format: "  ~ to!string(format_) ~ "\n" ~
                    "packer:\n" ~ packer_.info);
        }
}

///GLTexturePage using BinaryTexturePacker for texture packing.
alias GLTexturePage!BinaryTexturePacker TexturePage;
