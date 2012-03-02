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


import std.algorithm;
import std.exception;

import formats.zlib;
import color;


package:
///Magic number at the start of a PNG file.
immutable ubyte[] pngMagicNumber = [137, 80, 78, 71, 13, 10, 26, 10];

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
uint numChannels(const PNGColorType colorType) pure {return [1, 0, 3, 1, 2, 0, 4][colorType];}

///PNG image description.
struct PNGImage
{
    ///Image width in pixels.
    uint width;
    ///Image height in pixels.
    uint height;
    ///Color format.
    PNGColorType colorType;
    ///Bits per color channel.
    ubyte bitDepth;
    ///Bits per pixel
    ubyte bpp;

    /**
     * Construct a PNGImage.
     *
     * Params:  width     = Image width in pixels.
     *          height    = Image height in pixels.
     *          bitDepth = Bits per color channel.
     *          type      = PNG color type.
     *
     * Returns: Constructed PNGImage.
     */
    this(const uint width, const uint height, 
         const ubyte bitDepth, const PNGColorType type) pure
    {
        this.width = width;
        this.height = height;
        this.bitDepth = bitDepth;
        this.colorType = type;
        this.bpp = cast(ubyte)(bitDepth * numChannels(type));
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
    public:
        ///Text stored inside PNG file.
        PNGText text;
        ///Is the PNG file interlaced?
        ubyte interlace;
        ///Palette of the image. Can be empty, can't have more than 256 colors.
        Color[] palette;

        ///Are we using transparent color key? Only applicable when there's no alpha or palette.
        bool colorKey = false;
        ///Red channel of the color key (16bit). In grayscale, this is the color key.
        ushort colorKeyR;
        ///Green channel of the color key (16bit).
        ushort colorKeyG;
        ///Blue channel of the color key (16bit).
        ushort colorKeyB;

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
        this(PNGImage image) pure
        {
            image_ = image;
        }

        ///Get (a copy of) image information.
        @property PNGImage image() const pure {return image_;}
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
immutable IHDR = getUint(['I', 'H', 'D', 'R']);
///Image data.
immutable IDAT = getUint(['I', 'D', 'A', 'T']);
///Palette.
immutable PLTE = getUint(['P', 'L', 'T', 'E']);
///Transparency.
immutable tRNS = getUint(['t', 'R', 'N', 'S']);
///Background color.
immutable bKGD = getUint(['b', 'K', 'G', 'D']);
///End.
immutable IEND = getUint(['I', 'E', 'N', 'D']);
///Latin-1 text.
immutable tEXt = getUint(['t', 'E', 'X', 't']);
///Unicode (utf-8) text.
immutable iTXt = getUint(['i', 'T', 'X', 't']);
///Compressed latin-1 text.
immutable zTXt = getUint(['z', 'T', 'X', 't']);

/**
 * Determine if the specified color format is valid.
 *
 * Params:  type      = Color type.
 *          bitDepth = Bits per channel.
 *   
 * Returns: True if the color format is valid, false otherwise.
 */
bool validateColor(const PNGColorType colorType, const uint bitDepth) pure
{
    const int bd = bitDepth;
    final switch(colorType)
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
int paethPredictor(const int a, const int b, const int c) pure
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
    static PNGChunk fromStream(const ubyte[] stream)
    in{assert(stream.length >= chunkMinSize, "Chunk too small");}
    body
    {
        PNGChunk result;
        //length of chunk data
        const uint dataLength = getUint(stream);
        //chunk type
        result.type = getUint(stream[4 .. 8]);
        result.data = dataLength ? stream[8 .. 8 + dataLength] : null;
        //crc at the end of the chunk
        const uint crc = getUint(stream[8 + dataLength .. 12 + dataLength]);
        enforceEx!PNGException(zlibCheckCRC(crc, stream[4..8 + dataLength]),
                               "CRC does not match, probably corrupted file");
        return result;
    }

    ///Chunk comparison for ordering chunks to write to file.
    int opCmp(PNGChunk other) pure
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
    @property size_t length() const pure {return data.length + chunkMinSize;}
}

///Minimum chunk size, taken up by chunk length, type and crc uints.
immutable uint chunkMinSize = 12;

/**
 * Get an uint from the first 4 bytes of source buffer. 
 *
 * Params:  source = Buffer to read.
 *          
 * Returns: uint from the buffer. 
 */
uint getUint(const ubyte[] source) pure
in{assert(source.length >= 4, "Can't get an uint from a buffer smaller than 4 bytes");}
body{return source[0] << 24 | source[1] << 16 | source[2] << 8 | source[3];}
