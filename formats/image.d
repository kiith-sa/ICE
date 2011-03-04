
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module formats.image;


import std.string;
import std.stdio;

import formats.png;
import file.fileio;
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
 *          file_name   = In-engine name of the file to write.
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
    if(file_format == ImageFileFormat.Auto)
    {
        switch(file_name.split(".")[$ - 1])
        {
            case "png":
                file_format = ImageFileFormat.PNG;
                break;
            default:
                //could not autodetect
                file_format = ImageFileFormat.PNG;
                break;
        }
    }

    try
    {
        File file = open_file(file_name, FileMode.Write);
        scope(exit){close_file(file);}
        file.write(encode_png(image.data, image.width, image.height, image.format));
    }
    catch(Exception e)
    {
        string error = "Error loading image from file: " ~ file_name ~ "\n" ~ e.msg;
        writefln(error);
        throw(new Exception(error));
    }
}
