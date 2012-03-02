/***************************************************************************************************
License:
Copyright (c) 2005-2007 Lode Vandevenne
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.<br>
  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.<br>
  - Neither the name of Lode Vandevenne nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.<br>

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Lode Vandevenne (original version in C++), Lutger Blijdestijn (D version) : lutger dot blijdestijn at gmail dot com, Ferdinand Majerech (Refactoring)
*/


///PNG encoder.
module formats.pngencoder;


import core.stdc.string;

import std.math;

import formats.zlib;
import formats.pngcommon;
import memory.memory;
import containers.vector;


package:
///Encodes image data to PNG format.
struct PNGEncoder
{
    private:
        ///Zlib compression level. Must be between 0 and 9.
        ubyte level_ = 6;
        ///Zlib compression strategy.
        CompressionStrategy compression_ = CompressionStrategy.RLE;
        ///PNG filter strategy.
        PNGFilter filter_ = PNGFilter.Dynamic;
        ///Compress text data?
        bool compressText_ = true;

        ///Filtering functions.
        auto filters_ = [&none, &sub, &up, &average, &paeth];

    public:
        ///Set compression level. Can't be greater than 9.
        @property void level(const ubyte level){level_ = level;}

        ///Set Zlib compression strategy.
        @property void compression(const CompressionStrategy compression)
        {
            compression_ = compression;
        }

        ///Set PNG filter strategy.
        @property void filter(const PNGFilter filter){filter_ = filter;}

        ///Compress text data? (on by default)
        @property void compressText(const bool compress){compressText_ = compress;}

        /**
         * Encode image data to PNG format.
         *
         * Only 24bit RGB and 32bit RGBA formats are supported at the moment.
         *
         * Params:  info   = PNG information to encode.
         *          source = Image data to encode. 
         *                   Must correspond to width, height and color type in info.
         *
         * Returns: Manually allocated array with encoded PNG data. Must be manually freed.
         *
         * Throws:  PNGException on failure.
         */
        ubyte[] encode(const PNGInfo info, const ubyte[] source)
        in
        {
            assert(info.image.colorType == PNGColorType.RGB || info.image.colorType == PNGColorType.RGBA,
                   "Unsupported color type for PNG encoding");
            assert(info.image.bitDepth == 8, "Unsupported channel bit depth for PNG encoding");
        }
        body
        {
            PNGChunk[] chunks;
            //header chunk
            chunks ~= PNGChunk(IHDR, header(info.image));
            //filter image data
            Vector!ubyte filtered, compressed;
            filtered.reserve(8);
            filterData(filtered, source, info.image);
            //compress image data
            compressed.reserve(8);
            zlibDeflate(compressed, filtered[], compression_, level_);
            chunks ~= PNGChunk(IDAT, compressed.ptrUnsafe[0 .. compressed.length]);
            //auxiliary chunks from PNGInfo.
            chunks ~= auxiliaryChunks(info);
            chunks.sort;
            chunks ~= PNGChunk(IEND, []);

            auto buffer = Vector!ubyte(pngMagicNumber.dup);
            //write chunks to buffer
            foreach(chunk; chunks){writeChunk(buffer, chunk);}

            ubyte[] output = allocArray!ubyte(cast(uint)buffer.length);
            output[] = buffer[];

            return output;
        }

    private:
        /**
         * Create and return chunks containing auxiliary PNG data.
         *
         * Only color key, background color and text chunks are supported at the moment.
         *
         * Params:  info = PNG info to get data from.
         *
         * Returns: Auxiliary data chunks.
         */
        PNGChunk[] auxiliaryChunks(const ref PNGInfo info) const
        in
        {
            auto length = info.background.length;
            assert(length == 0 || length == 3 || length == 6, 
                   "Unsupported background color format for encoding");
        }
        body
        {
            PNGChunk[] chunks;

            //color key (transparent color) chunk
            if(info.colorKey)
            {
                chunks ~= PNGChunk(tRNS, [cast(ubyte)(info.colorKeyR / 256), 
                                          cast(ubyte)(info.colorKeyR % 256), 
                                          cast(ubyte)(info.colorKeyG / 256), 
                                          cast(ubyte)(info.colorKeyG % 256), 
                                          cast(ubyte)(info.colorKeyB / 256), 
                                          cast(ubyte)(info.colorKeyB % 256)]);
            }

            //background color chunk
            if(info.background.length == 3)
            {
                chunks ~= PNGChunk(bKGD, [0, info.background[0], 
                                          0, info.background[1], 
                                          0, info.background[2]]);
            }
            else if(info.background.length == 6)
            {
                chunks ~= PNGChunk(bKGD, info.background.dup);
            }

            //text chunks
            if(!info.text.empty()){chunks ~= chunkifyText(info.text);}

            return chunks;
        }

        /**
         * Create and return text data chunks.
         *
         * Params:  info = PNG info to get text data from.
         *
         * Returns: Text data chunks.
         */
        PNGChunk[] chunkifyText(const ref PNGText text) const
        {
            PNGChunk[] result;
            //latin
            foreach(immutable(ubyte)[] keyword, const immutable(ubyte)[] value; text.latin)
            {
                result ~= PNGChunk(zTXt, keyword ~ 
                                   (compressText_ ? cast(ubyte[])[0, 0] ~ zlibDeflate(value)
                                                  : cast(ubyte[])[0] ~ value));
            }
            //unicode
            foreach(string keyword, const string value; text.unicode)
            {
                result ~= PNGChunk(iTXt, cast(ubyte[])keyword ~ 
                                   (compressText_ ? cast(ubyte[])[0, 1, 0, 0, 0]
                                                     ~ zlibDeflate(cast(ubyte[])value)
                                                  : cast(ubyte[])[0, 0, 0, 0, 0]
                                                    ~ cast(ubyte[])value));
            }
            return result;
        }

        /**
         * Filter the image data before compression.
         *
         * Params:  buffer = Output buffer.
         *          source = Data to filter.
         *          image  = Image information.
         */
        void filterData(ref Vector!ubyte buffer, const ubyte[] source, const PNGImage image)
        {
            const uint pixelBytes = (image.bpp + 7) / 8;
            //size of a line in bytes
            const uint pitch = image.width * pixelBytes;

            //current and previous line
            const(ubyte)[] line;
            const(ubyte)[] previous;
            line = source[0 .. pitch];

            //line of zeroes used as previous line when we're filtering first line
            ubyte[] zeroLine = new ubyte[pitch];
            zeroLine[] = cast(ubyte)0;

            //filtered line is written here
            Vector!ubyte filtered;
            filtered.reserve(8);

            //filter each line separately to get best results
            if(filter_ == PNGFilter.Dynamic)
            {
                filtered.length = pitch;
                foreach(y; 0 .. image.height)
                {
                    ulong smallest = ulong.max;
                    PNGFilter bestFilter;

                    line = source[pitch * y .. pitch * (y + 1)];
                    //if we're at the first line, the line above us is the zero line
                    previous = y == 0 ? zeroLine : source[pitch * (y - 1) .. pitch * y];

                    //get the smallest filtered result
                    for(auto f = PNGFilter.None; f < PNGFilter.Dynamic; f++)
                    {
                        //filtered line
                        filterLine(filtered, previous, line, filters_[f], pixelBytes);

                        //absolute sum of the filtered line
                        uint sum = 0;
                        foreach(value; filtered){sum += abs(cast(int)(cast(byte)value));}

                        if(sum < smallest)
                        {
                            smallest = sum; 
                            bestFilter = f;
                        }
                    }

                    buffer ~= cast(ubyte)bestFilter;
                    filterLine(filtered, previous, line, filters_[bestFilter], pixelBytes);
                    buffer ~= filtered;
                }
            }
            //one filter for the whole image
            else foreach(y; 0 .. image.height)
            {
                line = source[pitch * y .. pitch * (y + 1)];
                //if we're at the first line, the line above us is the zero line
                previous = y == 0 ? zeroLine : source[pitch * (y - 1) .. pitch * y];

                buffer ~= cast(ubyte)filter_;
                filterLine(filtered, previous, line, filters_[filter_], pixelBytes);
                buffer ~= filtered;
            }
        }
}

private:
/**
 * Create header chunk contents.
 *
 * Params:  image = Image to get data from.
 *
 * Returns: Header chunk data.
 */
ubyte[] header(const PNGImage image)
{
    ubyte[] header = new ubyte[13];
    header.length = 0;

    addUint(header, image.width);
    addUint(header, image.height);
    header ~= image.bitDepth;
    header ~= image.colorType;
    //compression method
    header ~= 0; 
    //filter method
    header ~= 0; 
    //interlace method
    header ~= 0; 

    return header;
}

/**
 * Write a chunk to a buffer.
 *
 * Params:  buffer = Buffer to write to.
 *          chunk  = PNGChunk to write.
 */
void writeChunk(ref Vector!ubyte buffer, ref PNGChunk chunk)
{
    //chunk header
    addUint(buffer, cast(uint)chunk.data.length);
    addUint(buffer, chunk.type);

    //chunk data
    buffer ~= chunk.data;
    auto l = buffer.length;

    //crc
    addUint(buffer, zlibCRC(buffer[l - chunk.data.length - 4 .. l]));
}

/**
 * Append a uint to specified ubyte buffer (vector or array).
 *
 * Params:  buffer = Buffer to append to.
 *          i      = uint to append.
 */
void addUint(T)(ref T buffer, const uint i)
{
    buffer.length = buffer.length + 4;
    const l = buffer.length;
    buffer[l - 4] = cast(ubyte)(i >> 24);
    buffer[l - 3] = cast(ubyte)(i >> 16);
    buffer[l - 2] = cast(ubyte)(i >> 8);
    buffer[l - 1] = cast(ubyte)(i);
}

/**  
 * Filter a line of image data.
 *
 * Params:  result     = Filtered line will be written here.
 *          previous   = Previous line in the image. 
 *                       Should be a line of zeroes if this is the first line.
 *          line       = Current line in the image.
 *          filter     = Filter function to use.
 *          pixelBytes = Size of a pixel in bytes.
 */
void filterLine(ref Vector!ubyte result, const(ubyte)[] previous, const(ubyte)[] line, 
                ubyte function(const ubyte, const ubyte, const ubyte, const ubyte) pure filter, 
                const uint pixelBytes)
in{assert(previous.length == line.length, "Image line lengths don't match");}
body
{
    uint b = pixelBytes;
    //first pixel has nothing before it
    while(b--){result[b] = filter(0, previous[b], 0, line[b]);}
    foreach(i; pixelBytes .. result.length)
    {
        result[i] = filter(previous[i - pixelBytes], previous[i], 
                           line[i - pixelBytes], line[i]);
    }
}

/**
 * From the png spec: pixels for filtering are defined as follows such, where x is the current
 * being filtered and c, b correspond to the previous scanline:
 *     c b
 *     a x
 *
 * filter      construction                                                    Reconstruction
 * 0  None     Filt(x) = Orig(x)                                               Recon(x) = Filt(x)
 * 1  Sub      Filt(x) = Orig(x) - Orig(a)                                     Recon(x) = Filt(x) + Recon(a)
 * 2  Up       Filt(x) = Orig(x) - Orig(b)                                     Recon(x) = Filt(x) + Recon(b)
 * 3  Average  Filt(x) = Orig(x) - floor((Orig(a) + Orig(b)) / 2)              Recon(x) = Filt(x) + floor((Recon(a) + Recon(b)) / 2)
 * 4  Paeth    Filt(x) = Orig(x) - PaethPredictor(Orig(a), Orig(b), Orig(c))   Recon(x) = Filt(x) + PaethPredictor(Recon(a), Recon(b), Recon(c)
 */
ubyte none(const ubyte c, const ubyte b, const ubyte a, const ubyte x) pure 
{
    return x;
}
ubyte sub(const ubyte c, const ubyte b, const ubyte a, const ubyte x) pure 
{
    return cast(ubyte)(x - a);
}
ubyte up(const ubyte c, const ubyte b, const ubyte a, const ubyte x) pure 
{
    return cast(ubyte)(x - b);
}
ubyte average(const ubyte c, const ubyte b, const ubyte a, const ubyte x) pure 
{
    return cast(ubyte)(x - (a + b) / 2);
}
ubyte paeth(const ubyte c, const ubyte b, const ubyte a, const ubyte x) pure 
{
    return cast(ubyte)(x - paethPredictor(a,b,c));
}
