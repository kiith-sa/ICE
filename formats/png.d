
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///PNG encoding/decoding interface.
module formats.png;


import std.exception;

import formats.zlib;
import formats.pngcommon;
import formats.pngdecoder;
import formats.pngencoder;
import formats.image;
import memory.memory;
import color;


package:
/**
 * Encode image data to PNG format, ready to write to a file.
 *
 * Params:  data   = Data to encode. Size of the array must correspond with
 *                   specified width, height and color format.
 *          width  = Image width in pixels.
 *          height = Image height in pixels.
 *          format = Color format of the image.
 *
 * Returns: Manually allocated array with encoded data. Must be manually freed.
 *
 * Throws:  ImageFileException in case of an encoding error.
 */
ubyte[] encodePNG(const ubyte[] data, const uint width, const uint height, const ColorFormat format)
in
{
    assert(data.length == width * height * bytesPerPixel(format),
           "Incorrect length of data to encode to a PNG image");
    assert(format == ColorFormat.RGBA_8 || format == ColorFormat.RGB_8, 
           "Unsupported color format for PNG encoding");
}
body
{
    const PNGInfo info = PNGInfo(PNGImage(width, height, cast(ubyte)bitsPerChannel(format),
                                 pngColorType(format)));

    PNGEncoder encoder;
    encoder.compression = CompressionStrategy.Filtered;
    encoder.filter = PNGFilter.Dynamic;
    encoder.level = 9;

    try{return encoder.encode(info, data);}
    catch(PNGException e){throw new ImageFileException("PNG encoding error: " ~ e.msg);}
}

/**
 * Decode data in PNG format to raw image data.
 *
 * Params:  data   = Data to decode. Must be valid PNG data (e.g. loaded from a file).
 *          width  = Image width in pixels will be written here.
 *          height = Image height in pixels will be written here.
 *          format = Color format of the image will be written here.
 *
 * Returns: Manually allocated decoded image data. Must be manually freed.
 *
 * Throws:  ImageFileException on failure.
 */
ubyte[] decodePNG(const ubyte[] data, out uint width, out uint height, out ColorFormat format)
{
    PNGDecoder decoder;
    PNGInfo info;

    try
    {
        ubyte[] decoded = decoder.decode(data, info);
        scope(failure){free(decoded);}

        width = info.image.width;
        height = info.image.height;
        format = colorFormatFromPNG(info.image.colorType, info.image.bitDepth);
        assert(decoded.length == width * height * bytesPerPixel(format),
               "Image data size does not match image parameters");

        return decoded;
    }
    catch(PNGException e){throw new ImageFileException("PNG decoding error: " ~ e.msg);}
    catch(CompressionException e)
    {
        throw new ImageFileException("PNG decompression error: " ~ e.msg);
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
uint bitsPerChannel(const ColorFormat format) pure
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
PNGColorType pngColorType(const ColorFormat format) pure
{
    switch(format)
    {
        case ColorFormat.RGB_8:  return PNGColorType.RGB;
        case ColorFormat.RGBA_8: return PNGColorType.RGBA;
        default: assert(false, "Unsupported PNG color format.");
    }
}

/**
 * Convert PNG color type and channel bit depth to ColorFormat.
 *
 * Params:  type      = PNG color type.
 *          bitDepth = PNG bit depth per channel.
 *
 * Returns: Corresponding color format.
 *
 * Throws:  ImageFileException if the PNG color type/bitdepth is not supported.
 */
ColorFormat colorFormatFromPNG(const PNGColorType type, const ubyte bitDepth) pure
{
    switch(type)
    {
        case PNGColorType.Greyscale:
            enforceEx!ImageFileException(bitDepth == 8, "Unsupported PNG gray bit depth");
            return ColorFormat.GRAY_8;
        case PNGColorType.RGB:
            enforceEx!ImageFileException(bitDepth == 8, "Unsupported PNG RGB bit depth");
            return ColorFormat.RGB_8;
        case PNGColorType.RGBA:
            enforceEx!ImageFileException(bitDepth == 8, "Unsupported PNG RGBA bit depth");
            return ColorFormat.RGBA_8;
        default:
            throw new ImageFileException("Unsupported PNG color type.");
    }
}
