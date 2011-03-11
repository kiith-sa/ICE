
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module image;


import std.c.string;

import math.vector2;
import color;
import memory.memory;


//will be an RAII struct in D2
//could be optimized by adding a pitch data member (bytes per row)    
///Image object capable of storing images in various color formats.
final class Image
{
    invariant{assert(data_ !is null, "Image with NULL data");}

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
        this(uint width, uint height, ColorFormat format = ColorFormat.RGBA_8)
        {
            data_ = alloc!(ubyte)(width * height * bytes_per_pixel(format));
            size_ = Vector2u(width, height);
            format_ = format;
        }

        ///Destroy the image and free its memory.
        ~this(){free(data_);}
        
        ///Get color format of the image.
        ColorFormat format(){return format_;}

        ///Get size of the image in pixels.
        Vector2u size(){return size_;}

        ///Get image width in pixels.
        uint width(){return size_.x;}

        ///Get image height in pixels.
        uint height(){return size_.y;}

        ///Get direct access to image data.
        ubyte[] data(){return data_;}

        /**
         * Set RGBA pixel color.
         *
         * Only valid on RGBA_8 images.
         *
         * Params:  x     = X coordinate of the pixel.
         *          y     = Y coordinate of the pixel.
         *          color = Color to set.
         */
        void set_pixel_rgba8(uint x, uint y, Color color)
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8, "Incorrect image format");
        }
        body
        {
            uint offset = y * pitch + x * 4;
            data_[offset] = color.r;
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
        void set_pixel_gray8(uint x, uint y, ubyte color)
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
        Color get_pixel(uint x, uint y)
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Getting pixel color only supported with RGBA_8");
        }
        body
        {
            uint offset = y * pitch + x * 4;
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
        void generate_checkers(uint size)
        {
            bool white;
            for(uint y = 0; y < size_.y; ++y)
            {
                for(uint x = 0; x < size_.x; ++x)
                {
                    white = cast(bool)(x / size % 2);
                    if(cast(bool)(y / size % 2)){white = !white;}
                    if(white)
                    {
                        switch(format_)
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
                                set_pixel_rgba8(x, y, Color.white);
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel_gray8(x, y, 255);
                                break;
                            default:
                                assert(false, "Unsupported color format");
                        }
                    }
                }
            }
        }

        //This is extremely ineffective/ugly, but not really a priority
        /**
         * Generate a black/transparent-white/opague stripe pattern
         *
         * Params:  distance = Distance between 1 pixel wide stripes.
         */
        void generate_stripes(uint distance)
        {
            for(uint y = 0; y < size_.y; ++y)
            {
                for(uint x = 0; x < size_.x; ++x)
                {
                    if(cast(bool)(x % distance == y % distance))
                    {
                        switch(format_)
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
                                set_pixel_rgba8(x, y, Color.white);
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel_gray8(x, y, 255);
                                break;
                            default:
                                assert(false, "Unsupported color format");
                        }
                    }
                }
            }
        }

        ///Gamma correct the image with specified factor.
        void gamma_correct(real factor)
        in{assert(factor >= 0.0, "Gamma correction factor must not be negative");}
        body
        {
            Color pixel;
            for(uint y = 0; y < size_.y; ++y)
            {
                for(uint x = 0; x < size_.x; ++x)
                {
                    switch(format_)
                    {
                        case ColorFormat.RGBA_8:
                            pixel = get_pixel(x, y);
                            pixel.gamma_correct(factor);
                            set_pixel_rgba8(x, y, pixel);
                            break;
                        case ColorFormat.GRAY_8:
                            set_pixel_gray8(x, y, 
                                            color.gamma_correct(data_[y * pitch + x], factor));
                            break;
                        default:
                            assert(false, "Unsupported color format for gamma correction");
                    }
                }
            }
        }

        ///Flip the image vertically.
        void flip_vertical()
        {
            uint pitch = pitch();
            ubyte[] temp_row = alloc!(ubyte)(pitch);
            for(uint row = 0; row < size_.y / 2; ++row)
            {
                //swap row and size_.y - row
                ubyte* row_a = data_.ptr + pitch * row;
                ubyte* row_b = data_.ptr + pitch * (size_.y - row - 1);
                memcpy(temp_row.ptr, row_a, pitch);
                memcpy(row_a, row_b, pitch);
                memcpy(row_b, temp_row.ptr, pitch);
            }
            free(temp_row);
        }

    private:
        ///Get pitch (bytes per row) of the image.
        uint pitch(){return bytes_per_pixel(format_) * size_.x;}
}
