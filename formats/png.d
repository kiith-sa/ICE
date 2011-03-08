
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.png;


import std.stdio;

import formats.zlib;
import formats.pngcommon;
import formats.pngdecoder;
import formats.pngencoder;
import util.exception;
import color;


package:

///TODO: Vectors
/**
 * Encode image data to PNG format, ready to write to a file.
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
    PNGInfo info = PNGInfo(PNGImage(width, height, cast(ubyte)bits_per_channel(format),
                           png_color_type(format)));

    PNGEncoder encoder;
    encoder.compression = CompressionStrategy.Filtered;
    encoder.filter = PNGFilter.Dynamic;
    encoder.level = 9;

    try{return encoder.encode(info, data);}
    catch(PNGException e){throw new Exception("PNG encoding error: " ~ e.msg);}
}

/**
 * Decode data in PNG format to raw image data.
 *
 * Params:  data   = Data to decode. Must be valid PNG data (e.g. loaded from a file).
 *          width  = Image width in pixels will be written here.
 *          height = Image height in pixels will be written here.
 *          format = Color format of the image will be written here.
 *
 * Returns: Decoded image data.
 *
 * Throws:  Exception on failure.
 */
ubyte[] decode_png(ubyte[] data, out uint width, out uint height, out ColorFormat format)
{
    PNGDecoder decoder;
    PNGInfo info;

    try
    {
        ubyte[] decoded = decoder.decode(data, info);
        width = info.image.width;
        height = info.image.height;
        format = color_format_from_png(info.image.color_type, info.image.bit_depth);
        assert(decoded.length == width * height * bytes_per_pixel(format),
               "Image data size does not match image parameters");
        return decoded;
    }
    catch(PNGException e){throw new Exception("PNG decoding error: " ~ e.msg);}
    catch(Exception e){throw new Exception("PNG decompression error: " ~ e.msg);}
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
            assert(false, "Unsupported PNG color format.");
    }
}

/**
 * Convert ColorFormat to PNG color type.
 *
 * Params:  format = ColorFormat to convert.
 *
 * Returns: PNGColorType corresponding to the format.
 */
PNGColorType png_color_type(ColorFormat format)
{
    switch(format)
    {
        case ColorFormat.RGB_8:
            return PNGColorType.RGB;
        case ColorFormat.RGBA_8:
            return PNGColorType.RGBA;
        default:
            assert(false, "Unsupported PNG color format.");
    }
}

/**
 * Convert PNG color type and channel bit depth to ColorFormat.
 *
 * Params:  type      = PNG color type.
 *          bit_depth = PNG bit depth per channel.
 *
 * Returns: Corresponding color format.
 *
 * Throws:  Exception if the PNG color type/bitdepth is not supported.
 */
ColorFormat color_format_from_png(PNGColorType type, ubyte bit_depth)
{
    switch(type)
    {
        case PNGColorType.Greyscale:
            enforceEx!(Exception)(bit_depth == 8, "Unsupported PNG grayscale bit depth");
            return ColorFormat.GRAY_8;
        case PNGColorType.RGB:
            enforceEx!(Exception)(bit_depth == 8, "Unsupported PNG RGB bit depth");
            return ColorFormat.RGB_8;
        case PNGColorType.RGBA:
            enforceEx!(Exception)(bit_depth == 8, "Unsupported PNG RGBA bit depth");
            return ColorFormat.RGBA_8;
        default:
            throw new Exception("Unsupported PNG color type.");
    }
}
