module gltexture;


import derelict.opengl.gl;

import math;
import vector2;
import rectangle;
import color;
import image;
import allocator;

///Binary tree based texture packer. Handles allocation of texture page space.
package align(1) struct NodePacker
{
    private:
        //Single packer node.
        static align(1) struct Node
        {
            public:
                //Area belonging to the node.
                Rectangleu rectangle;
            private:
                //Children nodes.
                Node* child_a;
                Node* child_b;
                //True if this node's area is taken by a texture.
                bool full = false;

            public:
                ///Try to insert a texture with given size to this node.
                /**
                 * @return node with space for the texture on success.
                 * @return null on failure.
                */
                Node* insert(Vector2u size)
                in
                {
                    assert(size != Vector2u(0, 0), "Can't pack a zero sized "
                                                   "texture");
                }
                body
                {
                    //if not a leaf
                    if(child_a !is null && child_b !is null)
                    {
                        //try inserting to first child
                        Node* new_node = child_a.insert(size);
                        if(new_node !is null){return new_node;}
                        //no room, try the second 
                        //(which will return NULL if no room there either)
                        return child_b.insert(size);
                    }
                    if(full){return null;}

                    Vector2u rect_size = rectangle.size;
                    //if this node is too small
                    if(rect_size.x < size.x || rect_size.y < size.y)
                    {
                        return null;
                    }
                    //if exact fit
                    if(rect_size == size)
                    {
                        full = true;
                        return this;
                    }
                    child_a = alloc!(Node)();
                    child_b = alloc!(Node)();

                    //decide which way to split
                    Vector2u free_space = rect_size - size;
                    child_b.rectangle = child_a.rectangle = rectangle;
                    //split with a vertical cut if more free space on the right
                    if(free_space.x > free_space.y)
                    {
                        child_a.rectangle.max.x = rectangle.min.x + size.x;// - 1;
                        child_b.rectangle.min.x += size.x;
                    }
                    //split with a horizontal cut if more free space on the bottom
                    else
                    {
                        child_a.rectangle.max.y = rectangle.min.y + size.y;// - 1;
                        child_b.rectangle.min.y += size.y;
                    }
                    return child_a.insert(size);
                }

                ///Try to remove a texture with specified area.
                /**
                 * @return true on success.
                 * @return false on failure.
                 * @note could be optimized using simple rectanlge intersection
                 * (probably not much gain, though).
                 */
                bool remove(ref Rectangleu rect)
                {
                    //exact fit, this is the area we want to free
                    if(rect == rectangle && full)
                    {
                        full = false;
                        return true;
                    }
                    //try children
                    if(child_a !is null && child_a.remove(rect))
                    {
                        return true;
                    }
                    if(child_b !is null && child_b.remove(rect))
                    {
                        return true;
                    }
                    //can't remove from this node
                    return false;
                }
                
                ///Determine if this node and all its subnodes are empty.
                bool empty()
                {
                    if(full)
                    {
                        return false;
                    }
                    if(child_a !is null && !child_a.empty())
                    {
                        return false;
                    }
                    if(child_b !is null && !child_b.empty())
                    {
                        return false;
                    }
                    return true;
                }

                ///Destroy this node and its children.
                void die()
                {
                    if(child_a !is null)
                    {
                        child_a.die();
                        free(child_a);
                        child_a = null;
                    }
                    if(child_b !is null)
                    {
                        child_b.die();
                        free(child_b);
                        child_b = null;
                    }
                }
        }

        //Size of the area available to the packer, in pixels.
        Vector2u Size;

        //Root node of the packer tree.
        Node* Root;

    public:
        ///Fake constructor. Returns NodePacker with specified texture size.
        static NodePacker opCall(Vector2u size)
        {
            NodePacker packer;
            packer.ctor(size);
            return packer;
        }

        ///Destroy this NodePacker and its nodes.
        void die()
        {
            Root.die();
            free(Root);
        }

        ///Try to allocate space for a texture with given size.
        /**
         * @param size Size of the texture to allocate space for.
         * @param texcoords Texture coordinates of the texture will be output here.
         * @param offset Offset of the texture on the page will be output here.
         *
         * @return true on success.
         * @return false on failure.
         */
        bool allocate_space(Vector2u size, out Rectanglef texcoords, 
                            out Vector2u offset)
        {
            Node* node = Root.insert(size);
            if(node is null){return false;}

            Vector2f min = Vector2f(node.rectangle.min.x, node.rectangle.min.y);
            Vector2f max = Vector2f(node.rectangle.max.x, node.rectangle.max.y);

            texcoords.min = Vector2f(min.x / Size.x, min.y / Size.y);
            texcoords.max = Vector2f(max.x / Size.x, max.y / Size.y);
            offset = node.rectangle.min;
            return true;
        }

        ///Free space taken by a texture.
        void free_space(ref Rectangleu rectangle)
        {
            bool removed = Root.remove(rectangle);
            assert(removed, "Trying to remove unallocated space from NodePacker");
        }

        ///Determine if this NodePacker is empty.
        bool empty()
        {
            return Root.empty();
        }

    private:
        ///Initialization method used by the fake constructor.
        void ctor(Vector2u size)
        {
            Size = size;
            Root = alloc!(Node)();
            *Root = Node(Rectangleu(Vector2u(0,0), size), null, null, false);
        }
}   

///Convert a ColorFormat to OpenGL color format parameters.
void gl_color_format(ColorFormat format, out GLenum gl_format,
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


package align(1) struct GLTexture
{
    Rectanglef texcoords;
    //offset relative to page this texture is on
    Vector2u offset;
    uint page_index;
}

