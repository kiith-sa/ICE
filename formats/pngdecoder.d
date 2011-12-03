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


///PNG decoder.
module formats.pngdecoder;
@system


import std.algorithm;
import std.exception;
import std.intrinsic;
import std.string;

import formats.pngcommon;
import formats.zlib;
import math.vector2;
import memory.memory;
import containers.vector;
import color;


package:
/**
 * PNG file decoder. Supports all color types, interlacing, color key, background color, 
 * text. However, color types with less than 8 bytes per pixels are not tested at the 
 * moment and might not work.
 */
struct PNGDecoder
{
    public:
        /**
         * Decode PNG file data.
         *
         * Params:  source = PNG data to decode.
         *          info   = PNG info object to write image information to.
         *
         * Returns: Manually allocated decoded image data. Must be freed manually.
         *
         * Throws:  PNGException on decoding error.
         *          CompressionException on PNG data decompression error.
         */
        ubyte[] decode(in ubyte[] source, out PNGInfo info)
        {
            ubyte interlace;
            info = PNGInfo(read_header(source, interlace));
            info.interlace = interlace;

            const expected_length = info.interlace 
                                    ? buffer_size(info.image) + info.image.height * 2
                                    : buffer_size(info.image) + info.image.height;


            Vector!ubyte buffer;
            buffer.reserve(expected_length);

            auto inflator = Inflator(buffer);

            foreach(chunk; new PNGChunkIterator(source[header_size - 1 .. $]))
            {
                switch(chunk.type)
                {
                    //image data
                    case IDAT:
                        inflator.inflate(chunk.data);
                        break;
                    //palette
                    case PLTE:
                        enforceEx!PNGException(chunk.data.length <= 256 * 3, 
                                               "Palette with over 256 colors");
                        info.palette.length = chunk.data.length / 3;
                        uint byte_idx = 0;
                        foreach(ref color; info.palette)
                        {
                            color = Color(chunk.data[byte_idx++],
                                          chunk.data[byte_idx++], 
                                          chunk.data[byte_idx++],
                                          255);
                        }
                        break;
                    //color key or palette transparency
                    case tRNS:
                        if(chunk.data.length == 0){break;}
                        info.color_key = true;
                        if(info.image.color_type == PNGColorType.Palette)
                        {
                            enforceEx!PNGException(chunk.data.length <= info.palette.length, 
                                                   "Palette too large");
                            foreach(index, alpha; chunk.data){info.palette[index].a = alpha;}
                        }
                        else if(info.image.color_type == PNGColorType.RGB)
                        {
                            info.color_key_r = cast(ushort)(256U * chunk.data[0] + chunk.data[1]);
                            info.color_key_g = cast(ushort)(256U * chunk.data[2] + chunk.data[3]);
                            info.color_key_b = cast(ushort)(256U * chunk.data[4] + chunk.data[5]);
                        }
                        else if(info.image.color_type == PNGColorType.Greyscale)
                        {
                            info.color_key_r = cast(ushort)(256U * chunk.data[0] + chunk.data[1]);
                        }
                        else{assert(false, "Transparency chunk not supported for this format");}
                        break;
                    //background color
                    case bKGD:
                        if(info.image.color_type == PNGColorType.Palette || 
                           info.image.bit_depth == 16)
                        {
                            info.background = chunk.data.dup;
                        }
                        else
                        {
                            info.background.length = chunk.data.length / 2;
                            foreach(index, ref value; info.background)
                            {
                                value = chunk.data[index * 2];
                            }
                        }
                        break;
                    //compressed text
                    case zTXt:
                        auto sep = countUntil(chunk.data, 0);
                        if(sep > 0)
                        {
                            if(chunk.data[sep + 1] == 0)
                            {
                                info.text.latin[cast(immutable ubyte[])
                                                chunk.data[0 .. sep]] = 
                                                cast(immutable ubyte[])
                                                chunk.data[sep + 2 .. $];
                            }
                            else
                            {
                                info.text.latin[cast(immutable ubyte[])
                                                chunk.data[0 .. sep]] = 
                                                cast(immutable ubyte[]) 
                                                zlib_inflate(chunk.data[sep + 2 .. $]);
                            }
                        }
                        break;
                    //text
                    case tEXt:
                        auto sep = countUntil(chunk.data, 0);
                        if(sep > 0)
                        {
                            info.text.latin[cast(immutable ubyte[])
                                            chunk.data[0 .. sep]] = 
                                            cast(immutable ubyte[]) 
                                            chunk.data[sep + 1 .. $];
                        }
                        break;
                    //utf-8 text
                    case iTXt:
                        auto sep = countUntil(chunk.data, 0);
                        const keyword = cast(string)chunk.data[0 .. sep];
                        const compressed = cast(bool)chunk.data[sep + 1];
                        sep += countUntil(chunk.data[sep + 3 .. $], 0) + 3;
                        sep += countUntil(chunk.data[sep + 1 .. $], 0) + 1;
                        if(!compressed)
                        {
                            info.text.unicode[keyword] = cast(string)chunk.data[sep + 1 .. $];
                        }
                        else
                        {
                            info.text.unicode[keyword] = 
                                             cast(string)zlib_inflate(chunk.data[sep + 1 .. $]);
                        }
                        break;
                    default:
                        size_t type = chunk.type;
                        enforceEx!PNGException((bt(&type, cast(size_t)6) < 0), 
                                  "Unrecognized critical chunk");
                        break;
                }
            }

            if(info.interlace != 0){deinterlace(buffer, info.image);}
            else{reconstruct(buffer, info.image);}

            ubyte[] output = alloc_array!(ubyte)(cast(uint)buffer.length);
            output[] = buffer[];

            return output;
        }
}

private:
///Size of a PNG header.
immutable uint header_size = 34;

/**
 * Parse a PNG header.
 *
 * Params:  source    = PNG data buffer.
 *          interlace = PNG interlacing method will be written here.
 *
 * Returns: PNGImage with header information.
 *
 * Throws:  PNGException if the header is invalid.
 */
PNGImage read_header(in ubyte[] source, out ubyte interlace)
{
    //spec: http://www.w3.org/TR/PNG/#11IHDR

    enforceEx!PNGException(source.length >= header_size, "PNG header too small");
    enforceEx!PNGException(source[0 .. 8] == png_magic_number, 
                           "Invalid PNG header (PNG magic number does not match)");
    enforceEx!PNGException(get_uint(source[12 .. 16]) == IHDR, 
                           "Invalid PNG header (Header name does not match)");
    enforceEx!PNGException(zlib_check_crc(get_uint(source[29 .. 33]), source[12 .. 29]), 
                           "Invalid PNG CRC (file might be corrupted?)");

    const uint width      = get_uint(source[16 .. 20]);
    const uint height     = get_uint(source[20 .. 24]);
    const ubyte bit_depth = source[24];
    const color_type = cast(PNGColorType) source[25];
    enforceEx!PNGException(source[26] == 0, 
                           "Unsupported compression method in PNG header");
    enforceEx!PNGException(source[27] == 0, 
                           "Unsupported filter method in PNG header");
    enforceEx!PNGException(validate_color(color_type, bit_depth), 
                           "Invalid color format in PNG header");
    interlace = source[28];
    enforceEx!PNGException(interlace < 2, 
                           "Invalid  interlace method in PNG header");
    const ubyte bpp = cast(ubyte)(num_channels(color_type) * bit_depth);
    return PNGImage(width, height, bit_depth, color_type);
}

/**
 * Estimate buffer size needed for decoding an image with specified parameters.
 *
 * Params:  image = Image to estimate buffer size for.
 *
 * Returns: Estimated buffer size. Not exact.
 */
uint buffer_size(in PNGImage image) pure
{
    return ((image.width * image.bpp + 7) / 8) * image.height;
}

///Iterator over PNG chunks. 
class PNGChunkIterator
{
    private:
        ///PNG data stream (without header).
        const ubyte[] stream_;

    public:
        ///Construct a PNGChunkIterator over specified stream (without header).
        this(in ubyte[] stream){stream_ = stream;}

        ///Iterate over chunks. Chunks will be destroyed after their respective iterations.
        int opApply(int delegate(ref PNGChunk chunk) visitor)
        {
            int result = 0;
            uint pos = 0;
            while(pos + chunk_min_size <= stream_.length)
            {
                PNGChunk chunk = PNGChunk.from_stream(stream_[pos .. $]);
                if(chunk.type == IEND){break;}
                result = visitor(chunk);
                if(result){return result;}
                pos += chunk.length;
            }
            return result;
        }
}

/**
 * Unapply a filter on a line of image data.
 *
 * Params:  result      = Filtered result will be written here.
 *          line        = Current line in the image. Must not overlap with result.
 *          previous    = Previous, already filtered, line in the image. 
 *                        Must not overlap with result.
 *          pixel_bytes = Pixel size in bytes (1 if actual pixel size is below 1 byte).
 *          filter      = Filter to unapply.
 */
void unfilter_line(ubyte[] result, in ubyte[] line, in ubyte[] previous, 
                   uint pixel_bytes, in PNGFilter filter)
{
    switch(filter)
    {
        case PNGFilter.Paeth:
            result[0 .. line.length] = line;
            //first pixel
            result[0 .. pixel_bytes] += previous[0 .. pixel_bytes];

            //i is current pixel in this and previous line
            //o is previous pixel in this and previous line
            for(uint i = pixel_bytes, o = 0; i < line.length; i++, o++)
            {
                result[i] += paeth_predictor(result[o], previous[i], previous[o]);
            }
            break;
        case PNGFilter.Average:
            result[0 .. line.length] = line[];
            //first pixel
            foreach(i; 0 .. pixel_bytes){result[i] += previous[i] / 2;}
            //rest of the line
            foreach(i; pixel_bytes .. line.length)
            {
                result[i] += (result[i - pixel_bytes] + previous[i]) / 2;
            }
            break;
        case PNGFilter.Up:
            result[0 .. line.length] = line[] + previous[];
            break;
        case PNGFilter.Sub:
            //first pixel
            result[0 .. pixel_bytes] = line[0 .. pixel_bytes];
            //rest of the line
            foreach(i; pixel_bytes .. line.length)
            {
                result[i] = cast(ubyte)(line[i] + result[i - pixel_bytes]);
            }
            break;
        case PNGFilter.None:
            result[0 .. line.length] = line[];
            break;
        default:
            assert(false, "Invalid PNG filter.");
    }
}

/**
 * Deinterlace Adam7 interlaced data.
 *
 * Params:  buffer = Interlaced data will be read from here and deinterlaced data 
 *                   will be written here.
 *          image  = Image information.
 */
void deinterlace(ref Vector!(ubyte) buffer, in PNGImage image)
{
    //result buffer
    Vector!ubyte result;
    result.reserve(8);
    result.length = buffer_size(image);

    /**
     * Perform an adam7 deinterlacing pass.
     *
     * Params:  source = Source interlaced data.
     *          start  = Offset of the first deinterlaced pixel.
     *          dist   = Distance of deinterlaced pixels in the final image, e.g.
     *                   size equal to Vector2u(8, 8) means deinterlace 
     *                   every pixel is placed 8 pixels from previous one,
     *                   horizontally or vertically.
     *          dim    = Dimensions of interlaced data.
     */
    void adam7_pass(in ubyte[] source, in Vector2u start, in Vector2u dist, in Vector2u dim)
    {
        const uint pixel_bytes = (image.bpp + 7) / 8; // pixel_bytes is used for filtering
        //previous line
        ubyte[] previous = new ubyte[image.width * pixel_bytes];
        //current line
        ubyte[] line     = new ubyte[image.width * pixel_bytes];

        ///Place pixels from the current line to result. line_idx is index of the current line.
        void place_pixels(in uint line_idx)
        {
            //ineffective, but relatively readable
            //pixels of the line
            foreach(px; 0 .. dim.x)
            {
                //pixel offset in result without pixel size applied
                const uint offset = image.width * (start.y + dist.y * line_idx) 
                                    + start.x + dist.x * px;
                //working with bytes
                if(image.bpp >= 8)
                {
                    //offset of this pixel in result
                    const uint r = pixel_bytes * offset;
                    //offset of this pixel in line
                    const uint l = pixel_bytes * px;
                    result[r .. r + pixel_bytes] = line[l .. l + pixel_bytes];
                }
                //untested, might not work
                //working with bits
                else
                {
                    //offset of this pixel in bits, not bytes, in result
                    const uint px_start = image.bpp * offset;
                    const uint px_end = image.bpp * (offset + 1);
                    //offset of this pixel in bits, not bytes, in line
                    uint px_start_line = image.bpp * px;
                    
                    //bits in the pixel - r in result, b in line
                    for(uint r = px_start, l = px_start_line; r < px_end; r++, l++)
                    {
                        //bit position in result - 0 is the LSB, 7 is MSB of a byte
                        const uint rbitpos = 7 - (r & 0x7);
                        //bit position in line - 0 is the LSB, 7 is MSB of a byte
                        const uint lbitpos = 7 - (l & 0x7);
                        //bit value
                        const uint _bit = (line[l / 8] >> lbitpos) & 1;
                        //index of this byte in result
                        const uint byte_idx = r / 8;
                        //set the bit
                        result[byte_idx] = cast(ubyte)((result[byte_idx] & ~(1 << rbitpos)) 
                                                      | (_bit << rbitpos));
                    }
                }
            }
        }

        const uint line_length = 1 + ((image.bpp * dim.x + 7) / 8);
        //previous line to the first line is a zero line
        previous[] = 0;
        foreach(line_idx; 0 .. dim.y)
        {
            const uint line_start = line_idx * line_length;
            const PNGFilter filter = cast(PNGFilter)source[line_start];
            const ubyte[] source_line = source[line_start + 1 .. line_start + line_length];

            unfilter_line(line, source_line, previous, pixel_bytes, filter);
            place_pixels(line_idx);
            swap(line, previous);
        }
    }

    //dimensions of data for each pass
    const Vector2u[7] pass_dim = [Vector2u((image.width + 7) / 8, (image.height + 7) / 8),
                                  Vector2u((image.width + 3) / 8, (image.height + 7) / 8),
                                  Vector2u((image.width + 3) / 4, (image.height + 3) / 8),
                                  Vector2u((image.width + 1) / 4, (image.height + 3) / 4),
                                  Vector2u((image.width + 1) / 2, (image.height + 1) / 4),
                                  Vector2u((image.width + 0) / 2, (image.height + 1) / 2),
                                  Vector2u((image.width + 0) / 1, (image.height + 0) / 2)];

    //starting pixel for each pass
    static immutable Vector2u[7] pass_start = [Vector2u(0, 0),
                                               Vector2u(4, 0),
                                               Vector2u(0, 4),
                                               Vector2u(2, 0),
                                               Vector2u(0, 2),
                                               Vector2u(1, 0),
                                               Vector2u(0, 1)];
                    
    //distance between deinterlaced pixels for each pass
    static immutable Vector2u[7] pass_dist = [Vector2u(8, 8),
                                              Vector2u(8, 8),
                                              Vector2u(4, 8),
                                              Vector2u(4, 4),
                                              Vector2u(2, 4),
                                              Vector2u(2, 2),
                                              Vector2u(1, 2)]; 

    //adam7 passes. offset is start of the pass in source
    for(uint p = 0, offset = 0; p < 7; p++)
    {
        //empty pass
        if(pass_dim[p].y * pass_dim[p].x == 0){continue;}

        adam7_pass(buffer[offset .. buffer.length], pass_start[p], pass_dist[p], pass_dim[p]);

        offset += (pass_dim[p].y * (1 + (pass_dim[p].x * image.bpp + 7) / 8));
    }

    buffer = result;
}

/**
 * Reconstruct image from PNG (non-interlaced) data.
 *
 * PNG image data, when uncompressed, has a byte specifying filter before each
 * line and the line is filtered using that filter.
 * This will unapply the filter and pack lines together.
 *
 * Params:  buffer = PNG data will be read from here and output will be written here.
 *                   This might be done in place.
 *          image  = Information about the image.
 */
void reconstruct(ref Vector!ubyte buffer, in PNGImage image)
{
    //we can work with the array directly as we do this in place
    ubyte[] data = buffer.ptr_unsafe[0 .. buffer.length];

    const uint pixel_bytes = (image.bpp + 7) / 8;
    //bits are tightly packed, but lines are always padded to 1 byte boundaries
    const uint line_length = ((image.width * image.bpp) + 7) / 8;
    enforceEx!PNGException(data.length >= (line_length + 1) * image.height, "Invalid size of source data");

    ubyte[] previous = new ubyte[line_length];
    previous[] = 0;
    ubyte[] line = new ubyte[line_length];

    //working with bytes, iterating over lines
    if(image.bpp >= 8) for(uint l = 0, line_start = 0; l < image.height; ++l)
    {
        //line is preceded by a byte specifying filter used
        const auto filter = cast(PNGFilter)data[line_start];
        //copy from data to line to avoid sending overlapping arrays to unfilter_line
        line[] = data[line_start + 1 .. line_start + 1 + line_length];
        //line_start - 1 :in output, lines are packed together, we get rid of the filter bit
        unfilter_line(data[line_start - l .. $], line, previous, pixel_bytes, filter);
        previous = data[line_start - l .. $]; 
        //go to start of next line
        line_start += 1 + line_length;
    }
    //untested, might not work
    //working with bits
    else
    {
        //index if bit (not byte) in output
        uint obit = 0;
        //temp line
        ubyte[] temp = new ubyte[line_length];

        //iterating over lines
        for(uint l = 0, line_start = 0; l < image.height; ++l)
        {
            //line is preceded by a byte specifying filter used
            const auto filter = cast(PNGFilter)data[line_start];
            //copy from data to line to avoid sending overlapping arrays to unfilter_line
            line[] = data[line_start + 1 .. line_start + 1 + line_length];
            unfilter_line(temp, line, previous, pixel_bytes, filter);

            //tbit is bit in temp line
            foreach(tbit; 0 .. image.width * image.bpp)
            {
                //bit position in result - 0 is the LSB, 7 is MSB of a byte
                const uint obitpos = 7 - (obit & 0x7);
                //bit position in temp line - 0 is the LSB, 7 is MSB of a byte
                const uint tbitpos = 7 - (tbit & 0x7);
                //bit value
                const uint _bit = (temp[tbit / 8] >> tbitpos) & 1;
                //index of this byte in output
                const uint byte_idx = obit / 8;
                //set the bit
                data[byte_idx] = cast(ubyte)((data[byte_idx] & ~(1 << obitpos)) 
                                               | (_bit << obitpos));
                obit++;
            }

            previous = data[line_start - l .. $]; 
            //go to start of next line
            line_start += 1 + line_length;
        }
    }
    buffer.length = buffer_size(image); 
}
