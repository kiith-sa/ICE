
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.zlib;


import etc.c.zlib;

import math.math;
import containers.vector;
import util.exception;


///Exception thrown at errors related to compression (such as zlib).
class CompressionException : Exception{this(string msg){super(msg);}}

///Zlib compression strategy.
enum CompressionStrategy : ubyte
{
    Default = 0,
    Filtered = 1,
    HuffmanOnly = 2,
    RLE = 3,
    Fixed = 4,
    None = ubyte.max
}

/**
 * Decompress data compressed with Zlib.
 *
 * Params:  input   = Data to decompress.
 *          reserve = Expected size of decompressed data, used to reserve
 *                    space for decompression. 0 (default) means automatic.
 *
 * Returns: Decompressed data.
 *
 * Throws:  CompressionException if the data could not be decompressed.
 */
ubyte[] zlib_inflate(ubyte[] input, uint reserve = 0)
{
    ubyte[] inflated = new ubyte[reserve == 0 ? max(1u, input.length * 4) : reserve];

    z_stream stream;
    with(stream)
    {
        data_type = Z_BINARY;
        next_out = inflated.ptr;
        avail_out = inflated.length;
        next_in = input.ptr;
        avail_in = input.length;
    }

    scope(exit){inflateEnd(&stream);}
    enforceEx!(CompressionException)
              (!cast(bool)inflateInit(&stream), "Zlib decompression initialization error");

    while(stream.avail_in)
    {
        int message = inflate(&stream, Z_NO_FLUSH);

        if(message == Z_STREAM_END)
        {
            inflated.length = stream.total_out;
            return inflated;
        }
        else if(message != Z_OK){throw new CompressionException("Zlib decompression error");}
        else if(stream.avail_out == 0)
        {
            inflated.length = inflated.length * 2;
            stream.next_out = &inflated[inflated.length / 2];
            stream.avail_out = inflated.length / 2;
        }
    }
    assert(false, "Unfinished zlib decompression");
}

/**
 * Buffered Zlib decompressor. Used to decompress Zlib data piece by piece.
 *
 * Stores compressed data in an outside vector.
 */
struct Inflator
{
    private:
        ///Decompressed data.
        Vector!(ubyte)* inflated_;
        ///Zlib stream used for decompression.
        z_stream stream_;

        ///Have we started decompressing?
        bool started_ = false;
        ///Are we done with decompression? (Did we reach the end of the Zlib stream?)
        bool ended_ = false;

    public:
        /**
         * Construct an Inflator.
         *
         * Params:  inflated = Vector to write decompressed data to.
         *                     Any existing data in the vector will be overwritten.
         */
        static Inflator opCall(ref Vector!(ubyte) inflated)
        {
            Inflator result;

            inflated.length = inflated.allocated;

            result.inflated_ = &inflated;
            result.stream_.next_out = inflated.ptr;
            result.stream_.avail_out = inflated.length;
            result.stream_.avail_out = inflated.length;
            result.stream_.data_type = Z_BINARY;

            return result;
        }

        /**
         * Decompress a piece of the data.
         *
         * Throws:  CompressionException if the data could not be decompressed.
         */
        void inflate(ubyte[] input)
        {
            stream_.next_in = input.ptr;
            stream_.avail_in = input.length;

            if(!started_)
            {
                started_ = true;
                enforceEx!(CompressionException)(!cast(bool)inflateInit(&stream_), 
                                                 "Zlib decompression initialization error");
            }

            while(stream_.avail_in)
            {
                int message = .inflate(&stream_, Z_NO_FLUSH);

                if(message == Z_STREAM_END)
                {
                    inflateEnd(&stream_);
                    inflated_.length = stream_.total_out;
                    ended_ = true;
                    return;
                }
                else if(message != Z_OK)
                {
                    inflateEnd(&stream_);
                    throw new CompressionException("Zlib decompression error");
                }
                else if(stream_.avail_out == 0)
                {
                    inflated_.length = inflated_.length * 2;
                    stream_.next_out = inflated_.ptr + inflated_.length / 2;
                    stream_.avail_out = inflated_.length / 2;
                }
            }
        }
}

/**
 * Compress data using Zlib.
 *
 * Params:  source   = Data to compress.
 *          strategy = Zlib compression strategy to use.
 *          level    = Compression level. Must be at least 0 and at most 9.
 *
 * Returns: Compressed data.
 */
ubyte[] zlib_deflate(ubyte[] source, CompressionStrategy strategy = CompressionStrategy.RLE,
                     uint level = 9)
{
    ubyte[] buffer;
    deflate_(buffer, source, strategy, level);
    return buffer;
}

/**
 * Compress data using Zlib.
 *
 * Params:  result   = Compressed data will be written here.
 *          source   = Data to compress.
 *          strategy = Zlib compression strategy to use.
 *          level    = Compression level. Must be at least 0 and at most 9.
 *
 * Returns: Compressed data.
 */
void zlib_deflate(ref Vector!(ubyte) result, ubyte[] source, 
                  CompressionStrategy strategy = CompressionStrategy.RLE,
                  uint level = 9)
{deflate_(result, source, strategy, level);}

package:
/**
 * Check CRC using zlib CRC32 function.
 *
 * Params:  crc  = CRC32 to check.
 *          data = Data to check CRC of.
 *
 * Returns: True if CRC matches, false otherwise.
 */
bool zlib_check_crc(uint crc, ubyte[] data){return crc == crc32(0, data.ptr, data.length);}

/**
 * Generate CRC using zlib CRC32 function.
 *
 * Params:  data = Data to generate CRC for.
 * 
 * Returns: Generated CRC32.
 */
uint zlib_crc(ubyte[] data){return crc32(0, data.ptr, data.length);}

private:
/**
 * Compress data using Zlib (implementation).
 *
 * Params:  result   = Compressed data will be written here.
 *          source   = Data to compress.
 *          strategy = Zlib compression strategy to use.
 *          level    = Compression level. Must be at least 0 and at most 9.
 *
 * Returns: Compressed data.
 */
void deflate_(Buffer)(ref Buffer result, ubyte[] source, 
                      CompressionStrategy strategy, uint level)
in{assert(level <= 9, "Invalid zlib compression level");}
body
{
    if(source.length == 0){return;}

    //zlib usually compresses images to less than a fourth and we usually compress images
    //also prevent zero sized buffers in case we're deflating something really small
    result.length = max(1u, source.length / 4);

    z_stream stream;
    with(stream)
    {
        next_in = source.ptr;
        avail_in = source.length;
        next_out = result.ptr;
        avail_out = result.length;
        data_type = Z_BINARY;
    }

    deflateInit2(&stream, level, Z_DEFLATED, 15, 9, cast(ubyte)strategy);

    //deflate
    auto message = deflate(&stream, Z_FINISH);
    while(message != Z_STREAM_END)
    {
        result.length = result.length * 2;
        stream.next_out = result.ptr + result.length / 2;
        stream.avail_out = result.length / 2;
        message = deflate(&stream, Z_FINISH);
    }

    assert(message == Z_STREAM_END, "Unfinished zlib compression");

    result.length = stream.total_out;
    deflateEnd(&stream);
}
