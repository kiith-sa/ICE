
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Generic, API-independent texture page.
module video.texturepage;


import std.conv;

import color;
import image;
import math.math;
import math.rect;
import math.vector2;
import memory.memory;


///Texture page with customizable texture packer and API specific backend.
struct TexturePage(TexturePacker, TextureBackend)
{
    private:
        ///Texture packer, handles allocation of texture space.
        TexturePacker packer_;
        ///Texture backend, hides graphics API details.
        TextureBackend backend_;
        ///Size of the page in pixels.
        Vector2u size_;
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
            size_    = size;
            format_  = format;
            packer_  = TexturePacker(size);
            backend_ = TextureBackend(size, format);
        }
        
        /**
         * Try to insert an image to this page and use it as a texture.
         *
         * Params:  image    = Image to insert.
         *          pageArea = Area taken by the texture on the page will be returned here.
         *
         * Floating-point texture coordinates can be calculated by dividing pageArea by
         * texture page size.
         *
         * Returns: True on success, false on failure.
         */
        bool insertTexture(const ref Image image, out Rectu pageArea)
        {
            //image format must match
            if(image.format != format_){return false;}
            if(packer_.allocateSpace(image.size, pageArea))
            {                                  
                backend_.subImage(image, pageArea.min);
                return true;
            }
            return false;
        }

        ///Use this page to draw textured geometry from now on.
        void start(){backend_.start();}

        ///Remove texture with specified bounds from this page.
        void removeTexture(const ref Rectu bounds) {packer_.freeSpace(bounds);}
        ///Ditto.
        void removeTexture(const Rectu bounds) {packer_.freeSpace(bounds);}

        ///Determine if this page is empty (i.e. there are no textures on it).
        @property bool empty() const pure {return packer_.empty();}

        ///Get size of the page in pixels.
        @property Vector2u size() const pure {return size_;}

        ///Get the color format of the page.
        @property ColorFormat format() const pure {return format_;}

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

