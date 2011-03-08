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

module formats.pngdecoder;


import std.string;
import std.intrinsic;

import formats.pngcommon;
import formats.zlib;
import math.vector2;
import util.iterator;
import util.exception;
import util.swap;
import color;


package:
/**
 * PNG file decoder. Supports all color types, interlacing, color key, background color, 
 * text. However, color types with less than 8 bytes per pixels are not tested at the 
 * moment and might not work.
 */
struct PNGDecoder
{
    private:
    public:
        /**
         * Decode PNG file data.
         *
         * Params:  source = PNG data to decode.
         *          info   = PNG info object to write image information to.
         *
         * Returns: Decoded image data.
         *
         * Throws:  PNGException on decoding error, Exception on decompression error.
         */
        ubyte[] decode(ubyte[] source, ref PNGInfo info)
        {
            //TODO Vector, and return Vector. Don't care about copying yet, it might
            //end up being fast enough (probably much faster than deflating, anyway)
            info = PNGInfo(read_header(source, info.interlace));

            uint expected_length = info.interlace 
                                   ? buffer_size(info.image) + info.image.height * 2
                                   : buffer_size(info.image) + info.image.height;

            auto inflator = Inflator(expected_length);

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
                        enforceEx!(PNGException)(chunk.data.length <= 256 * 3, 
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
                            enforceEx!(PNGException)(chunk.data.length <= info.palette.length, 
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
                        auto sep = find(cast(string)chunk.data, 0);
                        if(sep > 0)
                        {
                            if(chunk.data[sep + 1] == 0)
                            {
                                info.text.latin[chunk.data[0 .. sep]] = 
                                               chunk.data[sep + 2 .. $];
                            }
                            else
                            {
                                info.text.latin[chunk.data[0 .. sep]] = 
                                               zlib_inflate(chunk.data[sep + 2 .. $]);
                            }
                        }
                        break;
                    //text
                    case tEXt:
                        auto sep = find(cast(string)chunk.data, 0);
                        if(sep > 0)
                        {
                            info.text.latin[chunk.data[0 .. sep]] = chunk.data[sep + 1 .. $];
                        }
                        break;
                    //utf-8 text
                    case iTXt:
                        auto sep = find(cast(string)chunk.data, 0);
                        string keyword = cast(string)chunk.data[0 .. sep];
                        bool compressed = cast(bool)chunk.data[sep + 1];
                        sep += find(cast(string)chunk.data[sep + 3 .. $], 0) + 3;
                        sep += find(cast(string)chunk.data[sep + 1 .. $], 0) + 1;
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
                        enforceEx!(PNGException)((bt(&chunk.type, 6) < 0), 
                                   "Unrecognized critical chunk");
                        break;
                }
            }

            ubyte[] buffer = inflator.inflated;

            buffer = (info.interlace == 0) ? reconstruct(buffer, info.image)
                                           : deinterlace(buffer, info.image);

            return buffer;
        }
}

private:
///Size of a PNG header.
const uint header_size = 34;

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
PNGImage read_header(ubyte[] source, out ubyte interlace)
{
    //spec: http://www.w3.org/TR/PNG/#11IHDR

    enforceEx!(PNGException)(source.length >= header_size, "PNG header too small");
    enforceEx!(PNGException)(source[0 .. 8] == png_magic_number, 
                             "Invalid PNG header (PNG magic number does not match)");
    enforceEx!(PNGException)(get_uint(source[12 .. 16]) == IHDR, 
                             "Invalid PNG header (Header name does not match)");
    enforceEx!(PNGException)(zlib_check_crc(get_uint(source[29 .. 33]), source[12 .. 29]), 
                             "Invalid PNG CRC (file might be corrupted?)");

    PNGImage result;
    with(result)
    {
        width = get_uint(source[16 .. 20]);
        height = get_uint(source[20 .. 24]);
        bit_depth = source[24];
        color_type = cast(PNGColorType) source[25];
        enforceEx!(PNGException)(source[26] == 0, 
                                 "Unsupported compression method in PNG header");
        enforceEx!(PNGException)(source[27] == 0, 
                                 "Unsupported filter method in PNG header");
        enforceEx!(PNGException)(validate_color(color_type, bit_depth), 
                                 "Invalid color format in PNG header");
        interlace = source[28];
        enforceEx!(PNGException)(interlace < 2, 
                                 "Invalid  interlace method in PNG header");
        bpp = cast(ubyte)(num_channels(color_type) * bit_depth);
    }
    return result;
}

/**
 * Estimate buffer size needed for decoding an image with specified parameters.
 *
 * Params:  image = Image to estimate buffer size for.
 *
 * Returns: Estimated buffer size. Not exact.
 */
uint buffer_size(ref PNGImage image){return ((image.width * image.bpp + 7) / 8) * image.height;}

///Iterator over PNG chunks.
class PNGChunkIterator : Iterator!(PNGChunk)
{
    private:
        ///PNG data stream (without header).
        ubyte[] stream_;

    public:
        ///Construct a PNGChunkIterator over specified stream (without header).
        this(ubyte[] stream){stream_ = stream;}

        override int opApply(int delegate(ref PNGChunk chunk) visitor)
        {
            int result = 0;
            uint pos = 0;
            PNGChunk chunk;
            while(pos + chunk_min_size <= stream_.length)
            {
                chunk = PNGChunk.from_stream(stream_[pos .. $]);
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
void unfilter_line(ubyte[] result, ubyte[] line, ubyte[] previous, uint pixel_bytes,
                   PNGFilter filter)
{
	switch(filter)
	{
		case PNGFilter.Paeth:
            //first pixel
            result[0 .. pixel_bytes] = line[0 .. pixel_bytes] + previous[0 .. pixel_bytes];
            //rest of the line
			for(uint i = pixel_bytes; i < line.length; i++)
            {
                result[i] = cast(ubyte)(line[i] +
                                        paeth_predictor(result[i - pixel_bytes],
                                                       previous[i],
                                                       previous[i - pixel_bytes]));
            }
            break;
		case PNGFilter.Average:
            //first pixel
            result[0 .. pixel_bytes] = line[0 .. pixel_bytes] + previous[0 .. pixel_bytes] / 2;
            //rest of the line
			for(uint i = pixel_bytes; i < line.length; i++)
            {
                result[i] = line[i] + ((result[i - pixel_bytes] + previous[i]) / 2);
            }
			break;
		case PNGFilter.Up:
            result[0 .. line.length] = line[] + previous[];
			break;
		case PNGFilter.Sub:
            //first pixel
            result[0 .. pixel_bytes] = line[0 .. pixel_bytes];
            //rest of the line
            for(uint i = pixel_bytes; i < line.length; i++)
            {
                result[i] = line[i] + result[i - pixel_bytes];
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
 * Params:  lines = Interlaced data.
 *          image = Image information.
 * 
 * Returns: Deinterlaced data.
 */
ubyte[] deinterlace(ubyte[] input, ref PNGImage image)
{
    //TODO Vector
    ubyte[] result = new ubyte[buffer_size(image)/* + image.height*/];

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
    void adam7_pass(ubyte[] source, Vector2u start, Vector2u dist, Vector2u dim)
    {
        uint pixel_bytes = (image.bpp + 7) / 8; // pixel_bytes is used for filtering
        //previous line
        ubyte[] previous = new ubyte[image.width * pixel_bytes];
        //current line
        ubyte[] line = new ubyte[image.width * pixel_bytes];

        ///Place pixels from the current line to result. line_idx is index of the current line.
        void place_pixels(uint line_idx)
        {
            //ineffective, but relatively readable
            //pixels of the line
            for(uint px = 0; px < dim.x; px++)
            {
                //pixel offset in result without pixel size applied
                uint offset = image.width * (start.y + dist.y * line_idx) + start.x + dist.x * px;
                //working with bytes
                if(image.bpp >= 8)
                {
                    //offset of this pixel in result
                    uint r = pixel_bytes * offset;
                    //offset of this pixel in line
                    uint l = pixel_bytes * px;
                    result[r .. r + pixel_bytes] = line[l .. l + pixel_bytes];
                }
                //untested, might not work
                //working with bits
                else
                {
                    //offset of this pixel in bits, not bytes, in result
                    uint px_start = image.bpp * offset;
                    uint px_end = image.bpp * (offset + 1);
                    //offset of this pixel in bits, not bytes, in line
                    uint px_start_line = image.bpp * px;
                    
                    //bits in the pixel - r in result, b in line
                    for(uint r = px_start, l = px_start_line; r < px_end; r++, l++)
                    {
                        //bit position in result - 0 is the LSB, 7 is MSB of a byte
                        uint rbitpos = 7 - (r & 0x7);
                        //bit position in line - 0 is the LSB, 7 is MSB of a byte
                        uint lbitpos = 7 - (l & 0x7);
                        //bit value
                        uint _bit = (line[l / 8] >> lbitpos) & 1;
                        //index of this byte in result
                        uint byte_idx = r / 8;
                        //set the bit
                        result[byte_idx] = cast(ubyte)((result[byte_idx] & ~(1 << rbitpos)) 
                                                      | (_bit << rbitpos));
                    }
                }
            }
        }

        uint line_length = 1 + ((image.bpp * dim.x + 7) / 8);
        //previous line to the first line is a zero line
        previous[] = 0;
        for(uint line_idx = 0; line_idx < dim.y; line_idx++)
        {
            uint line_start = line_idx * line_length;
            PNGFilter filter = cast(PNGFilter)source[line_start];
            ubyte[] source_line = source[line_start + 1 .. line_start + line_length];

            unfilter_line(line, source_line, previous, pixel_bytes, filter);
            place_pixels(line_idx);
            swap(line, previous);
        }
    }

    //dimensions of data for each pass
    Vector2u[7] pass_dim = [Vector2u((image.width + 7) / 8, (image.height + 7) / 8),
                            Vector2u((image.width + 3) / 8, (image.height + 7) / 8),
                            Vector2u((image.width + 3) / 4, (image.height + 3) / 8),
                            Vector2u((image.width + 1) / 4, (image.height + 3) / 4),
                            Vector2u((image.width + 1) / 2, (image.height + 1) / 4),
                            Vector2u((image.width + 0) / 2, (image.height + 1) / 2),
                            Vector2u((image.width + 0) / 1, (image.height + 0) / 2)];

    //starting pixel for each pass
    const Vector2u[7] pass_start = [Vector2u(0, 0),
                                    Vector2u(4, 0),
                                    Vector2u(0, 4),
                                    Vector2u(2, 0),
                                    Vector2u(0, 2),
                                    Vector2u(1, 0),
                                    Vector2u(0, 1)];
                    
    //distance between deinterlaced pixels for each pass
    const Vector2u[7] pass_dist = [Vector2u(8, 8),
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

        adam7_pass(input[offset .. $], pass_start[p], pass_dist[p], pass_dim[p]);

        offset += (pass_dim[p].y * (1 + (pass_dim[p].x * image.bpp + 7) / 8));
    }

    return result;
}

/**
 * Reconstruct image from PNG (non-interlaced) data.
 *
 * PNG image data, when uncompressed, has a byte specifying filter before each
 * line and the line is filtered using that filter.
 * This will unapply the filter and pack lines together.
 *
 * Params:  buffer = PNG data. Might be altered (changed in place).
 *          image  = Information about the image.
 *
 * Returns: Reconstructed image.
 */
ubyte[] reconstruct(ubyte[] data, ref PNGImage image)
{
    //TODO Vectors
	uint pixel_bytes = (image.bpp + 7) / 8;
    //bits are tightly packed, but lines are always padded to 1 byte boundaries
    uint line_length = ((image.width * image.bpp) + 7) / 8;
    enforceEx!(PNGException)(data.length >= (line_length + 1) * image.height, "Invalid size of source data");

    ubyte[] previous = new ubyte[line_length];
    previous[] = 0;
    ubyte[] line = new ubyte[line_length];

    //working with bytes
    if(image.bpp >= 8)
    {
        //iterating over lines
        for(uint l = 0, line_start = 0; l < image.height; ++l)
        {
            //line is preceded by a byte specifying filter used
            auto filter = cast(PNGFilter)data[line_start];
            //copy from data to line to avoid sending overlapping arrays to unfilter_line
            line[] = data[line_start + 1 .. line_start + 1 + line_length];
            //line_start - 1 :in output, lines are packed together, we get rid of the filter bit
            unfilter_line(data[line_start - l .. $], line, previous, pixel_bytes, filter);
            previous = data[line_start - l .. $]; 
            //go to start of next line
            line_start += 1 + line_length;
        }
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
            auto filter = cast(PNGFilter)data[line_start];
            //copy from data to line to avoid sending overlapping arrays to unfilter_line
            line[] = data[line_start + 1 .. line_start + 1 + line_length];
            unfilter_line(temp, line, previous, pixel_bytes, filter);

            //tbit is bit in temp line
            for(uint tbit = 0; tbit < image.width * image.bpp; tbit++)
            {
                //bit position in result - 0 is the LSB, 7 is MSB of a byte
                uint obitpos = 7 - (obit & 0x7);
                //bit position in temp line - 0 is the LSB, 7 is MSB of a byte
                uint tbitpos = 7 - (tbit & 0x7);
                //bit value
                uint _bit = (temp[tbit / 8] >> tbitpos) & 1;
                //index of this byte in output
                uint byte_idx = obit / 8;
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
    data.length = buffer_size(image); 
	return data;
}
