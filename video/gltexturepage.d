
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///OpenGL texture page.
module video.gltexturepage;
@system


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
 *          gl_format       = GL format of the data (RGBA, luminance, etc) will be written here.
 *          type            = GL data type (unsigned byte, etc) will be written here.
 *          internal_format = GL internal format (RGBA8, etc) will be written here.
 */
package void gl_color_format(in ColorFormat format, out GLenum gl_format,
                             out GLenum type, out GLint internal_format)
{
    final switch(format)
    {
        case ColorFormat.RGB_565:
            assert(false, "Unsupported texture format: RGB_565");
        case ColorFormat.RGB_8:
            internal_format = GL_RGB8;
            gl_format = GL_RGB;
            type = GL_UNSIGNED_BYTE;
            break;
        case ColorFormat.RGBA_8:
            internal_format = GL_RGBA8;
            gl_format = GL_RGBA;
            type = GL_UNSIGNED_INT_8_8_8_8;
            break;
        case ColorFormat.GRAY_8:
            internal_format = GL_RED;
            gl_format = GL_RED;
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
package GLint pack_alignment(in ColorFormat format)
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
        this(in Vector2u size, in ColorFormat format)
        in
        {
            assert(is_pot(size.x) && is_pot(size.y), 
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

            GLenum gl_format;
            GLenum type;
            GLint internal_format;
            gl_color_format(format, gl_format, type, internal_format);
            
            glTexImage2D(GL_TEXTURE_2D, 0, internal_format, size_.x, size_.y, 
                         0, gl_format, type, image.data_unsafe.ptr);
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
        bool insert_texture(const ref Image image, 
                            out Rectanglef texcoords, out Vector2u offset)
        {
            //image format must match
            if(image.format != format_){return false;}
            if(packer_.allocate_space(image.size, texcoords, offset))
            {                                  
                //get opengl color format parameters
                GLenum gl_format, type;
                GLint internal_format;
                gl_color_format(format_, gl_format, type, internal_format);

                glBindTexture(GL_TEXTURE_2D, texture_);
                
                //default GL alignment is 4 bytes which messes up less than
                //4 Bpp textures (e.g. grayscale) when their row sizes are not
                //divisible by 4. So we force alignment here.
                glPixelStorei(GL_UNPACK_ALIGNMENT, pack_alignment(image.format));
                //write to texture
                glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, 
                                image.size.x, image.size.y, 
                                gl_format, type, image.data.ptr);
                return true;
            }
            return false;
        }

        ///Use this page to draw textured geometry from now on.
        void start(){glBindTexture(GL_TEXTURE_2D, texture_);}

        ///Remove texture with specified bounds from this page.
        void remove_texture(const ref Rectangleu bounds){packer_.free_space(bounds);}

        ///Determine if this page is empty (i.e. there are no textures on it).
        @property bool empty() const {return packer_.empty();}

        ///Get size of the page in pixels.
        @property Vector2u size() const {return size_;}

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
