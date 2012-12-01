
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module video.gltexturebackend;


import derelict.opengl.gl;

import color;
import image;
import math.vector2;
import video.binarytexturepacker;
import video.texturepage;


///Alias for default texture page to use with OpenGL code.
package alias TexturePage!(BinaryTexturePacker, GLTextureBackend) GLTexturePage;

/**
 * OpenGL texture backend.
 *
 * Encapsulates an OpenGL texture and operates on it. Used by TexturePage.
 */
package struct GLTextureBackend
{
    private:
        //OpenGL texture.
        GLuint texture_ = 0;
        //Color format of the texture.
        ColorFormat format_;
        //Size of the texture in pixels.
        Vector2u size_;

    public:
        /**
         * Construct a GLTextureBackend.
         *
         * Params:  size   = Size of the texture.
         *          format = Color format of the texture.
         */
        this(const Vector2u size, const ColorFormat format)
        {
            //create blank image to use as initial texture data
            auto image = Image(size.x, size.y, format);
            format_ = format;
            size_   = size;

            glGenTextures(1, &texture_);
            glBindTexture(GL_TEXTURE_2D, texture_);

            GLenum glFormat;
            GLenum type;
            GLint internalFormat;
            glColorFormat(format, glFormat, type, internalFormat);

            glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, size.x, size.y, 
                         0, glFormat, type, image.dataUnsafe.ptr);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }

        ///Destroy the texture backend.
        ~this()
        {
            if(texture_ != 0){glDeleteTextures(1, &texture_);}
        }

        /**
         * Insert an image into the texture.
         *
         * Params:  image  = Image to insert.
         *          offset = Offset of the image relative to the texture in pixels.
         */
        void subImage(const ref Image image, const Vector2u offset)
        in
        {
            assert(offset.x + image.width <= size_.x &&
                   offset.y + image.height <= size_.y, 
                   "GLTextureBackend.subImage(): image out of texture bounds");
        }
        body
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
        }

        ///Start using this texture for upcoming draws.
        void start(){glBindTexture(GL_TEXTURE_2D, texture_);}

        /**
         * Convert a ColorFormat to OpenGL color format parameters.
         *
         * Params:  format         = ColorFormat to convert.
         *          glFormat       = GL format of the data (RGBA, luminance, etc) will be written here.
         *          type           = GL data type (unsigned byte, etc) will be written here.
         *          internalFormat = GL internal format (RGBA8, etc) will be written here.
         */
        static void glColorFormat(const ColorFormat format, out GLenum glFormat,
                                  out GLenum type, out GLint internalFormat)
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
                    type = GL_UNSIGNED_BYTE;
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
        static GLint packAlignment(const ColorFormat format)
        {
            final switch(format)
            {
                case ColorFormat.RGB_565: return 2;
                case ColorFormat.RGB_8:   return 1;
                case ColorFormat.RGBA_8:  return 4;
                case ColorFormat.GRAY_8:  return 1;
            }
        }
}
