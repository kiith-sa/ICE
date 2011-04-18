
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module color;


import math.math;


///Represents color formats used by images and screen.
enum ColorFormat
{
    ///16-bit RGB without alpha.
    RGB_565,
    ///24-bit RGB.
    RGB_8,
    ///32-bit RGBA.
    RGBA_8,
    ///8-bit grayscale.
    GRAY_8
}

/**
 * Return number of bytes per pixel specified color format uses.
 *
 * Params:  format = Color format to check.
 *
 * Returns: Bytes per pixel needed by specified color format.
 */
uint bytes_per_pixel(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_565:
            return 2;
        case ColorFormat.RGB_8:
            return 3;
        case ColorFormat.RGBA_8:
            return 4;
        case ColorFormat.GRAY_8:
            return 1;
        default:
            assert(false, "Unsupported image color format!");
    }
}

/**
 * Return a string representation of specified color format.
 *
 * Params:  format = Color format to get string representation of.
 *
 * Returns: String representation of specified color format.
 */
string to_string(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_565:
            return "RGB_565";
        case ColorFormat.RGB_8:
            return "RGB_8";
        case ColorFormat.RGBA_8:
            return "RGBA_8";
        case ColorFormat.GRAY_8:
            return "GRAY_8";
        default:
            assert(false, "Unsupported image color format!");
    }
}

///32-bit RGBA8 color.
align(1) struct Color
{
    ///Red channel.
    ubyte r;
    ///Green channel.
    ubyte g;
    ///Blue channel.
    ubyte b;
    ///Alpha channel.
    ubyte a;

    ///Common color constants, identical to HTML.
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

    /**
     * Construct a color.
     *
     * Params:  r = Red channel value.
     *          g = Green channel value.
     *          b = Blue channel value.
     *          a = Alpha channel value.
     *
     * Returns: Color with specified RGBA values.
     */
    static Color opCall(ubyte r, ubyte g, ubyte b, ubyte a)
    {
        Color color;
        color.r = r;
        color.g = g;
        color.b = b;
        color.a = a;
        return color;
    }

    /**
     * Construct a color (no alpha).
     *
     * Alpha is fully opague (255).
     *
     * Params:  r = Red channel value.
     *          g = Green channel value.
     *          b = Blue channel value.
     *
     * Returns: Color with specified RGB values.
     */
    static Color opCall(ubyte r, ubyte g, ubyte b){return Color(r, g, b, 255);}

    ///Return the average intensity of the color.
    ubyte average()
    {
        real average = (cast(real)r + cast(real)g + cast(real) b) / 3.0;
        return cast(ubyte)round_s32(average);
    }
    ///Unittest for average().
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

    ///Return lightness of the color.
    ubyte lightness()
    {
        uint d = max(r, g, b) + min(r, g, b);
        return cast(ubyte)round_s32(0.5f * d); 
    }

    ///Return luminance of the color.
    ubyte luminance(){return cast(ubyte)round_s32(0.3 * r + 0.59 * g + 0.11 * b);}
    ///Unittest for luminance().
    unittest
    {
        Color color = Color(253, 254, 255, 255);
        assert(color.luminance == 254);
    }
    
    /**
     * Add two colors (values are clamped to range 0 .. 255).
     *
     * Params:  c = Color to add.
     *
     * Returns: Result of color addition.
     */
    Color opAdd(Color c)
    {
        return Color(cast(ubyte)min(255, r + c.r), 
                     cast(ubyte)min(255, g + c.g),
                     cast(ubyte)min(255, b + c.b), 
                     cast(ubyte)min(255, a + c.a));
    }
    ///Unittest for add().
    unittest
    {
        Color color1 = Color(253, 254, 255, 255);
        Color color2 = Color(128, 0, 87, 42);
        Color color3 = Color(3, 145, 192, 17);
        assert(color1 + color2 == Color(255, 254, 255, 255));
        assert(color2 + color3 == Color(131, 145, 255, 59));
        assert(color3 + color1 == Color(255, 255, 255, 255));
    }
    
    /**
     * Interpolate the color to another color.
     *
     * Params:  c = Color to interpolate with.
     *          d = Interpolation ratio. 1 is this color, 0 other color, 0.5 half in between.
     *              Must be in 0.0 .. 1.0 range.
     */
    Color interpolated(Color c, float d)
    in{assert(d >= 0.0 && d <= 1.0, "Color interpolation value must be between 0.0 and 1.0");}
    body
    {
        ubyte d_byte = floor_u8(d * 255.0);
        ubyte inv_byte = 255 - d_byte;

        //ugly, but fast
        //colors are multiplied as ubytes from 0 to 255 and then divided by 256
        return Color(cast(ubyte)((r * d_byte + c.r * inv_byte) >> 8),
                     cast(ubyte)((g * d_byte + c.g * inv_byte) >> 8),
                     cast(ubyte)((b * d_byte + c.b * inv_byte) >> 8),
                     cast(ubyte)((a * d_byte + c.a * inv_byte) >> 8));
    }

    ///Set grayscale color.
    void gray_8(ubyte gray){r = g = b = a = gray;}

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

/**
 * Gamma correct a GRAY_8 color.
 *
 * Params:  color  = Color (grayscale) to gamma correct.
 *          factor = Gamma correction factor.
 *
 * Returns: Gamma corrected color.
 */
ubyte gamma_correct(ubyte color, real factor)
in{assert(factor >= 0.0, "Can't gamma correct with a negative factor");}
body{return cast(ubyte)min(cast(real)color * factor, 255.0L);}
