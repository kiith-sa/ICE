module image;


import math.vector2;
import color;
import allocator;

///Image object capable of storing images in various color formats.
final class Image
{
    invariant{assert(Data !is null, "Image with NULL data");}

    private:
        //note: could be optimized by adding a pitch data member (bytes per row)    

        //Image data. Manually allocated.
        ubyte[] Data = null;
        //Size of the image in pixels.
        Vector2u Size;
        //Color format of the image.
        ColorFormat Format;

    public:
        ///Construct an image with specified size and format.
        this(uint width, uint height, ColorFormat format = ColorFormat.RGBA_8)
        {
            Data = alloc!(ubyte)(width * height * bytes_per_pixel(format));
            Size = Vector2u(width, height);
            Format = format;
        }

        ///Destroy the image and free its memory.
        ~this(){free(Data);}
        
        ///Get color format of the image.
        ColorFormat format(){return Format;}

        ///Get size of the image.
        Vector2u size(){return Size;}

        ///Get direct access to the data stored in the image.
        ubyte[] data(){return Data;}

        ///Set RGBA pixel color.
        void set_pixel(uint x, uint y, Color color)
        in
        {
            assert(x < Size.x && y < Size.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Setting a non-RGBA_8 pixel with RGBA_8 color");
        }
        body
        {
            uint offset = (y * Size.x + x) * 4;
            Data[offset] = color.r;
            Data[offset + 1] = color.g;
            Data[offset + 2] = color.b;
            Data[offset + 3] = color.a;
        }

        ///Set grayscale pixel color.
        void set_pixel(uint x, uint y, ubyte color)
        in
        {
            assert(x < Size.x && y < Size.y, "Pixel out of range");
            assert(format == ColorFormat.GRAY_8,
                   "Setting a non-GRAY_8 pixel with GRAY_8 color");
        }
        body{Data[y * Size.x + x] = color;}

        ///Get RGBA pixel color.
        Color get_pixel(uint x, uint y)
        in
        {
            assert(x < Size.x && y < Size.y, "Pixel out of range");
            assert(format == ColorFormat.RGBA_8,
                   "Getting pixel color only supported with RGBA_8");
        }
        body
        {
            uint offset = (y * Size.x + x) * 4;
            return Color(Data[offset], Data[offset + 1], Data[offset + 2],
                         Data[offset + 3]);
        }
        
        //This is extremely ineffective/ugly, but not really a priority
        ///Generate a black/transparent-white/opague checker pattern
        ///with specified size of one square of the pattern.
        void generate_checkers(uint size)
        {
            bool white;
            for(uint y = 0; y < Size.y; ++y)
            {
                for(uint x = 0; x < Size.x; ++x)
                {
                    white = cast(bool)(x / size % 2);
                    if(cast(bool)(y / size % 2)){white = !white;}
                    if(white)
                    {
                        switch(Format)
                        {
                            case ColorFormat.RGB_565:
                                Data[(y * Size.x + x) * 2] = 255;
                                Data[(y * Size.x + x) * 2 + 1] = 255;
                                break;
                            case ColorFormat.RGBA_8:
                                set_pixel(x, y, Color(255, 255, 255, 255));
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel(x, y, 255);
                                break;
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
            for(uint y = 0; y < Size.y; ++y)
            {
                for(uint x = 0; x < Size.x; ++x)
                {
                    if(cast(bool)(x % distance == y % distance))
                    {
                        switch(Format)
                        {
                            case ColorFormat.RGB_565:
                                Data[(y * Size.x + x) * 2] = 255;
                                Data[(y * Size.x + x) * 2 + 1] = 255;
                                break;
                            case ColorFormat.RGBA_8:
                                set_pixel(x, y, Color(255, 255, 255, 255));
                                break;
                            case ColorFormat.GRAY_8:
                                set_pixel(x, y, 255);
                                break;
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
            for(uint y = 0; y < Size.y; ++y)
            {
                for(uint x = 0; x < Size.x; ++x)
                {
                    switch(Format)
                    {
                        case ColorFormat.RGBA_8:
                            pixel = get_pixel(x, y);
                            pixel.gamma_correct(factor);
                            set_pixel(x, y, pixel);
                            break;
                        case ColorFormat.GRAY_8:
                            set_pixel(x, y,
                                      color.gamma_correct(Data[y * Size.x + x], 
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
