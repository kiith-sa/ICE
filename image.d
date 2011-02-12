
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module image;


import math.vector2;
import color;
import memory.memory;

///Image object capable of storing images in various color formats.
final class Image
{
    invariant{assert(data_ !is null, "Image with NULL data");}

    private:
        //note: could be optimized by adding a pitch data member (bytes per row)    

        //Image data. Manually allocated.
        ubyte[] data_ = null;
        //Size of the image in pixels.
        Vector2u size_;
        //Color format of the image.
        ColorFormat format_;

    public:
        ///Construct an image with specified size and format.
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

        ///Get size of the image.
        Vector2u size(){return size_;}

        ///Get direct access to the data stored in the image.
        ubyte[] data(){return data_;}

        ///Set RGBA pixel color.
        void set_pixel(uint x, uint y, Color color)
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Setting a non-RGBA_8 pixel with RGBA_8 color");
        }
        body
        {
            uint offset = (y * size_.x + x) * 4;
            data_[offset] = color.r;
            data_[offset + 1] = color.g;
            data_[offset + 2] = color.b;
            data_[offset + 3] = color.a;
        }

        ///Set grayscale pixel color.
        void set_pixel(uint x, uint y, ubyte color)
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.GRAY_8,
                   "Setting a non-GRAY_8 pixel with GRAY_8 color");
        }
        body{data_[y * size_.x + x] = color;}

        ///Get RGBA pixel color.
        Color get_pixel(uint x, uint y)
        in
        {
            assert(x < size_.x && y < size_.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Getting pixel color only supported with RGBA_8");
        }
        body
        {
            uint offset = (y * size_.x + x) * 4;
            return Color(data_[offset], data_[offset + 1], data_[offset + 2],
                         data_[offset + 3]);
        }
        
        //This is extremely ineffective/ugly, but not really a priority
        ///Generate a black/transparent-white/opague checker pattern
        ///with specified size of one square of the pattern.
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
                                data_[(y * size_.x + x) * 2] = 255;
                                data_[(y * size_.x + x) * 2 + 1] = 255;
                                break;
                            case ColorFormat.RGBA_8:
                                set_pixel(x, y, Color.white);
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel(x, y, 255);
                                break;
                            default:
                                assert(false, "Unsupported color format");
                        }
                    }
                }
            }
        }

        //This is extremely ineffective/ugly, but not really a priority
        ///Generate a black/transparent-white/opague stripe pattern
        ///with specified distance between 1-pixel wide stripes.
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
                                data_[(y * size_.x + x) * 2] = 255;
                                data_[(y * size_.x + x) * 2 + 1] = 255;
                                break;
                            case ColorFormat.RGBA_8:
                                set_pixel(x, y, Color.white);
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel(x, y, 255);
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
        in
        {
            assert(factor >= 0.0, "Gamma correction factor must not be negative");
        }
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
                            set_pixel(x, y, pixel);
                            break;
                        case ColorFormat.GRAY_8:
                            set_pixel(x, y,
                                      color.gamma_correct(data_[y * size_.x + x], 
                                                          factor));
                            break;
                        default:
                            assert(false, "Unsupported color format "
                                          "for gamma correction");
                    }
                }
            }
        }
}
