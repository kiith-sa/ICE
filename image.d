
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///2D image struct.
module image;


import core.stdc.string;

import math.vector2;
import color;
import memory.allocator;


//could be optimized by adding a pitch data member (bytes per row)    
///Image object capable of storing images in various color formats.
struct Image
{
    alias BufferSwappingAllocator!(ubyte, 16) Allocator;
    //commented out due to a compiler bug
    //invariant(){assert(data_ !is null, "Image with NULL data");}

    private:
        ///Image data. Manually allocated.
        ubyte[] data_ = null;
        ///Size of the image in pixels.
        Vector2u size_;
        ///Color format of the image.
        ColorFormat format_;

    public:
        /**
         * Construct an image.
         *
         * Params:  width  = Width in pixels.
         *          height = Height in pixels.
         *          format = Color format of the image.
         */
        this(const uint width, const uint height, 
             const ColorFormat format = ColorFormat.RGBA_8)
        {
            data_ = Allocator.allocArray!ubyte(width * height * bytesPerPixel(format));
            size_ = Vector2u(width, height);
            format_ = format;
        }

        ///Destroy the image and free its memory.
        ~this(){if(data !is null){Allocator.free(data_);}}

        ///Get color format of the image.
        @property ColorFormat format() const pure {return format_;}

        ///Get size of the image in pixels.
        @property Vector2u size() const pure {return size_;}

        ///Get image width in pixels.
        @property uint width() const pure {return size_.x;}

        ///Get image height in pixels.
        @property uint height() const pure {return size_.y;}

        ///Get direct read-only access to image data.
        @property const(ubyte[]) data() const pure {return data_;}

        ///Get direct read-write access to image data.
        @property ubyte[] dataUnsafe() pure {return data_;}

        /**
         * Set RGBA pixel color.
         *
         * Only valid on RGBA_8 images.
         *
         * Params:  x     = X coordinate of the pixel.
         *          y     = Y coordinate of the pixel.
         *          color = Color to set.
         */
        void setPixelRGBA8(const uint x, const uint y, const Color color) pure
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8, "Incorrect image format");
        }
        body
        {
            const uint offset = y * pitch + x * 4;
            data_[offset]     = color.r;
            data_[offset + 1] = color.g;
            data_[offset + 2] = color.b;
            data_[offset + 3] = color.a;
        }

        /**
         * Set grayscale pixel color.
         *
         * Only valid on GRAY_8 images.
         *
         * Params:  x     = X coordinate of the pixel.
         *          y     = Y coordinate of the pixel.
         *          color = Color to set.
         */
        void setPixelGray8(const uint x, const uint y, const ubyte color) pure
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.GRAY_8, "Incorrect image format");
        }
        body{data_[y * pitch + x] = color;}

        /**
         * Get RGBA color of a pixel.
         *
         * Only supported on RGBA_8 images (can be improved).
         *
         * Params:  x = X coordinate of the pixel.
         *          y = Y coordinate of the pixel.
         *
         * Returns: Color of the pixel.
         */
        Color getPixel(const uint x, const uint y) const pure
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Getting pixel color only supported with RGBA_8");
        }
        body
        {
            const uint offset = y * pitch + x * 4;
            return Color(data_[offset], 
                         data_[offset + 1], 
                         data_[offset + 2], 
                         data_[offset + 3]);
        }

        //This is extremely ineffective/ugly, but not really a priority
        /**
         * Generate a black/transparent-white/opague checker pattern.
         *
         * Params:  size = Size of one checker square.
         */
        void generateCheckers(const uint size) pure
        {
            bool white;
            foreach(y; 0 .. size_.y) foreach(x; 0 .. size_.x)
            {
                white = cast(bool)(x / size % 2);
                if(cast(bool)(y / size % 2)){white = !white;}
                if(white) final switch(format_)
                {
                    case ColorFormat.RGB_565:
                        data_[y * pitch + x * 2] = 255;
                        data_[y * pitch + x * 2 + 1] = 255;
                        break;
                    case ColorFormat.RGB_8:
                        data_[y * pitch + x * 3] = 255;
                        data_[y * pitch + x * 3 + 1] = 255;
                        data_[y * pitch + x * 3 + 2] = 255;
                        break;
                    case ColorFormat.RGBA_8:
                        setPixelRGBA8(x, y, Color.white);
                        break;
                    case ColorFormat.GRAY_8:
                        setPixelGray8(x, y, 255);
                        break;
                }
            }
        }

        //This is extremely ineffective/ugly, but not really a priority
        /**
         * Generate a black/transparent-white/opague stripe pattern
         *
         * Params:  distance = Distance between 1 pixel wide stripes.
         */
        void generateStripes(const uint distance) pure
        {
            foreach(y; 0 .. size_.y) foreach(x; 0 .. size_.x)
            {
                if(cast(bool)(x % distance == y % distance)) final switch(format_)
                {
                    case ColorFormat.RGB_565:
                        data_[y * pitch + x * 2] = 255;
                        data_[y * pitch + x * 2 + 1] = 255;
                        break;
                    case ColorFormat.RGB_8:
                        data_[y * pitch + x * 3] = 255;
                        data_[y * pitch + x * 3 + 1] = 255;
                        data_[y * pitch + x * 3 + 2] = 255;
                        break;
                    case ColorFormat.RGBA_8:
                        setPixelRGBA8(x, y, Color.white);
                        break;
                    case ColorFormat.GRAY_8:
                        setPixelGray8(x, y, 255);
                        break;
                }
            }
        }

        ///Gamma correct the image with specified factor.
        void gammaCorrect(const real factor) pure
        in{assert(factor >= 0.0, "Gamma correction factor must not be negative");}
        body
        {
            Color pixel;
            foreach(y; 0 .. size_.y) foreach(x; 0 .. size_.x)
            {
                switch(format_)
                {
                    case ColorFormat.RGBA_8:
                        pixel = getPixel(x, y);
                        pixel.gammaCorrect(factor);
                        setPixelRGBA8(x, y, pixel);
                        break;
                    case ColorFormat.GRAY_8:
                        setPixelGray8(x, y, 
                        Color.gammaCorrect(data_[y * pitch + x], factor));
                        break;
                    default:
                        assert(false, "Unsupported color format for gamma correction");
                }
            }
        }

        ///Flip the image vertically.
        void flipVertical()
        {
            const uint pitch = pitch();
            ubyte[] tempRow = Allocator.allocArray!ubyte(pitch);
            foreach(row; 0 .. size_.y / 2)
            {
                //swap row and size_.y - row
                ubyte* rowA = data_.ptr + pitch * row;
                ubyte* rowB = data_.ptr + pitch * (size_.y - row - 1);
                memcpy(tempRow.ptr, rowA, pitch);
                memcpy(rowA, rowB, pitch);
                memcpy(rowB, tempRow.ptr, pitch);
            }
            Allocator.free(tempRow);
        }

    private:
        ///Get pitch (bytes per row) of the image.
        @property uint pitch() const pure {return bytesPerPixel(format_) * size_.x;}
}
