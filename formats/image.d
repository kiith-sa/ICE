
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Image encoding/decoding.
module formats.image;
@trusted


import std.string;
import std.stdio;

import formats.png;
import file.fileio;
import memory.memory;
import image;
import color;

private alias file.file.File File;


///Exception thrown at errors related to image files.
class ImageFileException : Exception{this(string msg){super(msg);}} 

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
 * Params:  image       = Image to write.
 *          file_name   = In-engine name of the file to write to.
 *          file_format = Image file format. Autodetected by default.
 *                        If the format can't be autodetected, PNG format is used.
 *
 * PNG is the only supported format at the moment (more formats may or may not be
 * added in future). Also, only 24-bit RGB and 32-bit RGBA color formats are supported
 * at the moment.
 *
 * Throws:  FileIOException if the image could not be written.
 *          ImageFileException in the case of an encoding error, if the color format is not 
 *          supported or file format could not be detected in case of autodetection.
 */
void write_image(const ref Image image, in string file_name, 
                 ImageFileFormat file_format = ImageFileFormat.Auto)
{
    scope(failure){writeln("Image writing failed: " ~ file_name);}

    if(file_format == ImageFileFormat.Auto)
    {
        file_format = detect_image_format(file_name);
    }

    try
    {
        File file = File(file_name, FileMode.Write);
        if(file_format == ImageFileFormat.PNG)
        {
            ubyte[] data = encode_png(image.data, image.width, image.height, image.format);
            file.write(data);
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
 * Params:  image       = Image to read to. Any existing contents will be cleared.
 *          file_name   = In-engine name of the file to read from.
 *          file_format = Image file format. Autodetected by default.
 *                        If the format can't be autodetected, PNG format is used.
 *
 * PNG is the only supported format at the moment (more formats may or may not be
 * added in future). Also, only 8-bit grayscale, 24-bit RGB and 32-bit RGBA color 
 * formats are supported at the moment.
 *
 * Throws:  FileIOException if the file could not be read from.
 *          ImageFileException if image data was invalid.
 */
void read_image(ref Image image, in string file_name, 
                ImageFileFormat file_format = ImageFileFormat.Auto)
{
    scope(failure){writeln("Image reading failed: " ~ file_name);}

    if(file_format == ImageFileFormat.Auto)
    {
        file_format = detect_image_format(file_name);
    }

    try
    {
        File file = File(file_name, FileMode.Read);

        //parameters of the loaded image will be written here
        uint width, height;
        ColorFormat format;

        ubyte[] image_data = null;

        if(file_format == ImageFileFormat.PNG)
        {
            image_data = decode_png(cast(ubyte[])file.data, width, height, format);
        }
        else{assert(false, "Unsupported image file format for reading");}

        assert(image_data !is null, "No image data read");

        clear(image);
        image = Image(width, height, format);
        image.data_unsafe[] = image_data;
        free(image_data);
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
 * Params:  file_name = File name to determine file format from.
 *          
 * Returns: Format detected, or PNG if could not detect.
 */
ImageFileFormat detect_image_format(in string file_name)
{ 
    const extension = file_name.split(".")[$ - 1];
    return extension.icmp("png") ? ImageFileFormat.PNG : ImageFileFormat.PNG;
}
