
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///RGBA Color struct and utility functions.
module color;


import std.algorithm;
import std.random;
import std.string;
import std.traits;

import math.math;
import util.unittests;


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
 * Return number of bytes specified color format uses per pixel.
 *
 * Params:  format = Color format to check.
 *
 * Returns: Bytes per pixel needed by specified color format.
 */
uint bytesPerPixel(const ColorFormat format) pure
{
    final switch(format)
    {
        case ColorFormat.RGB_565: return 2;
        case ColorFormat.RGB_8:   return 3;
        case ColorFormat.RGBA_8:  return 4;
        case ColorFormat.GRAY_8:  return 1;
    }
}

///32-bit RGBA8 color.
struct Color
{
    ///Red channel.
    ubyte r;
    ///Green channel.
    ubyte g;
    ///Blue channel.
    ubyte b;
    ///Alpha channel.
    ubyte a = 255;

    ///Common color constants, identical to HTML.
    static immutable white        = rgb!"FFFFFF";
    static immutable grey         = rgb!"888";
    static immutable black        = rgb!"000";
                                        
    static immutable red          = rgb!"FF0000";
    static immutable green        = rgb!"00FF00";
    static immutable blue         = rgb!"0000FF";
    static immutable burgundy     = rgb!"800";
                    
    static immutable yellow       = rgb!"FFFF00";
    static immutable cyan         = rgb!"00FFFF";
    static immutable magenta      = rgb!"FF00FF";
    static immutable forestGreen = rgb!"880";
    static immutable darkPurple  = rgb!"808";

    /**
     * Construct a color.
     *
     * Params:  r = Red channel value.
     *          g = Green channel value.
     *          b = Blue channel value.
     *          a = Alpha channel value.
     */
    this(const ubyte r, const ubyte g, const ubyte b, const ubyte a) pure
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }
                   
    ///Comparison for sorting.
    int opCmp(ref const Color c) const pure nothrow
    {
        return r != c.r ? r - c.r :
               g != c.g ? g - c.g :
               b != c.b ? b - c.b :
               a != c.a ? a - c.a : 
                          0;
    }

    ///Return the average RGB intensity of the color.
    @property ubyte average() const
    {
        const real average = (r + g + b) / 3.0L;
        return round!ubyte(average);
    }
    ///Unittest for average().
    private static void unittestAverage()
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
    @property ubyte lightness() const
    {
        uint d = max(r, g, b) + min(r, g, b);
        return round!ubyte(0.5f * d); 
    }

    ///Return luminance of the color.
    @property ubyte luminance() const
    {
        return round!ubyte(0.3 * r + 0.59 * g + 0.11 * b);
    }
    ///Unittest for luminance().
    private static void unittestLuminance()
    {
        Color color = Color(253, 254, 255, 255);
        assert(color.luminance == 254);
    }
    
    ///Add two colors (values are clamped to range 0 .. 255).
    Color opBinary(string op)(const Color c) const pure if(op == "+")
    {
        return Color(cast(ubyte)min(255, r + c.r), 
                     cast(ubyte)min(255, g + c.g),
                     cast(ubyte)min(255, b + c.b), 
                     cast(ubyte)min(255, a + c.a));
    }
    ///Unittest for opBinary!"+"
    private static void unittestPlus()
    {
        Color color1 = Color(253, 254, 255, 255);
        Color color2 = Color(128, 0, 87, 42);
        Color color3 = Color(3, 145, 192, 17);
        assert(color1 + color2 == Color(255, 254, 255, 255));
        assert(color2 + color3 == Color(131, 145, 255, 59));
        assert(color3 + color1 == Color(255, 255, 255, 255));
    }

    ///Multiply a color by a float (values are clamped to range 0 .. 255).
    Color opBinary(string op)(const float m) const if(op == "*")
    {
        return Color(round!ubyte(clamp(r * m, 0.0f, 255.0f)), 
                     round!ubyte(clamp(g * m, 0.0f, 255.0f)),
                     round!ubyte(clamp(b * m, 0.0f, 255.0f)), 
                     round!ubyte(clamp(a * m, 0.0f, 255.0f)));
    }
    ///Unittest for opBinary!"*"
    private static void unittestMultiply()
    {
        Color color1 = Color(128, 128, 128, 128);
        Color color2 = Color(255, 255, 255, 255);
        assert(color1 * 0.5 == color2 * 0.25);
        assert(color1 * 0.5 == Color(64, 64, 64, 64));
    }

    ///Add a color to this color (values are clamped to range 0 .. 255).
    void opOpAssign(string op)(const Color c) pure if(op == "+")
    {
        this = this + c;
    }
    ///Unittest for opOpAssign!"+"
    private static void unittestPlusAssign()
    {
        Color color1 = Color(253, 254, 255, 255);
        Color color2 = Color(128, 0, 87, 42);
        Color color3 = Color(3, 145, 192, 17);
        color1 += color2;
        color2 += color3;
        color3 += color1;
        assert(color1 == Color(255, 254, 255, 255));
        assert(color2 == Color(131, 145, 255, 59));
        assert(color3 == Color(255, 255, 255, 255));
    }

    ///Multiply this color by a float (values are clamped to range 0 .. 255).
    void opOpAssign(string op)(const float m) if(op == "*")
    {
        this = this * m;
    }
    ///Unittest for opOpAssign!"*"
    private static void unittestMultiplyAssign()
    {
        Color color1 = Color(128, 128, 128, 128);
        Color color2 = Color(255, 255, 255, 255);
        color1 *= 0.5;
        color2 *= 0.25;
        assert(color1 == color2);
        assert(color1 == Color(64, 64, 64, 64));
    }

    /**
     * Interpolate this color to another color.
     *
     * Params:  c = Color to interpolate with.
     *          d = Interpolation ratio. 1 is this color, 0 other color, 0.5 half in between.
     *              Must be in 0.0 .. 1.0 range.
     */
    Color interpolated(const Color c, const float d) const
    in{assert(d >= 0.0 && d <= 1.0, "Color interpolation value must be between 0.0 and 1.0");}
    body
    {
        const dByte   = floor!ubyte(d * 255.0);
        const invByte = cast(ubyte)(255 - dByte);

        //ugly, but fast
        //colors are multiplied as ubytes from 0 to 255 and then divided by 256
        return Color(cast(ubyte)((r * dByte + c.r * invByte) >> 8),
                     cast(ubyte)((g * dByte + c.g * invByte) >> 8),
                     cast(ubyte)((b * dByte + c.b * invByte) >> 8),
                     cast(ubyte)((a * dByte + c.a * invByte) >> 8));
    }

    ///Set grayscale color.
    @property void gray8(const ubyte gray) pure {r = g = b = a = gray;}

    ///Gamma correct the color with specified factor.
    void gammaCorrect(const real factor) pure
    in{assert(factor >= 0.0, "Can't gamma correct with a negative factor");}
    body
    {
        real scale = 1.0;
        real temp = 0.0;
        real R = cast(real)r;
        real G = cast(real)g;
        real B = cast(real)b;
        const real factorInv = factor / 255.0;
        R *= factorInv;
        G *= factorInv;
        B *= factorInv;
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

    ///Return a random color with full opacity.
    static Color randomRGB()
    {
        Color result;
        result.r = cast(ubyte)uniform(0, 256);
        result.g = cast(ubyte)uniform(0, 256);
        result.b = cast(ubyte)uniform(0, 256);
        result.a = 255;
        return result;
    }

    /**
     * Gamma correct a GRAY_8 color.
     *
     * Params:  color  = Color (grayscale) to gamma correct.
     *          factor = Gamma correction factor.
     *
     * Returns: Gamma corrected color.
     */
    static ubyte gammaCorrect(const ubyte color, const real factor) pure
    in
    {
        assert(factor >= 0.0, "Can't gamma correct with a negative factor");
    }
    body
    {
        return cast(ubyte)min(cast(real)color * factor, 255.0L);
    }
}
mixin registerTest!(Color.unittestAverage, "Color.average");
mixin registerTest!(Color.unittestLuminance, "Color.luminance");
mixin registerTest!(Color.unittestPlus, "Color.+");
mixin registerTest!(Color.unittestMultiply, "Color.multiply");
mixin registerTest!(Color.unittestPlusAssign, "Color.+=");
mixin registerTest!(Color.unittestMultiplyAssign, "Color.*=");

///RGB color from a hexadecimal string (CSS style), e.g. FFFFFF for white.
template rgb(string c) if(c.length == 6)
{
    enum auto rgb = rgba!(c ~ "FF");
}

///RGBA color from a hexadecimal string (CSS style), e.g. FFFFFF80 for half-transparent white.
template rgba(string c) if(c.length == 8) 
{
    enum auto rgba = Color(hexColor(c[0 .. 2]), hexColor(c[2 .. 4]), 
                           hexColor(c[4 .. 6]), hexColor(c[6 .. 8]));
}

///RGB color from a short hexadecimal string (CSS style), e.g. FFF for white.
template rgb(string c) if(c.length == 3)
{
    enum auto rgb = rgb!(c[0] ~ "0" ~ c[1] ~ "0" ~ c[2] ~ "0");
}

///RGBA color from a short hexadecimal string (CSS style), e.g. FFF8 for half-transparent white.
template rgba(string c) if(c.length == 4) 
{
    enum auto rgba = rgba!(c[0] ~ "0" ~ c[1] ~ "0" ~ c[2] ~ "0" ~ c[3] ~ "0");
}
void unittestRgba()
{
    assert(rgba!"f0F0F0F0" == rgba!"FFFF"  &&
           rgb!"FFF"       == rgb!"F0F0F0" &&
           rgb!"FFF"       == rgba!"F0F0F0FF" &&
           rgb!"FFF"       == Color(240, 240, 240, 255));
}
mixin registerTest!(unittestRgba, "color.rgba");
///Get value of a 2-character hexadecimal sequence corresponding to single color channel.
ubyte hexColor(string hex) pure
{
    assert(hex.length == 2, "Hex string to get color from must have 2 chars");
    hex = toUpper(hex);
    return cast(ubyte)(16 * hexDigit(hex[0]) + hexDigit(hex[1]));
}

private:
///Convert a hexadecimal digit to integer.
auto hexDigit(const char hex) pure
{
    if(hex >= '0' && hex <= '9')     {return hex - '0';}
    else if(hex >= 'A' && hex <= 'F'){return 10 + hex - 'A';}
    assert(false, "'" ~ hex ~ "' is not a hexadecimal digit");
}
