
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module file.fileio;


import std.c.stdio;

import std.file;
import std.string;

public import file.file;
import memory.memory;
import util.exception;


///Exception thrown at file errors.
class FileIOException : Exception{this(string msg){super(msg);}} 

/**
 * Add a mod directory (subdirectory of ./data/) to read data from. 
 *
 * Directories added later take precedence over directories
 * added before, e.g., if we add 3 directories, "main", "mod1" and "mod2",
 * file "file.txt" will be first searched for as "./data/mod2/file.txt",
 * then "./data/mod1/file.txt" and finally "./data/main/file.txt"
 *
 * Only lowercase letters, numbers and the '_' character are legal in mod directory names.
 *
 * Params:  directory = Mod directory to add.
 *
 * Throws:  FileIOException on if the directory name is invalid or it does not exist.
 */
void add_mod_directory(string directory)
{
    enforceEx!(FileIOException)
              (valid_directory(directory),
              "Invalid data subdirectory: " ~ directory ~ " Only lowercase ASCII "
              "alphanumeric characters and '_' are allowed.");
    enforceEx!(FileIOException)
              (exists(root_ ~ "/" ~ directory), "Mod directory not found: " ~ directory);

    mod_directories_ ~= directory;
}

/**
 * Open a file with given name and mode.
 *
 * Files are searched for in known ./data/ subdirectories, e.g. if "main" and "mod"
 * are known subdirectories, file "file.txt" is first searched for in "./data/mod"
 * and the "./data/main". Alternatively, subdirectory can be specified explicitly,
 * e.g. "mod::file.txt" will always open "./data/mod/file.txt" .
 * Reading a file that doesn't exist is an error.
 * For writing and appending, mod directory must be explicitly set.
 * (e.g. mod::file.txt).
 *
 * Params:  name = In-engine name of the file to open. For writing or appending,
 *                 mod directory must be specified.
 *          mode = File mode to open the file in.
 *
 * Returns: File opened.
 *
 * Throws:  FileIOException if the file to read could not be found, file name is invalid 
 *                          or the mod directory was not specified for writing/appending.
 *
 * Examples:
 * --------------------
 * //Read fonts/Font42.ttf from any mod directory (depending on font directories' order).
 * File file = open_file("fonts/Font42.ttf", FileMode.Read); 
 * //don't forget to close the file
 * scope(exit){close_file(file);}
 * --------------------
 *
 * --------------------
 * //Read fonts/Font42.ttf from "main" directory.
 * File file = open_file("main::fonts/Font42.ttf", FileMode.Read); 
 * //don't forget to close the file
 * scope(exit){close_file(file);}
 * --------------------
 *
 * --------------------
 * //ERROR: must specify mod directory for writing.
 * File file = open_file("fonts/Font42.ttf, FileMode.Write"); 
 * //don't forget to close the file
 * scope(exit){close_file(file);}
 * --------------------
 *
 * --------------------
 * //Open fonts/Font42.ttf from the "main" directory for writing.
 * File file = open_file("main::fonts/Font42.ttf, FileMode.Write"); 
 * //don't forget to close the file
 * scope(exit){close_file(file);}
 * --------------------
 */
File open_file(string name, FileMode mode)
{
    bool exists;
    //get the file path
    string path = get_path(name, exists);
    switch(mode)
    {
        case FileMode.Read:
            enforceEx!(FileIOException) 
                      (exists, "File to read not found: " ~ name ~ " path: " ~ path);
            //load file into memory
            return load_file(name, path);
        case FileMode.Write, FileMode.Append:
            enforceEx!(FileIOException) 
                      (name.find("::") >= 0, "Mod directory for writing and/or appending "
                                             "not specified");
            return File(name, path, mode, 0, write_reserve_);
        default:
            assert(false, "Unsupported file mode");
    }
}

/**
 * Close a file. This will write out any changes and delete any buffers.
 * 
 * Params:  file = File to close.
 * 
 * Throws:  FileIOException if the buffers couldn't be written out in append or write mode.
 */
void close_file(File file)
{
    FILE* handle;
    //destroy the file object at exit
    scope(exit){file.die();}

    switch(file.mode_)
    {
        //nothing to write in read mode
        case FileMode.Read:
            return;
        case FileMode.Write:
            handle = fopen(toStringz(file.path_), "wb");
            break;
        case FileMode.Append:
            handle = fopen(toStringz(file.path_), "ab");
            break;
        default:
            assert(false, "Unsupported file mode");
    }

    //close the file at exit
    scope(exit){fclose(handle);}
    //nothing to write
    if(file.write_used_ == 0){return;}

    assert(file.write_used_ <= uint.max, "Writing over 4GiB files is not yet supported.");

    int blocks_written = fwrite(file.write_data_.ptr, 
                                cast(uint)file.write_used_, 1, handle);

    enforceEx!(FileIOException)
              (blocks_written == 1, "Couldn't write to file " ~ file.path_ ~ " Maybe you " ~ 
                                    "don't have sufficient rights");
}

/**
 * Ensure a directory exists. Will create the directory if it doesn't.
 *
 * Params:  name = In-engine name of the directory.
 *
 * Throws:  FileIOException if the mod directory is not specified, name is invalid, file with 
 *                          specified name exists that is not a directory or it couldn't be 
 *                          created.
 */
void ensure_directory(string name)
{
    enforceEx!(FileIOException)(name.find("::") >= 0, 
                          "Mod directory for directory creation not specified");
    try
    {
        bool exists;
        string path = get_path(name, exists);
        if(!exists)
        {
            mkdir(path);
            return;
        }
        enforceEx!(FileIOException)
                  (isdir(path), "File with specified name exists but is not a directory");
    }
    catch(FileException e)
    {
        throw new FileIOException("Directory could not be created: " ~ e.msg);
    }
}

/**
 * Does the specified file(directory) exist?
 *
 * Params:  name = In-engine file name.
 *
 * Returns: True if the file(directory) exists, false otherwise.
 *
 * Throws:  FileIOException if the file name is invalid.
 */
bool file_exists(string name)
{
    bool exists;
    string dummy = get_path(name, exists);
    return exists;
}

private:
///Default amount of bytes to reserve for file writing buffers - to prevent
///frequent reallocations.
const write_reserve_ = 4096;

///known (added) mod directories.
string[] mod_directories_;

///directory mod directories are in.
string root_ = "./data";

/**
 * Static constructor. Adds the main data directory.
 *
 * Throws:  FileIOException if the main directory does not exist.
 */
static this()
{
    enforceEx!(FileIOException)(exists(root_ ~ "/main"), "Main data directory doesn't exist");
    add_mod_directory("main");
}

/**
 * Convert an in-engine filename to real file path and determine if the file exists.
 *
 * Params:  file_name   = In-engine file name.
 *          file_exists = If the file exists, true will be written here, false otherwise.
 *
 * Returns: Real filesystem path of the file.
 *
 * Throws:  FileIOException on failure.
 */
string get_path(string file_name, out bool file_exists)
{
    string[] parts = file_name.split("::");
    string path;
    //can't have nested absolute mod directory specifiers
    enforceEx!(FileIOException)(parts.length <= 2, "Invalid file name: " ~ file_name);
    //absolute mod directory in the file name (e.g. mod::fonts/font.ttf)
    if(parts.length == 2)
    {
        path = root_ ~ "/" ~ parts[0];
        //does the mod directory exist?
        enforceEx!(FileIOException)
                  (exists(path), "File name with invalid mod directory: " ~ file_name);
        path ~= "/" ~ parts[1];
        file_exists = cast(bool)exists(path);
    }
    //file name contains no directory - look for it in known mod directories
    else
    {
        file_exists = true;
        //look for the file in mod directories
        foreach_reverse(dir; mod_directories_)
        {
            path = root_ ~ "/" ~ dir ~ "/" ~ file_name;
            if(exists(path)){return path;}
        }           
        //file not found anywhere
        file_exists = false;
        //return path in default directory if it doesn't exist anywhere
    }
    return path;
}

/**
 * Validate a name of a mod directory.
 *
 * Params:  directory = Directory name.
 *
 * Returns: True if the directory name is valid, false otherwise.
 */
bool valid_directory(string directory)
{
    //only lowercase, digits and _ are allowed
    foreach(dchar c; directory)
    {
        if(!(inPattern(c, lowercase) || inPattern(c, digits) || c == '_')){return false;}
    }
    return true;
}

/**
 * Load a file from specified path.
 *
 * Params:  name = In-engine name of the file.
 *          path = Actual filesystem path of the file.
 * 
 * Returns: The loaded file.
 *
 * Throws:  FileIOException if the file could not be read.
 */
File load_file(string name, string path)
{
    ulong size = getSize(path);
    assert(size <= uint.max, "Reading over 4GiB files not yet supported");

    //create a file object with allocated data_ buffer
    File file = File(name, path, FileMode.Read, size, 0);
    scope(failure){file.die();}
    
    //don't need to read if the file is empty
    if(size == 0){return file;}

    FILE* handle = fopen(toStringz(path), "rb");
    //read to file
    size_t blocks_read = fread(file.data_.ptr, cast(uint)size, 1, handle);
    fclose(handle);

    enforceEx!(FileIOException)(blocks_read == 1, 
                                "Could open but could not read file: " ~ path ~
                                " File might be corrupted or you might not have "
                                "sufficient rights");
    return file;
}
