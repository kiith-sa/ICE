
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Image encoding/decoding.
module formats.image;


import std.string;
import std.stdio;

import dgamevfs._;

import formats.png;
import memory.memory;
import image;
import color;


///Exception thrown at errors related to image files.
class ImageFileException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @trusted nothrow 
    {
        super(msg, file, line);
    }
}

///Image file formats, e.g. PNG, GIF, etc.
enum ImageFileFormat
{
    ///PNG (Portable Network Graphics).
    PNG,
    ///Automatic file format detection based on file extension (.png for PNG files).
    Auto
}

/**
 * Write an image to file.
 *
 * Params:  image      = Image to write.
 *          fileName   = File to write into.
 *          fileFormat = Image file format. Autodetected by default.
 *                       If the format can't be autodetected, PNG format is used.
 *
 * PNG is the only supported format at the moment (more formats may or may not be
 * added in future). Also, only 24-bit RGB and 32-bit RGBA color formats are supported
 * at the moment.
 *
 * Throws:  VFSException if the image could not be written.
 *          ImageFileException in the case of an encoding error, if the color format is not 
 *          supported or file format could not be detected in case of autodetection.
 */
void writeImage(const ref Image image, VFSFile file,
                ImageFileFormat fileFormat = ImageFileFormat.Auto)
{
    scope(failure){writeln("Image writing failed: " ~ file.name);}

    if(fileFormat == ImageFileFormat.Auto)
    {
        fileFormat = detectImageFormat(file.name);
    }

    try
    {
        if(fileFormat == ImageFileFormat.PNG)
        {
            ubyte[] data = encodePNG(image.data, image.width, image.height, image.format);
            file.output.write(cast(void[])data);
            free(data);
        }
        else{assert(false, "Unsupported image file format for writing");}
    }
    catch(ImageFileException e)
    {
        throw new ImageFileException("Image encoding error:" ~ e.msg);
    }
}

/**
 * Read an image from a file.
 *
 * Params:  image      = Image to read to. Any existing contents will be cleared.
 *          fileName   = File to read from.
 *          fileFormat = Image file format. Autodetected by default.
 *                       If the format can't be autodetected, PNG format is used.
 *
 * PNG is the only supported format at the moment (more formats may or may not be
 * added in future). Also, only 8-bit grayscale, 24-bit RGB and 32-bit RGBA color 
 * formats are supported at the moment.
 *
 * Throws:  VFSException if the file could not be read from.
 *          ImageFileException if image data was invalid.
 */
void readImage(ref Image image, VFSFile file,
               ImageFileFormat fileFormat = ImageFileFormat.Auto)
{
    scope(failure){writeln("Image reading failed: " ~ file.name);}

    if(fileFormat == ImageFileFormat.Auto)
    {
        fileFormat = detectImageFormat(file.name);
    }

    try
    {
        //parameters of the loaded image will be written here
        uint width, height;
        ColorFormat format;

        ubyte[] imageData = null;

        if(fileFormat == ImageFileFormat.PNG)
        {
            auto rawData = allocArray!ubyte(cast(size_t)file.bytes);
            scope(exit) {free(rawData);}
            file.input.read(cast(void[])rawData);
            imageData = decodePNG(rawData, width, height, format);
        }
        else{assert(false, "Unsupported image file format for reading");}

        assert(imageData !is null, "No image data read");

        clear(image);
        image = Image(width, height, format);
        image.dataUnsafe[] = imageData;
        free(imageData);
    }
    catch(ImageFileException e)
    {
        const error = "Error decoding image: " ~ e.msg;
        writeln(error);
        throw(new ImageFileException(error));
    }
}

private:
/**
 * Determine file format from file name extension.
 *
 * Params:  fileName = File name to determine file format from.
 *          
 * Returns: Format detected, or PNG if could not detect.
 */
ImageFileFormat detectImageFormat(const string fileName)
{ 
    const extension = fileName.split(".")[$ - 1];
    return extension.icmp("png") ? ImageFileFormat.PNG : ImageFileFormat.PNG;
}
