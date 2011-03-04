/***************************************************************************************************
License:
Copyright (c) 2005-2007 Lode Vandevenne
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.<br>
  - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.<br>
  - Neither the name of Lode Vandevenne nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.<br>

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Lode Vandevenne (original version in C++), Lutger Blijdestijn (D version) : lutger dot blijdestijn at gmail dot com.

Date: August 7, 2007

About:
The lodepng encoder can encode images of any of the supported png color formats to 24-bit RGB or
32-bit RGBA png images. Conversion, if needed, is done automatically. It is compatible with the
Phobos and Tango libraries. For Tango, lodepng expects the zlib binding from phobos in etc.c.zlib.d<br>
This module publicly imports lodepng.Common, where you'll find the data types used by both the encoder
and decoder, as well as some utility and image format conversion routines.<br>

Features:
The following features are supported by the encoder:
<ul>
    <li> conformant encoding of 24-bit RGB and 32-bit RGBA PNG images </li>
    <li> automatic conversion of other color formats </li>
    <li> setting the compression and filter methods </li>
    <li> textual key-value metadata: normal and compressed latin1, unicode (utf-8) </li>
    <li> transparency / colorkey </li>
    <li> the following chunks are written by the encoder
        <ul>
            <li>IHDR (image information)</li>
            <li>IDAT (pixel data)</li>
            <li>IEND (the final chunk)</li>
            <li>tRNS (colorkey)</li>
            <li>bKGD (suggested background color) </li>
            <li>tEXt (uncompressed latin-1 key-value strings)</li>
            <li>zTXt (compressed latin-1 key-value strings)</li>
            <li>iTXt (utf8 key-value strings)</li>
        </ul>
   </li>
</UL>

<b>Limitations:</b><br>
The following features are not supported.
<ul>
    <li> Ouput in any color formats other than 24-bit RGB or 32-bit RGBA</li>
    <li> Interlacing </li>
    <li> The following chunk types are not written by the encoder
        <ul>
            <li>PLTE (color palette)</li>
            <li>cHRM (device independent color info) </li>
            <li>gAMA (device independent color info) </li>
            <li>iCCP (device independent color info) </li>
            <li>sBIT (original number of significant bits) </li>
            <li>sRGB (device independent color info) </li>
            <li>pHYs (physical pixel dimensions) </li>
            <li>sPLT (suggested reduced palette) </li>
            <li>tIME (last image modification time) </li>
        </ul>
    </li>
</ul>

References:
$(LINK2 http://members.gamedev.net/lode/projects/LodePNG/, Original lodepng) <br>
$(LINK2 http://www.w3.org/TR/PNG/, PNG Specification) <br>
$(LINK2 http://www.libpng.org/pub/png/pngsuite.html, PNG Suite: set of test images) <br>
$(LINK2 http://optipng.sourceforge.net/, OptiPNG: tool to experimentally optimize png images)
***************************************************************************************************/
module lodepng.Encode;

version (Tango)
{
    import tango.math.Math;
}
else
    import std.math;
import lodepng.ZlibCodec;
public import lodepng.Common;

/***************************************************************************************************
    Returns a png image of the raw pixels provided by source and described by original

        This function will attempt to convert to 24-bit RGB if it is a lossless operation, otherwise
        the resulting png image will be in the 32-bit RGBA format. The array returned can be written to disk
        as a png file.

        throws: PngException
***************************************************************************************************/
ubyte[] encode( in ubyte[] source, in PngInfo original)
{
    ubyte[] buf;
    return _encode(source, original, EncodeOptions(), buf);
}

/**************************************************************************************************
    Returns a png image of the raw pixels provided by source and described by original.

        See also: EncodeOptions

        throws: PngException
***************************************************************************************************/
ubyte[] encode( in ubyte[] source, in PngInfo original, in EncodeOptions options)
{
    ubyte[] buf;
    return _encode(source, original, options, buf);
}

/***************************************************************************************************
    Combinations of filter and compression trade-offs

        The png compression scheme works by applying lossless filters on the image data and then
        compressing with the deflate (zlib) algorithm. The filters condition the data for better
        compression. This enumeration can be used with EncodeOptions, see FilterStrategy and
        CompressionStrategy for more control over how the image is encoded.

***************************************************************************************************/
enum EncodingStrategy
{
    /// source data is stored as is
    Store,

    /** this gives zero compression but can be useful for storage in a zlib compressed file, in
    which case the filtering conditions the data for better compression **/
    FilterOnly,

    /// aim for reasonable compression but with emphasis on speed
    Fast,

    /// aim for good compression / speed tradeoff
    Normal,

    /// aim for best compression
    Best
}

/***************************************************************************************************
    Filter method

        The png specification defines five types of filters. In addition each scanline can have a
        different filtering method applied (Dynamic). The latter method gives the best compression,
        when a fixed method is preffered usually paeth works best.

***************************************************************************************************/
enum FilterStrategy : ubyte
{
    None = 0, ///
    Up = 1, ///
    Sub = 2, ///
    Average = 3, ///
    Paeth = 4, ///
    Dynamic, ///
}

/***************************************************************************************************
    Zlib compression method

        Which compression scheme works best depends on the type of image. Tools such as optipng can
        figure this out experimentally.

***************************************************************************************************/
enum CompressionStrategy : ubyte
{

    Default = 0, ///
    Filtered = 1, ///
    RLE = 3, ///
    None = ubyte.max ///
}

/// Controls how a png image is encoded and what auxiliary data is to be written
struct EncodeOptions
{
    /// constructors
    static EncodeOptions opCall()
    {
        EncodeOptions result;
        return result;
    }

    /// ditto
    static EncodeOptions opCall(ColorType colorType,
                                EncodingStrategy strategy = EncodingStrategy.Normal,
                                bool autoRemoveAlpha = true)
    {
        EncodeOptions result;
        result.setStrategy(strategy);

        with (result)
        {
            autoRemoveAlpha = autoRemoveAlpha;
            targetColorType = colorType;
        }
        return result;
    }

    /// ditto
    static EncodeOptions opCall(EncodingStrategy strategy,
                                bool autoRemoveAlpha = true)
    {
        EncodeOptions result;
        result.setStrategy(strategy);
        return result;
    }

    /// ditto
    static EncodeOptions opCall(CompressionStrategy compression, FilterStrategy filter = FilterStrategy.Dynamic)
    {
        EncodeOptions result;
        result.compressionLevel = 9;
        result.compressionStrategy = compression;
        result.filterStrategy = filter;
        return result;
    }

    invariant
    {
        assert(compressionLevel >=0 && compressionLevel <= 9, "invalid zlib compression level");
        assert(targetColorType == ColorType.Any ||
                targetColorType == ColorType.RGB ||
                targetColorType == ColorType.RGBA, "colortype is not supported");
    }

    /***********************************************************************************************
        The colortype of the target image

            lodepng can only encode in RGB(A) format. If the format is set ColorType.Any, RGB or
            RGBA is chosen depending on whether the source image has an alpha channel.
    ***********************************************************************************************/
    ColorType targetColorType = ColorType.Any;

    /***********************************************************************************************
        Remove alpha channel

            If set to true and the source image has an alpha channel, this will be removed if (and
            only if) the image is fully opaque or a colorkey can be written. This is considered a
            lossless operation.
    ***********************************************************************************************/
    bool autoRemoveAlpha = true;

    PngText text; /// key-value strings to be written, see also: lodepng.Common.PngText
    bool compressText = false; /// if zlib compression is to be used on text

    ubyte[] backgroundColor; /// suggested background RGB-triplet, must be either 3 or 6 bytes

    bool  colorKey = false; /// colorkey, set to true if it is to be encoded
    ubyte keyR;     /// red/greyscale component of color key
    ubyte keyG;     /// green component of color key
    ubyte keyB;     /// blue component of color key

    ubyte compressionLevel = 6; /// zlib compression level, affects memory use. Must be in range 0-9
    FilterStrategy filterStrategy = FilterStrategy.Dynamic; /// see FilterStrategy
    CompressionStrategy compressionStrategy = CompressionStrategy.RLE; /// see CompressionStrategy

    /// This will set compressionLevel, compressionStrategy and filterStrategy
    void setStrategy(EncodingStrategy strategy)
    {
        switch (strategy)
        {
            case EncodingStrategy.Store:
                compressionLevel = 0;
                compressionStrategy = CompressionStrategy.None;
                filterStrategy = FilterStrategy.None;
            	break;
            case EncodingStrategy.FilterOnly:
                compressionLevel = 0;
                compressionStrategy = CompressionStrategy.None;
                filterStrategy = FilterStrategy.Dynamic;
            	break;
            case EncodingStrategy.Fast:
            	compressionLevel = 6;
                compressionStrategy = CompressionStrategy.RLE;
                filterStrategy = FilterStrategy.Paeth;
            	break;
            case EncodingStrategy.Normal:
                compressionLevel = 6;
                compressionStrategy = CompressionStrategy.RLE;
                filterStrategy = FilterStrategy.Dynamic;
            	break;
            case EncodingStrategy.Best:
                compressionLevel = 9;
                compressionStrategy = CompressionStrategy.Filtered;
                filterStrategy = FilterStrategy.Dynamic;
            	break;
/+ TODO: decide to implement or leave it out
            case EncodingStrategy.ByteCrunch:
                compressionLevel = 9;
                compressionStrategy = CompressionStrategy.Filtered;
                filterStrategy = FilterStrategy.Dynamic;
            	break;
+/
            default:
                assert(false, "I don't know about this strategy");
                break;
        }
    }
}

private
{
    ubyte[] _encode( in ubyte[] source, in PngInfo original, in EncodeOptions options, inout ubyte[] buffer)
    {
        // TODO: be more sparing with memory here, can at least avoid one array copy

        Chunk[] ChunkList;

        // find out what colortype of target should be and whether colorkey (tRNS) should be made
        ColorType destColor = (options.targetColorType == ColorType.RGB ||
                               options.targetColorType == ColorType.RGBA) ? options.targetColorType :
                               original.image.colorType;
        if (!(destColor == ColorType.RGB || destColor == ColorType.RGBA))
            destColor = (hasAlphaChannel(original.image.colorType)) ? ColorType.RGBA : ColorType.RGB;
        if (options.autoRemoveAlpha && destColor == ColorType.RGBA && !options.colorKey)
        {
            ubyte[] colorKey;
            if (opaqueOrColorkey(source, original, colorKey))
            {
                if (colorKey.length)
                    ChunkList ~= Chunk(tRNS, colorKey);
                destColor = ColorType.RGB;
            }
        }

        // properties of image to be written
        auto image = PngImage(original.image.width, original.image.height, 8, destColor);

        // convert original if necessary
        ubyte[] pixels;
        if (original.image.colorType != destColor || original.image.bitDepth != 8)
            pixels = convert(source, original, destColor);
        else
            pixels = source;

        ChunkList ~= Chunk(IHDR, headerData(image));
        ChunkList ~= Chunk(IDAT,
            Encoder.create(options.compressionStrategy, options.compressionLevel)(filter(pixels, image)));
        if(options.colorKey)
            ChunkList ~= Chunk(tRNS, [0, cast(ubyte)options.keyR, 0, cast(ubyte)options.keyG, 0, cast(ubyte)options.keyB]);
        if(options.backgroundColor.length == 3)
            ChunkList ~= Chunk( bKGD, [
                                0, options.backgroundColor[0],
                                0, options.backgroundColor[1],
                                0, options.backgroundColor[2] ]);
        else if(options.backgroundColor.length == 6)
               ChunkList ~= Chunk( bKGD, options.backgroundColor);
        if (options.text !is null && (options.text.latin1Text.length > 0 || options.text.unicodeText.length > 0))
            ChunkList ~= chunkifyText(options);
        ChunkList.sort;
        ChunkList ~= Chunk(IEND, []);

        // pre-allocate space needed
        uint pngLength = 8;
        foreach(chunk; ChunkList)
            pngLength += chunk.length;
        buffer.length = pngLength;
        buffer.length = 0;

        // create and write all data
        writeSignature(buffer);
        foreach(chunk; ChunkList)
            writeChunk(buffer, chunk);

        return buffer;
    }

    Chunk[] chunkifyText(EncodeOptions options)
    {
        Chunk[] result;
        if (options.compressText)
        {
            auto enc = Encoder.create();
            foreach(ubyte[] keyword, ubyte[] value; options.text)
                result ~= Chunk(zTXt, keyword ~ cast(ubyte[])[0, 0] ~ enc(value));
            foreach(char[] keyword, char[] value; options.text)
                result ~= Chunk(iTXt, cast(ubyte[])keyword ~ cast(ubyte[])[0, 1, 0, 0, 0] ~ enc(cast(ubyte[])value));
        }
        else
        {
            foreach(ubyte[] keyword, ubyte[] value; options.text)
                result ~= Chunk(tEXt, keyword ~ cast(ubyte[])[0] ~ value);
            foreach(char[] keyword, char[] value; options.text)
                result ~= Chunk(iTXt, cast(ubyte[])keyword ~ cast(ubyte[])[0, 0, 0, 0, 0] ~ cast(ubyte[])value);
        }
        return result;
    }

    ubyte[] filter(in ubyte[] source, ref PngImage image, FilterStrategy filterMethod = FilterStrategy.Dynamic)
    {
        /* adaptive filtering */

        ubyte[] buffer = new ubyte[image.width * (image.bpp / 8) * image.height];
        uint bytewidth = (image.bpp + 7) / 8;

        uint scanlength = image.width * bytewidth;
        buffer.length = image.height * (scanlength + 1) + image.height;
        ubyte[] line, previous;
        buffer.length = 0;
        line = source[0..scanlength];
        ubyte bestFilter = 0;

        uint absSum(ubyte[] array)
        {
            uint result = 0;
            foreach(value; array)
                result += abs(cast(int)(cast(byte)value));
            return result;
        }

        uint smallest = absSum(filterMap(line, &None, bytewidth));

        void setSmallest(uint sum, ubyte filterType)
        {
            if (sum < smallest)
            {
                smallest = sum;
                bestFilter = filterType;
            }
        }

        if (filterMethod == FilterStrategy.Dynamic)
        {
            for (ubyte f = 1; f < 5; f++)
                setSmallest(absSum(dynFilterMap(line, f, bytewidth)), f);
            buffer ~= bestFilter;
            buffer ~= dynFilterMap(line, bestFilter, bytewidth);

            for (int y = 1; y < image.height; y++)
            {
                line = source[scanlength * y..scanlength * y + scanlength];
                previous = source[scanlength * (y - 1)..scanlength * y];

                bestFilter = 0;
                smallest = absSum(filterMap(line, &None, bytewidth));
                for (ubyte f = 1; f < 5; f++)
                     setSmallest(absSum(dynFilterMap(previous, line, f, bytewidth)), f);

                buffer ~= bestFilter;
                buffer ~= dynFilterMap(previous, line, bestFilter, bytewidth);
            }
        }
        else
        {
            buffer ~= cast(ubyte)filterMethod;
            buffer ~= dynFilterMap(line, cast(ubyte)filterMethod, bytewidth);

            for (int y = 1; y < image.height; y++)
            {
                line = source[scanlength * y..scanlength * y + scanlength];
                previous = source[scanlength * (y - 1)..scanlength * y];

                buffer ~= cast(ubyte)filterMethod;
                buffer ~= dynFilterMap(line, cast(ubyte)filterMethod, bytewidth);
            }
        }
        return buffer;
    }

    bool opaqueOrColorkey(in ubyte[] image, in PngInfo info, out ubyte[] colorKey)
    {
        if (info.image.colorType == ColorType.Greyscale || info.image.colorType == ColorType.RGB)
            return false;
        else if (info.image.colorType == ColorType.RGBA )
        {
            uint numpixels = info.image.width * info.image.height;

            ubyte[3] ckey;
            bool hasCkey = false;

            for(size_t i = 0; i < numpixels; i++)
            {
                if(image[i * 4 + 3] != 255)
                {
                    if(image[i * 4 + 3] == 0)
                    {
                        if (hasCkey)
                        {
                            if (ckey[0] != image[i * 4] || ckey[1] != image[i * 4 + 1] ||
                                ckey[2] != image[i * 4 + 2] )
                                return false;
                        }
                        else
                        {
                            hasCkey = true;
                            ckey[0..2] = image[i * 4 .. i * 4 + 2];
                        }
                    }
                    else
                        return false;
                }
            }
            if (hasCkey)
            {
                colorKey = new ubyte[6];
                colorKey[1] = ckey[0];
                colorKey[3] = ckey[1];
                colorKey[5] = ckey[2];
            }
            return true;
        }
        else if(info.image.colorType == ColorType.GreyscaleAlpha)
        {
            size_t numpixels = image.length / 2;

            ubyte[1] ckey;
            bool hasCkey = false;

            for(size_t i = 0; i < numpixels; i++)
            {
                if(image[i * 2 + 1] != 255)
                {
                    if (hasCkey)
                    {
                        if (ckey[0] != image[i * 2])
                            return false;
                    }
                    else
                    {
                        hasCkey = true;
                        ckey[0] = image[i * 2];
                    }
                }
            }
            if (hasCkey)
            {
                colorKey = new ubyte[2];
                colorKey[1] = ckey[0];
            }
            return true;
        }
        else if (info.image.colorType == ColorType.Palette)
        {
            // TODO: implement this (compression optimization)
            return false;
        }
    }

    ubyte[] headerData(PngImage image)
    {
        ubyte[] header = new ubyte[13];
        header.length = 0;

        header.concatUint(image.width);
        header.concatUint(image.height);
        header ~= image.bitDepth;
        header ~= image.colorType;
        header ~= 0; //compression method
        header ~= 0; //filter method
        header ~= 0; //interlace method

        return header;
    }

    void concatUint(inout ubyte[] bytestream, uint num)
    {
        bytestream.length = bytestream.length + 4;
        bytestream[$-4] = num >> 24;
        bytestream[$-3] = num >> 16;
        bytestream[$-2] = num >> 8;
        bytestream[$-1] = num;
    }

    void writeChunk(inout ubyte[] bytestream, ref Chunk chunk)
    {
        bytestream.concatUint(chunk.data.length);

        bytestream.length = bytestream.length + 4;
        bytestream[$-4] = (chunk.type & 0xff000000) >> 24 ;
        bytestream[$-3] = (chunk.type & 0x00ff0000) >> 16;
        bytestream[$-2] = (chunk.type & 0x0000ff00) >> 8;
        bytestream[$-1] =  chunk.type & 0x000000ff;

        bytestream.length = bytestream.length + chunk.data.length;
        bytestream[$ - chunk.data.length..$] = chunk.data;

        uint CRC = createCRC(bytestream[$ - chunk.data.length - 4.. $]);
        bytestream.concatUint(CRC);
    }

    void writeSignature(inout ubyte[] byteStream)
    {
        byteStream ~= [137, 80, 78, 71, 13, 10, 26, 10];
    }

    /++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        From the png spec: pixels for filtering are defined as follows such, where x is the current
        being filtered and c, b correspond to the previous scanline:
            c b
            a x

    filters:    construction                                                    Reconstruction
    0	None	Filt(x) = Orig(x) 	                                            Recon(x) = Filt(x)
    1	Sub	    Filt(x) = Orig(x) - Orig(a) 	                                Recon(x) = Filt(x) + Recon(a)
    2	Up	    Filt(x) = Orig(x) - Orig(b) 	                                Recon(x) = Filt(x) + Recon(b)
    3	Average	Filt(x) = Orig(x) - floor((Orig(a) + Orig(b)) / 2) 	            Recon(x) = Filt(x) + floor((Recon(a) + Recon(b)) / 2)
    4	Paeth	Filt(x) = Orig(x) - PaethPredictor(Orig(a), Orig(b), Orig(c))   Recon(x) = Filt(x) + PaethPredictor(Recon(a), Recon(b), Recon(c)
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++/
    ubyte None      (ubyte c, ubyte b, ubyte a, ubyte x) { return x; }
    ubyte Sub       (ubyte c, ubyte b, ubyte a, ubyte x) { return x - a; }
    ubyte Up        (ubyte c, ubyte b, ubyte a, ubyte x) { return x - b; }
    ubyte Average   (ubyte c, ubyte b, ubyte a, ubyte x) { return x - (a + b) / 2; }
    ubyte Paeth     (ubyte c, ubyte b, ubyte a, ubyte x) { return x - paethPredictor(a,b,c); }

    /*  map for filtering. seq1 contains the previous scanline and seq2 the current
    *   pixels are passed in the order they appear in the serialized image (left to right, top to bottom)
    */
    ubyte[] filterMap(T)(ubyte[] seq1, ubyte[] seq2, T op, uint bytewidth)
    {
        ubyte[] result;
        result.length = seq1.length < seq2.length ? seq1.length : seq2.length;

        auto bw = bytewidth;
        while (bw--)
            result[bw] = op(0, seq1[bw], 0, seq2[bw]);
        for (int i = bytewidth; i < result.length; i++)
            result[i] = op(seq1[i - bytewidth], seq1[i], seq2[i - bytewidth], seq2[i]);
        return result;
    }

    /*  see filterMap above, this is a special case for the top scanline, where pixels from the
    *   previous scanline are set to zero
    */
    ubyte[] filterMap(T)(ubyte[] seq, T op, uint bytewidth)
    {
        ubyte[] result;
        result.length = seq.length;

        auto bw = bytewidth;
        while (bw--)
            result[bw] = op(0, 0, 0, seq[bw]);
        for (int i = bytewidth; i < result.length; i++)
            result[i] = op(0, 0, seq[i - bytewidth], seq[i]);
        return result;
    }

    ubyte[] dynFilterMap(ubyte[] seq1, ubyte[] seq2, ubyte fOp, uint bytewidth)
    {
        switch(fOp)
        {
            case 0: return filterMap(seq1,seq2, &None, bytewidth);
            case 1:	return filterMap(seq1,seq2, &Sub, bytewidth);
            case 2: return filterMap(seq1,seq2, &Up, bytewidth);
            case 3: return filterMap(seq1,seq2, &Average, bytewidth);
            case 4: return filterMap(seq1,seq2, &Paeth, bytewidth);
            default:
                mixin(pngEnforce(`false`, "wrong png filter"));
            break;
        }
    }

    ubyte[] dynFilterMap(ubyte[] seq, ubyte fOp, uint bytewidth)
    {
        switch(fOp)
        {
            case 0: return filterMap(seq, &None, bytewidth);
            case 1: return filterMap(seq, &Sub, bytewidth);
            case 2: return filterMap(seq, &Up, bytewidth);
            case 3: return filterMap(seq, &Average, bytewidth);
            case 4: return filterMap(seq, &Paeth, bytewidth);
            default:
                mixin(pngEnforce(`false`, "wrong png filter"));
            break;
        }
    }
}

