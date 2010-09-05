module video.gltexturepage;


import derelict.opengl.gl;

import video.gltexturepage;
import video.nodepacker;
import math.math;
import math.vector2;
import math.rectangle;
import color;
import image;
import allocator;


///Convert a ColorFormat to OpenGL color format parameters.
package void gl_color_format(ColorFormat format, out GLenum gl_format,
                             out GLenum type, out GLint internal_format)
{
    switch(format)
    {
        case ColorFormat.RGB_565:
            assert(false, "Unsupported texture format: RGB_565");
            break;
        case ColorFormat.RGBA_8:
            internal_format = GL_RGBA8;
            gl_format = GL_RGBA;
            type = GL_UNSIGNED_INT_8_8_8_8;
            break;
        case ColorFormat.GRAY_8:
            internal_format = GL_LUMINANCE8;
            gl_format = GL_LUMINANCE;
            type = GL_UNSIGNED_BYTE;
            break;
        default:
            assert(false, "Unsupported texture format");
            break;
    }
}

//Parts of this code could be abstracted to a more general TexturePage
//struct that could be "inherited" in D2 using alias this,
//but that would only make sense if we are to add more texture page 
//implementations.
///OpenGL texture page struct.
package align(1) struct GLTexturePage(TexturePacker) 
{
    private:
        ///Packer, handles allocation of texture space.
        TexturePacker Packer;
        ///Size of the page in pixels.
        Vector2u Size;
        ///OpenGL texture object
        GLuint  Texture;
        ///Color format of the page.
        ColorFormat Format;

    public:
        ///Fake constructor. Returns a page with specified format and size.
        static GLTexturePage!(TexturePacker) opCall(Vector2u size, 
                                                    ColorFormat format)
        {
            GLTexturePage!(TexturePacker) page;
            page.ctor(size, format);
            return page;
        }
        
        ///Destroy the page.
        void die()
        {
            Packer.die();
            glDeleteTextures(1, &Texture);
        }
        
        ///Try to insert an image to this page and use it as a texture.
        /**
         * @param image Image to insert.
         * @param texcoords Texture coords of the texture will be output here.
         * @param offset Offset of the texture relative to page will be output here.
         *
         * @returns true on success.
         * @returns false on failure.
         */
        bool insert_texture(ref Image image, out Rectanglef texcoords, 
                                     out Vector2u offset) 
        {
            if(image.format != Format)
            {
                return false;
            }
            if(Packer.allocate_space(image.size, texcoords, offset))
            {                                  
                //get opengl color format parameters
                GLenum gl_format, type;
                GLint internal_format;
                gl_color_format(Format, gl_format, type, internal_format);

                glBindTexture(GL_TEXTURE_2D, Texture);
                
                //default GL alignment is 4 bytes which messes up less than
                //4 Bpp textures (e.g. grayscale) when their row sizes are not
                //divisible by 4. So we force alignment here.
                glPixelStorei(GL_UNPACK_ALIGNMENT, bytes_per_pixel(image.format));
                //write to texture
                glTexSubImage2D(GL_TEXTURE_2D, 0, offset.x, offset.y, 
                                image.size.x, image.size.y, 
                                gl_format, type, image.data.ptr);
                return true;
            }
            return false;
        }

        ///Use this page to draw textured geometry from now on.
        void start()
        {
            glBindTexture(GL_TEXTURE_2D, Texture);
        }

        ///Determine if this texture page is resident in the video memory.
        bool is_resident()
        {
            GLboolean resident;
            glAreTexturesResident(1, &Texture, &resident);
            return cast(bool) resident;
        }

        ///Remove texture with specified bounds from this page.
        void remove_texture(ref Rectangleu bounds)
        {
            Packer.free_space(bounds);
        }

        ///Determine if this page is empty (i.e. there are no textures on it).
        bool empty()
        {
            return Packer.empty();
        }

        ///Return a string containing information about this page.
        string info()
        {
            string info = "Color format: " ~ to_string(Format);
            info ~= "\nSize: " ~ cast(string)Size;
            return info;
        }

    private:
        ///Initialization method used by the fake constructor.
        void ctor(Vector2u size, ColorFormat format)
        in
        {
            assert(is_pot(size.x) && is_pot(size.y), 
                   "Non-power-of-two texture page size");
        }
        body
        {
            Size = size;
            Format = format;
            Packer = TexturePacker(size);

            //create blank image to use as texture data
            scope Image image = new Image(size.x, size.y, format);
            glGenTextures(1, &Texture);
            
            glBindTexture(GL_TEXTURE_2D, Texture);

            GLenum gl_format;
            GLenum type;
            GLint internal_format;
            gl_color_format(format, gl_format, type, internal_format);
            
            glTexImage2D(GL_TEXTURE_2D, 0, internal_format, Size.x, 
                         Size.y, 0, gl_format, type, image.data.ptr);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
}

alias GLTexturePage!(NodePacker) TexturePage;
