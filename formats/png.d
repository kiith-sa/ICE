
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.png;


import std.stdio;

import lodepng.Decode;
import lodepng.Encode;

import color;


package:

/**
 * Encode image data in PNG format, ready to write to a file.
 *
 * Params:  data   = Data to encode. Size of the array must correspond with
 *                   specified width, height and color format.
 *          width  = Image width in pixels.
 *          height = Image height in pixels.
 *          format = Color format of the image.
 *
 * Returns: Array with encoded data.
 *
 * Throws:  Exception in case of an encoding error.
 */
ubyte[] encode_png(ubyte[] data, uint width, uint height, ColorFormat format)
in
{
    assert(data.length == width * height * bytes_per_pixel(format),
           "Incorrect length of data to encode to a PNG image");
    assert(format == ColorFormat.RGBA_8 || format == ColorFormat.RGB_8, 
           "Unsupported color format for PNG encoding");
}
body
{
    auto compression_strategy = CompressionStrategy.Filtered;
    auto filter_strategy = FilterStrategy.Dynamic;
    auto encode_options = EncodeOptions(compression_strategy, filter_strategy);

    PngInfo info;
    info.image = PngImage(width, height, cast(ubyte)bits_per_channel(format),
                          png_color_type(format));

    try{return encode(data, info, encode_options);}
    catch(PngException e)
    {
        string error = "PNG encoding error: " ~ e.msg;
        writefln(error);
        throw new Exception(error);
    }
}

private:

/**
 * Determine how many bits per channel does a ColorFormat need. 
 *
 * Params:  format = Format to check.
 *
 * Returns: Bits per channel of the format.
 */
uint bits_per_channel(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_8, ColorFormat.RGBA_8:
            return 8;
        default:
            assert(false, "Unsupported color format for PNG.");
    }
}

/**
 * Convert ColorFormat to LodePNG ColorType.
 *
 * Params:  format = ColorFormat to convert.
 *
 * Returns: ColorType corresponding to the format.
 */
ColorType png_color_type(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_8:
            return ColorType.RGB;
        case ColorFormat.RGBA_8:
            return ColorType.RGBA;
        default:
            assert(false, "Unsupported color type for PNG.");
    }
}
