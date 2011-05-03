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


module formats.pngencoder;
@system


import std.c.string;

import std.math;

import formats.zlib;
import formats.pngcommon;
import memory.memory;
import containers.vector;


package:
///Encodes image data to PNG format.
struct PNGEncoder
{
    invariant(){assert(level_ >= 0 && level_ <= 9, "invalid zlib compression level");}

    private:
        ///Zlib compression level. Must be between 0 and 9.
        ubyte level_ = 6;
        ///Zlib compression strategy.
        CompressionStrategy compression_ = CompressionStrategy.RLE;
        ///PNG filter strategy.
        PNGFilter filter_ = PNGFilter.Dynamic;
        ///Compress text data?
        bool compress_text_ = true;

        ///Filtering functions.
        auto filters_ = [&none, &sub, &up, &average, &paeth];

    public:
        ///Set compression level. Can't be greater than 9.
        @property void level(in ubyte level){level_ = level;}

        ///Set Zlib compression strategy.
        @property void compression(in CompressionStrategy compression)
        {
            compression_ = compression;
        }

        ///Set PNG filter strategy.
        @property void filter(in PNGFilter filter){filter_ = filter;}

        ///Compress text data? (on by default)
        @property void compress_text(in bool compress){compress_text_ = compress;}

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
        ubyte[] encode(in PNGInfo info, in ubyte[] source)
        in
        {
            assert(info.image.color_type == PNGColorType.RGB || info.image.color_type == PNGColorType.RGBA,
                   "Unsupported color type for PNG encoding");
            assert(info.image.bit_depth == 8, "Unsupported channel bit depth for PNG encoding");
        }
        body
        {
            PNGChunk[] chunks;
            //header chunk
            chunks ~= PNGChunk(IHDR, header(info.image));
            //filter image data
            auto filtered = Vector!(ubyte)(8);
            filter_data(filtered, source, info.image);
            //compress image data
            auto compressed = Vector!(ubyte)(8);
            zlib_deflate(compressed, filtered.array, compression_, level_);
            chunks ~= PNGChunk(IDAT, compressed.array_unsafe);
            //auxiliary chunks from PNGInfo.
            chunks ~= auxiliary_chunks(info);
            chunks.sort;
            chunks ~= PNGChunk(IEND, []);

            auto buffer = Vector!(ubyte)(png_magic_number);
            //write chunks to buffer
            foreach(chunk; chunks){write_chunk(buffer, chunk);}

            ubyte[] output = alloc_array!(ubyte)(buffer.length);
            output[] = buffer.array;

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
        PNGChunk[] auxiliary_chunks(const ref PNGInfo info) const
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
            if(info.color_key)
            {
                chunks ~= PNGChunk(tRNS, [cast(ubyte)(info.color_key_r / 256), 
                                          cast(ubyte)(info.color_key_r % 256), 
                                          cast(ubyte)(info.color_key_g / 256), 
                                          cast(ubyte)(info.color_key_g % 256), 
                                          cast(ubyte)(info.color_key_b / 256), 
                                          cast(ubyte)(info.color_key_b % 256)]);
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
            if (!info.text.empty()){chunks ~= chunkify_text(info.text);}

            return chunks;
        }

        /**
         * Create and return text data chunks.
         *
         * Params:  info = PNG info to get text data from.
         *
         * Returns: Text data chunks.
         */
        PNGChunk[] chunkify_text(const ref PNGText text) const
        {
            PNGChunk[] result;
            //latin
            foreach(immutable(ubyte)[] keyword, const immutable(ubyte)[] value; text.latin)
            {
                result ~= PNGChunk(zTXt, keyword ~ 
                                   (compress_text_ ? cast(ubyte[])[0, 0] ~ zlib_deflate(value)
                                                   : cast(ubyte[])[0] ~ value));
            }
            //unicode
            foreach(string keyword, const string value; text.unicode)
            {
                result ~= PNGChunk(iTXt, cast(ubyte[])keyword ~ 
                                   (compress_text_ ? cast(ubyte[])[0, 1, 0, 0, 0]
                                                     ~ zlib_deflate(cast(ubyte[])value)
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
        void filter_data(ref Vector!(ubyte) buffer, in ubyte[] source, in PNGImage image)
        {
            const uint pixel_bytes = (image.bpp + 7) / 8;
            //size of a line in bytes
            const uint pitch = image.width * pixel_bytes;

            //current and previous line
            const(ubyte)[] line;
            const(ubyte)[] previous;
            line = source[0 .. pitch];

            //line of zeroes used as previous line when we're filtering first line
            ubyte[] zero_line = new ubyte[pitch];
            zero_line[] = cast(ubyte)0;

            //filtered line is written here
            auto filtered = Vector!(ubyte)(8);

            //filter each line separately to get best results
            if(filter_ == PNGFilter.Dynamic)
            {
                filtered.length = pitch;
                for(uint y = 0; y < image.height; y++)
                {
                    ulong smallest = ulong.max;
                    PNGFilter best_filter;

                    line = source[pitch * y .. pitch * (y + 1)];
                    //if we're at the first line, the line above us is the zero line
                    previous = y == 0 ? zero_line : source[pitch * (y - 1) .. pitch * y];

                    //get the smallest filtered result
                    for(auto f = PNGFilter.None; f < PNGFilter.Dynamic; f++)
                    {
                        //filtered line
                        filter_line(filtered, previous, line, filters_[f], pixel_bytes);

                        //absolute sum of the filtered line
                        uint sum = 0;
                        foreach(value; filtered){sum += abs(cast(int)(cast(byte)value));}

                        if(sum < smallest)
                        {
                            smallest = sum; 
                            best_filter = f;
                        }
                    }

                    buffer ~= cast(ubyte)best_filter;
                    filter_line(filtered, previous, line, filters_[best_filter], pixel_bytes);
                    buffer ~= filtered.array;
                }
            }
            //one filter for the whole image
            else
            {
                for(uint y = 0; y < image.height; y++)
                {
                    line = source[pitch * y .. pitch * (y + 1)];
                    //if we're at the first line, the line above us is the zero line
                    previous = y == 0 ? zero_line : source[pitch * (y - 1) .. pitch * y];

                    buffer ~= cast(ubyte)filter_;
                    filter_line(filtered, previous, line, filters_[filter_], pixel_bytes);
                    buffer ~= filtered.array;
                }
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
ubyte[] header(in PNGImage image)
{
    ubyte[] header = new ubyte[13];
    header.length = 0;

    add_uint(header, image.width);
    add_uint(header, image.height);
    header ~= image.bit_depth;
    header ~= image.color_type;
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
void write_chunk(ref Vector!(ubyte) buffer, const ref PNGChunk chunk)
{
    //chunk header
    add_uint(buffer, cast(uint)chunk.data.length);
    add_uint(buffer, chunk.type);

    //chunk data
    buffer ~= chunk.data;
    auto l = buffer.length;

    //crc
    add_uint(buffer, zlib_crc(buffer[l - chunk.data.length - 4 .. l]));
}

/**
 * Append a uint to specified ubyte buffer (vector or array).
 *
 * Params:  buffer = Buffer to append to.
 *          i      = uint to append.
 */
void add_uint(T)(ref T buffer, in uint i)
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
 * Params:  result      = Filtered line will be written here.
 *          previous    = Previous line in the image. 
 *                        Should be a line of zeroes if this is the first line.
 *          line        = Current line in the image.
 *          filter      = Filter function to use.
 *          pixel_bytes = Size of a pixel in bytes.
 */
void filter_line(ref Vector!(ubyte) result, const(ubyte)[] previous, const(ubyte)[] line, 
                 ubyte function(in ubyte, in ubyte, in ubyte, in ubyte) pure filter, 
                 in uint pixel_bytes)
in{assert(previous.length == line.length, "Image line lengths don't match");}
body
{
    uint b = pixel_bytes;
    //first pixel has nothing before it
    while(b--){result[b] = filter(0, previous[b], 0, line[b]);}
    for(uint i = pixel_bytes; i < result.length; i++)
    {
        result[i] = filter(previous[i - pixel_bytes], previous[i], 
                           line[i - pixel_bytes], line[i]);
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
ubyte none(in ubyte c, in ubyte b, in ubyte a, in ubyte x) pure 
{
    return x;
}
ubyte sub(in ubyte c, in ubyte b, in ubyte a, in ubyte x) pure 
{
    return cast(ubyte)(x - a);
}
ubyte up(in ubyte c, in ubyte b, in ubyte a, in ubyte x) pure 
{
    return cast(ubyte)(x - b);
}
ubyte average(in ubyte c, in ubyte b, in ubyte a, in ubyte x) pure 
{
    return cast(ubyte)(x - (a + b) / 2);
}
ubyte paeth(in ubyte c, in ubyte b, in ubyte a, in ubyte x) pure 
{
    return cast(ubyte)(x - paeth_predictor(a,b,c));
}
