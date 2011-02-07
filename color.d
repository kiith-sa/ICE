module color;


import math.math;

///Represents color formats used by images and screen/
enum ColorFormat
{
    ///16-bit RGB without alpha
    RGB_565,
    ///32-bit RGBA
    RGBA_8,
    ///8-bit grayscale
    GRAY_8
}

///Return number of bytes per pixel given color format uses.
uint bytes_per_pixel(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_565:
            return 2;
            break;
        case ColorFormat.RGBA_8:
            return 4;
            break;
        case ColorFormat.GRAY_8:
            return 1;
            break;
        default:
            assert(false, "Unsupported image color format!");
            break;
    }
}

//this should be trivial using compile time reflection in D2
///Return a string representation of given color format.
string to_string(ColorFormat format, bool short_format = false)
{
    switch(format)
    {
        case ColorFormat.RGB_565:
            return short_format ? "RGB_565" : "ColorFormat.RGB_565";
            break;
        case ColorFormat.RGBA_8:
            return short_format ? "RGBA_8" : "ColorFormat.RGBA_8";
            break;
        case ColorFormat.GRAY_8:
            return short_format ? "GRAY_8" : "ColorFormat.GRAY_8";
            break;
        default:
            assert(false, "Unsupported image color format!");
            break;
    }
}

///32-bit RGBA8 color
align(1) struct Color
{
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;

    ///Common color constants, identical to HTML
    static const Color white = Color(255, 255, 255);
    static const Color grey = Color(128, 128, 128);
    static const Color black = Color(0, 0, 0);

    static const Color red = Color(255, 0, 0);
    static const Color green = Color(0, 255, 0);
    static const Color blue = Color(0, 0, 255);
    static const Color burgundy = Color(128, 0, 0);

    static const Color yellow = Color(255, 255, 0);
    static const Color cyan = Color(0, 255, 255);
    static const Color magenta = Color(255, 0, 255);
    static const Color forest_green = Color(128, 128, 0);
    static const Color dark_purple = Color(128, 0, 128);

    ///Fake constructor.
    static Color opCall(ubyte r, ubyte g, ubyte b, ubyte a)
    {
        Color color;
        color.r = r;
        color.g = g;
        color.b = b;
        color.a = a;
        return color;
    }

    ///Fake constructor for RGB without alpha.
    static Color opCall(ubyte r, ubyte g, ubyte b){return Color(r, g, b, 255);}

    ///Returns the average intensity of the color.
    ubyte average()
    {
        real average = (cast(real)r + cast(real)g + cast(real) b) / 3.0;
        return round32(average);
    }
    unittest
    {
        Color color = Color(253, 254, 255, 255);
        assert(color.average == 254);
        color = Color(253, 253, 254, 255);
        assert(color.average == 253);
        color = Color(253, 254, 254, 255);
        assert(color.average == 254);
        color = Color(0, 0, 1, 255);
        assert(color.average == 0);
        color = Color(255, 255, 255, 255);
        assert(color.average == 255);
    }

    ///Returns lightness of the color.
    ubyte lightness()
    {
        uint d = max(r, g, b) + min(r, g, b);
        return round32(0.5f * d); 
    }
    unittest
    {
        Color color = Color(253, 254, 255, 255);
        assert(color.luminance == 254);
    }

    ///Returns luminance of the color.
    ubyte luminance(){return round32(0.3 * r + 0.59 * g + 0.11 * b);}
    
    ///Adds two colors (values are clamped to range 0 .. 255).
    Color opAdd(Color c)
    {
        return Color(min(255, r + c.r), min(255, g + c.g),
                     min(255, b + c.b), min(255, a + c.a));
    }
    unittest
    {
        Color color1 = Color(253, 254, 255, 255);
        Color color2 = Color(128, 0, 87, 42);
        Color color3 = Color(3, 145, 192, 17);
        assert(color1 + color2 == Color(255, 254, 255, 255));
        assert(color2 + color3 == Color(131, 145, 255, 59));
        assert(color3 + color1 == Color(255, 255, 255, 255));
    }
    
    ///Interpolates the color with a float between 0 and 1 to another color.
    Color interpolated(Color c, float d)
    in
    {
        assert(d >= 0.0 && d <= 1.0, 
               "Color interpolation value must be between 0.0 and 1.0");
    }
    body
    {
        float inv = 1.0 - d;
        //this truncates the fraction part and hence is imprecise, but fast.
        return Color(floor_u8(r * d + c.r * inv), 
                     floor_u8(g * d + c.g * inv),
                     floor_u8(b * d + c.b * inv), 
                     floor_u8(a * d + c.a * inv));
    }

    ///Set grayscale color.
    void gray(ubyte gray){r = g = b = a = gray;}

    ///Gamma correct the color with specified factor.
    void gamma_correct(real factor)
    in{assert(factor >= 0.0, "Can't gamma correct with a negative factor");}
    body
    {
        real scale = 1.0, temp = 0.0;
        real R = cast(real)r;
        real G = cast(real)g;
        real B = cast(real)b;
        real factor_inv = factor / 255.0;
        R *= factor_inv;
        G *= factor_inv;
        B *= factor_inv;
        if (R > 1.0 && (temp = (1.0 / R)) < scale) scale = temp;
        if (G > 1.0 && (temp = (1.0 / G)) < scale) scale = temp;
        if (B > 1.0 && (temp = (1.0 / B)) < scale) scale = temp;
        scale *= 255.0;
        R *= scale;	
        G *= scale;	
        B *= scale;
        r = cast(ubyte)R;
        g = cast(ubyte)G;
        b = cast(ubyte)B;
    }
}

///Gamma correct a GRAY_8 color.
ubyte gamma_correct(ubyte color, real factor)
in{assert(factor >= 0.0, "Can't gamma correct with a negative factor");}
body
{
    return cast(ubyte)min(cast(real)color * factor, 255.0L);
}
