
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.image;


import std.string;
import std.stdio;

import formats.png;
import file.fileio;
import memory.memory;
import image;
import color;


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
 * Throws:  Exception if the file could not be written, the color format is not 
 *          supported or file format could not be detected in case of autodetection.
 */
void write_image(Image image, string file_name, 
                 ImageFileFormat file_format = ImageFileFormat.Auto)
{
    if(file_format == ImageFileFormat.Auto){file_format = detect_image_format(file_name);}
    try
    {
        File file = open_file(file_name, FileMode.Write);
        scope(exit){close_file(file);}
        if(file_format == ImageFileFormat.PNG)
        {
            ubyte[] data = encode_png(image.data, image.width, image.height, image.format);
            file.write(data);
            free(data);
        }
        else{assert(false, "Unsupported image file format for writing");}
    }
    catch(Exception e)
    {
        string error = "Error writing image to file: " ~ file_name ~ "\n" ~ e.msg;
        writefln(error);
        throw(new Exception(error));
    }
}

/**
 * Read an image from a file.
 *
 * Params:  file_name   = In-engine name of the file to read from.
 *          file_format = Image file format. Autodetected by default.
 *                        If the format can't be autodetected, PNG format is used.
 *
 * PNG is the only supported format at the moment (more formats may or may not be
 * added in future). Also, only 8-bit grayscale, 24-bit RGB and 32-bit RGBA color 
 * formats are supported at the moment.
 *
 * Throws:  Exception if the file could not be read from or the PNG data was invalid.
 */
Image read_image(string file_name, ImageFileFormat file_format = ImageFileFormat.Auto)
{
    if(file_format == ImageFileFormat.Auto){file_format = detect_image_format(file_name);}
    try
    {
        File file = open_file(file_name, FileMode.Read);
        scope(exit){close_file(file);}

        //parameters of the loaded image will be written here
        uint width, height;
        ColorFormat format;

        ubyte[] image_data = null;

        if(file_format == ImageFileFormat.PNG)
        {
            image_data = decode_png(cast(ubyte[])file.data, width, height, format);
        }
        else{assert(false, "Unsupported image file format for reading");}

        Image image = new Image(width, height, format);
        image.data[] = image_data;
        if(image_data !is null){free(image_data);}
        return image;
    }
    catch(Exception e)
    {
        string error = "Error reading image from file: " ~ file_name ~ "\n" ~ e.msg;
        writefln(error);
        throw(new Exception(error));
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
ImageFileFormat detect_image_format(string file_name)
{ 
    string extension = file_name.split(".")[$ - 1];
    return extension.icmp("png") ? ImageFileFormat.PNG : ImageFileFormat.PNG;
}
