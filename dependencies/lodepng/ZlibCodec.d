/// wraps zlib
module lodepng.ZlibCodec;
//pragma(lib, "zlib");

import czlib = etc.c.zlib;
import lodepng.util;


// buffered decompression of zlib streams, avoiding GC provocation where possible
struct DecodeStream
{
    // TODO: should be scope class for releasing zlib resources on scope exit

    // constructor: initialize with target, will be resized as needed
    static DecodeStream create(inout ubyte[] dest)
    {
        DecodeStream result;
        result.dest = dest;

        result.zlibStream.next_out = dest.ptr;
        result.zlibStream.avail_out = dest.length;
        result.zlibStream.avail_out = dest.length; //Z_BINARY
        result.zlibStream.data_type = czlib.Z_BINARY;

        return result;
    }

    ubyte[] opCall()
    {
        return dest;
    }

    void opCall(in ubyte[] input)
    {
        zlibStream.next_in = input.ptr;
        zlibStream.avail_in = input.length;

        if (!isInit)
        {
            isInit = true;
            msg = czlib.inflateInit(&zlibStream);
	        if (msg)
	        {
	            czlib.inflateEnd(&zlibStream);
	            throw new Exception("");// TODO: toString(msg));
	        }
        }

        while(zlibStream.avail_in)
        {
            msg = czlib.inflate(&zlibStream, czlib.Z_NO_FLUSH);

            if (msg == czlib.Z_STREAM_END)
            {
                czlib.inflateEnd(&zlibStream);
                hasEnded = true;
                dest.length = zlibStream.total_out;
                return;
            }
            else if (msg != czlib.Z_OK)
            {
                czlib.inflateEnd(&zlibStream);
                throw new Exception("");// TODO: toString(zlibStream.msg));
            }
            else if(zlibStream.avail_out == 0)
            {
                dest.length = dest.length * 2;
                zlibStream.next_out = &dest[dest.length / 2];
                zlibStream.avail_out = dest.length / 2;
            }
        }
    }

    bool isInit = false;
    bool hasEnded = false;

    private
	{
	    ubyte[] dest;
	    int msg = 0;
	    czlib.z_stream zlibStream;
	}
}

struct Encoder
{
    static Encoder create(ubyte strategy = czlib.Z_RLE, uint clevel = 9)
    {
        Encoder result;
        result.level = clevel;
        result.strategy = strategy;
        return result;
    }
    ubyte[] opCall(in ubyte[] source)
    {
        ubyte[] result;
        return this.opCall(source, result);

    }
    ubyte[] opCall(in ubyte[] source, ref ubyte[] buffer)
    {
        if (source.length == 0)
        {
            buffer.length = 0;
            return buffer;
        }

        buffer.length = source.length / 4;
        czlib.z_stream stream;
        stream.next_in = source.ptr;
        stream.avail_in = source.length;
        stream.next_out = buffer.ptr;
        stream.avail_out = buffer.length;
        stream.data_type = czlib.Z_BINARY;

        czlib.deflateInit2(&stream, 9, czlib.Z_DEFLATED, 15, level, strategy);
        auto msg = czlib.deflate(&stream, czlib.Z_FINISH);
        while(msg != czlib.Z_STREAM_END)
        {
            buffer.length = buffer.length + buffer.length;
            stream.next_out = &buffer[buffer.length / 2];
            stream.avail_out = buffer.length / 2;
            msg = czlib.deflate(&stream, czlib.Z_FINISH);
        }

        assert(msg == czlib.Z_STREAM_END);
        buffer.length = stream.total_out;
        czlib.deflateEnd(&stream);

        return buffer;
    }

    private ubyte strategy = czlib.Z_RLE;
    private ubyte level = 9;
}
