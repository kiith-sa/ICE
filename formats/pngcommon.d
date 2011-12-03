/***************************************************************************************************
License:
Copyright (c) 2005-2007 Lode Vandevenne
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.<br>
  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.<br>
  - Neither the name of Lode Vandevenne nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.<br>

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Lode Vandevenne (original version in C++), Lutger Blijdestijn (D version) : lutger dot blijdestijn at gmail dot com, Ferdinand Majerech (refactoring)
*/


///Structs and functions shared by PNG encoder and decoder.
module formats.pngcommon;
@system


import std.algorithm;
import std.exception;

import formats.zlib;
import color;


package:
///Magic number at the start of a PNG file.
immutable ubyte[] png_magic_number = [137, 80, 78, 71, 13, 10, 26, 10];

///PNG filter strategy.
enum PNGFilter : ubyte
{
    ///No filtering.
    None = 0,
    Sub = 1,
    Up = 2,
    Average = 3,
    ///Paeth filter (usually the best except for Dynamic).
    Paeth = 4,
    ///Separate filter for each line (best compresiion).
    Dynamic,
}

///Exception thrown at PNG decoding or encoding errors.
class PNGException : Exception{this(string msg){super(msg);}}

/**
 * Color types supported by the png format.
 *
 * See the $(LINK2 http://www.w3.org/TR/PNG/index-noobject.html#6Colour-values, png specification)
 * for details.
 */
enum PNGColorType : ubyte
{
    ///Allowed bit depths: 1, 2, 4, 8 and 16.
    Greyscale = 0,
    ///Allowed bit depths: 8 and 16.
    RGB = 2, 
    ///Allowed bit depths: 1, 2, 4 and 8.
    Palette = 3, 
    ///Allowed bit depths: 8 and 16.
    GreyscaleAlpha = 4, 
    ///Allowed bit depths: 8 and 16.
    RGBA = 6
}

///Number of color or alpha channels used by this color type.
uint num_channels(PNGColorType color_type){return [1, 0, 3, 1, 2, 0, 4][color_type];}

///PNG image description.
struct PNGImage
{
    ///Image width in pixels.
    uint width;
    ///Image height in pixels.
    uint height;
    ///Color format.
    PNGColorType color_type;
    ///Bits per color channel.
    ubyte bit_depth;
    ///Bits per pixel
    ubyte bpp;

    /**
     * Construct a PNGImage.
     *
     * Params:  width     = Image width in pixels.
     *          height    = Image height in pixels.
     *          bit_depth = Bits per color channel.
     *          type      = PNG color type.
     *
     * Returns: Constructed PNGImage.
     */
    this(in uint width, in uint height, in ubyte bit_depth, in PNGColorType type)
    {
        this.width = width;
        this.height = height;
        this.bit_depth = bit_depth;
        this.color_type = type;
        this.bpp = cast(ubyte)(bit_depth * num_channels(type));
    }
}

/**
 * PNG file description.
 *
 * Stores image information and auxiliary data such as text, background color,
 * palette, etc.
 */
struct PNGInfo
{
    invariant()
    {
        assert(palette.length <= 256, "Too many colors in a palette (over 256)");
        assert(background.length == 0 || //nothing
               background.length == 1 || //palette/gray
               background.length == 2 || //gray 16bit
               background.length == 3 || //RGB
               background.length == 6);  //RGB 16bit
    }

    public:
        ///Text stored inside PNG file.
        PNGText text;
        ///Is the PNG file interlaced?
        ubyte interlace;
        ///Palette of the image. Can be empty, can't have more than 256 colors.
        Color[] palette;

        ///Are we using transparent color key? Only applicable when there's no alpha or palette.
        bool color_key = false;
        ///Red channel of the color key (16bit). In grayscale, this is the color key.
        ushort color_key_r;
        ///Green channel of the color key (16bit).
        ushort color_key_g;
        ///Blue channel of the color key (16bit).
        ushort color_key_b;

        /**
         * Background color of the image. Can be empty.
         *
         * Interpretation depends on color type.
         *
         * Palette          - background[0] is background color. 
         * Grayscale 8-bit  - background[0] is background color.
         * Grayscale 16-bit - background[0 .. 1] is background color.
         * RGB 8-bit        - background[0 .. 3] is background color.
         * RGB 16-bit       - background[0 .. 6] is background color.
         * RGBA 8-bit       - background[0 .. 4] is background color.
         * RGBA 16-bit      - background[0 .. 8] is background color.
         */
        ubyte[] background;

    private:
        ///Image information.
        PNGImage image_;

    public:
        /**
         * Construct a PNGInfo.
         *
         * Params:  image = Image information.
         *
         * Returns: Constructed PNGInfo.
         */
        this(PNGImage image)
        {
            image_ = image;
        }

        ///Get (a copy of) image information.
        @property PNGImage image() const {return image_;}
}

///Dictionary of key-value text metadata in utf-8 and / or latin-1 encoding.
struct PNGText
{
    public:
        ///Latin-1 text data.
        immutable(ubyte)[][immutable(ubyte)[]] latin;
        ///Unicode text data.
        string[string] unicode;

        ///Is there no text?
        @property bool empty() const {return unicode.length + latin.length == 0;}
}

///Header.
immutable IHDR = get_uint(['I', 'H', 'D', 'R']);
///Image data.
immutable IDAT = get_uint(['I', 'D', 'A', 'T']);
///Palette.
immutable PLTE = get_uint(['P', 'L', 'T', 'E']);
///Transparency.
immutable tRNS = get_uint(['t', 'R', 'N', 'S']);
///Background color.
immutable bKGD = get_uint(['b', 'K', 'G', 'D']);
///End.
immutable IEND = get_uint(['I', 'E', 'N', 'D']);
///Latin-1 text.
immutable tEXt = get_uint(['t', 'E', 'X', 't']);
///Unicode (utf-8) text.
immutable iTXt = get_uint(['i', 'T', 'X', 't']);
///Compressed latin-1 text.
immutable zTXt = get_uint(['z', 'T', 'X', 't']);

/**
 * Determine if the specified color format is valid.
 *
 * Params:  type      = Color type.
 *          bit_depth = Bits per channel.
 *   
 * Returns: True if the color format is valid, false otherwise.
 */
bool validate_color(in PNGColorType color_type, in uint bit_depth)
{
    const int bd = bit_depth;
    final switch(color_type)
    {
        case PNGColorType.Greyscale: 
            return [1, 2, 4, 8, 16].canFind(bd);
        case PNGColorType.Palette: 
            return [1, 2, 4, 8].canFind(bd);
        case PNGColorType.RGB, PNGColorType.RGBA, PNGColorType.GreyscaleAlpha: 
            return [8, 16].canFind(bd);
    }
}

/**
 * Paeth predictor, used by the Paeth PNG filter.
 *
 * Params:  a = Pixel to the left of the current pixel.
 *          b = Pixel above the current pixel.
 *          c = Pixel to the left of pixel b.
 */
int paeth_predictor(in int a, in int b, in int c) pure
{
    const int p = a + b - c;

    const int pa = p > a ? p - a : a - p;
    const int pb = p > b ? p - b : b - p;
    const int pc = p > c ? p - c : c - p;

    if(pa <= pb && pa <= pc){return a;}
    else if(pb <= pc){return b;}
    return c;
}

///Chunk of a PNG file.
struct PNGChunk
{
    ///Chunk type.
    uint type;
    ///Raw chunk contents.
    const(ubyte)[] data;

    /**
     * Construct a chunk from a byte stream (probably loaded from a file).
     *
     * Params:  stream = Stream to read from.
     *
     * Returns: Constructed chunk.
     */
    static PNGChunk from_stream(in ubyte[] stream)
    in{assert(stream.length >= chunk_min_size, "Chunk too small");}
    body
    {
        PNGChunk result;
        //length of chunk data
        const uint data_length = get_uint(stream);
        //chunk type
        result.type = get_uint(stream[4 .. 8]);
        result.data = data_length ? stream[8 .. 8 + data_length] : null;
        //crc at the end of the chunk
        const uint crc = get_uint(stream[8 + data_length .. 12 + data_length]);
        enforceEx!PNGException(zlib_check_crc(crc, stream[4..8 + data_length]),
                               "CRC does not match, probably corrupted file");
        return result;
    }

    ///Chunk comparison for ordering chunks to write to file.
    int opCmp(PNGChunk other)
    {
        switch(type)
        {
            case IHDR: return -1;
            case PLTE: return (other.type == bKGD || other.type == tRNS) ? -1 : 1;
            case IEND: return 1;
            case IDAT: return other.type == IEND ? -1 : 1;
            case bKGD, tRNS: return other.type == IDAT ? -1 : 1;
            //not ordering unknown chunks
            default: return 0;
        }
    }

    ///Get length of the chunk in bytes.
    @property size_t length() const {return data.length + chunk_min_size;}
}

///Minimum chunk size, taken up by chunk length, type and crc uints.
immutable uint chunk_min_size = 12;

/**
 * Get an uint from the first 4 bytes of source buffer. 
 *
 * Params:  source = Buffer to read.
 *          
 * Returns: uint from the buffer. 
 */
uint get_uint(in ubyte[] source) pure
in{assert(source.length >= 4, "Can't get an uint from a buffer smaller than 4 bytes");}
body{return source[0] << 24 | source[1] << 16 | source[2] << 8 | source[3];}
