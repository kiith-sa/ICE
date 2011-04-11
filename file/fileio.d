
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
import containers.array : contains;
import util.exception;


///Exception thrown at file errors.
class FileIOException : Exception{this(string msg){super(msg);}} 

/**
 * Add a mod directory.
 *
 * Directories added later take precedence over directories added before.
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
              (valid_mod_directory(directory),
              "Invalid data subdirectory: " ~ directory ~ " Only lowercase ASCII "
              "alphanumeric characters and '_' are allowed.");
    enforceEx!(FileIOException)
              (exists(root_ ~ "/" ~ directory) || exists(user_root_ ~ "/" ~ directory)
               , "Mod directory not found: " ~ directory);

    mod_directories_ ~= directory;
}

/**
 * Open a file with given name and mode.
 *
 * Files are searched for in mod subdirectories in root and user data directories.
 * If opening a file for reading, it is first searched for in the newest mod directory
 * in user data, then in root data, then in second newest mod directory and so on.
 * If it's not found, a FileIOException is thrown.
 *
 * Alternatively, mod directory can be explicitly specified, like this : "mod::file.ext",
 * which will look only in that subdirectory in user, root data directories.
 * If specified explicitly, the mod directory only needs to exist in root and/or user data,
 * it doesn't need to be registered with add_mod_directory().
 *
 * If the file is opened for writing or appending, the mod directory must be specified
 * and must exist in user data, and the file will be opened whether it already exists or not.
 * Files are always written to user data (root data is read only).
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
    switch(mode)
    {
        case FileMode.Read:
            //load file into memory
            return load_file(name, get_path_read(name));
        case FileMode.Write, FileMode.Append:
            enforceEx!(FileIOException) 
                      (name.find("::") >= 0, "Mod directory for writing and/or appending "
                                             "not specified");
            return File(name, get_path_write(name), mode, 0, write_reserve_);
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

    auto blocks_written = fwrite(file.write_data_.ptr, 
                                 cast(uint)file.write_used_, 1, handle);

    enforceEx!(FileIOException)
              (blocks_written == 1, "Couldn't write to file " ~ file.path_ ~ " Maybe you " ~ 
                                    "don't have sufficient rights");
}

/**
 * Ensure a directory exists in user data. Will create the directory if it doesn't.
 *
 * Mod directory must be specified.
 * 
 * Params:  name = In-engine name of the directory.
 *
 * Throws:  FileIOException if the mod directory is not specified, name is invalid, file with 
 *                          specified file exists that is not a directory or it couldn't be 
 *                          created.
 */
void ensure_directory_user(string name)
{
    enforceEx!(FileIOException)
              (name.find("::") >= 0, "Mod directory for directory creation not specified");
    try
    {
        string path = get_path_write(name);

        if(!exists(path))
        {
            mkdir(path);
            return;
        }
        enforceEx!(FileIOException)
                  (isdir(path), 
                   "File with specified name exists but is not a directory");
    }
    catch(FileException e)
    {
        throw new FileIOException("Could not create directory: " ~ e.msg);
    }
}

/**
 * Does the specified file(directory) exist in user data?
 *
 * Mod directory must be specified.
 *
 * Params:  name = In-engine file name.
 *
 * Returns: True if the file(directory) exists in user data, false otherwise.
 *
 * Throws:  FileIOException if the mod directory is not specified or the
 *          file name is invalid.
 */
bool file_exists_user(string name){return cast(bool)exists(get_path_write(name));}

/**
 * Set root data directory. Must be called exactly once at startup.
 *
 * Params:  root_data = Root data directory to set. 
 *
 * Throws:  FileIOException if the directory does not exist or is invalid.
 */
void root_data(string root_data)
{
    root_ = root_data;
    string path = root_ ~ "/main";
    enforceEx!(FileIOException)
              (exists(path) && isdir(path), "Main data directory (root) doesn't exist");
}

/**
 * Set user data directory. Must be called exactly once at startup. 
 *
 * If the specified directory doesn't exist, it will be created.
 *
 * Params:  user_data = User data directory to set. 
 *
 * Throws:  FileIOException if the path specified exists but is not a directory,
 *          or the user data directory could not be created.
 */
void user_data(string user_data)
{
    user_root_ = user_data;
    string path = user_root_ ~ "/main";
    try
    {
        if(!exists(user_root_)){mkdir(user_root_);}
        if(!exists(path)){mkdir(path);}
    }
    catch(FileException e)
    {
        throw new FileIOException("Could not create directory: " ~ path ~ " " ~ e.msg);
    }
    enforceEx!(FileIOException)(isdir(path), "Main data directory (user) is not a directory");
}

private:
///Default amount of bytes to reserve for file writing buffers - to prevent
///frequent reallocations.
const write_reserve_ = 4096;

///known (added) mod directories.
string[] mod_directories_ = ["main"];

/**
 * Main game data directory. This directory contains default game data.
 * 
 * E.g. on Linux this could be /usr/local/share/xxx . This directory is read only.
 */
string root_ = "./data";

/**
 * User data directory. This directory containg saves, screenshots and other writable data.
 * 
 * Files in user data directory override files in root data directory,
 * i.e. if the same file exists in user data and root data, the one from user data is read.
 * 
 * E.g. on Linux this could be /home/user/.xxx .
 */
string user_root_ = "./user_data";

/**
 * Get filesystem path for reading.
 *
 * If the mod directory is specified explicitly, this will look for the file
 * first in user data and then in root data, and return first match or throw
 * if not found.
 *
 * If the mod directory is not specified, it will look in each mod directory
 * from newest to oldest, both in user and root data and return the first match,
 * or throw if not found.
 *
 * Params:  file_name = In-engine file name to get path for.
 *
 * Returns: Path corresponding to the file name.
 *
 * Throws:  FileIOException if the file was not found anywhere or the file name is invalid,
 */
string get_path_read(string file_name)
{
    string[] parts = file_name.split("::");
    //can't have nested mod directory specifiers
    enforceEx!(FileIOException)(parts.length <= 2, "Invalid file name (reading): " ~ file_name);

    //mod directory specified
    if(parts.length == 2)
    {
        foreach(root; [user_root_, root_])
        {
            string path = root ~ "/" ~ parts[0] ~ "/" ~ parts[1];
            if(exists(path)){return path;}
        }
    }
    //mod directory not specified
    else
    {
        //look for the file in mod directories
        foreach_reverse(dir; mod_directories_)
        {
            //try in user data, root data
            foreach(root; [user_root_, root_])
            {
                string path = root ~ "/" ~ dir ~ "/" ~ file_name;
                if(exists(path)){return path;}
            }
        }           
    }
    throw new FileIOException("File to read does not exist: " ~ file_name);
}

/**
 * Get filesystem path for writing.
 * 
 * Mod directory must be specified. Also, the specified directory must exist,
 * although it doesn't need to be a registered mod directory - it only needs to
 * be a subdirectory of user data directory.
 *
 * The path will be returned whether or not a file with that path already exists.
 *
 * Params:  file_name = In-engine file name to get path for.
 *
 * Returns: Path corresponding to the file name.
 *
 * Throws: FileIOException if the mod directory is not specified or does not exist,
 *         or the file name is invalid.
 */
string get_path_write(string file_name)
{
    string[] parts = file_name.split("::");
    //can't have nested mod directory specifiers
    enforceEx!(FileIOException)(parts.length == 2, "Invalid file name (writing): " ~ file_name);
    
    enforceEx!(FileException)(exists(user_root_ ~ "/" ~ parts[0]),
                              "File name with invalid mod directory: " ~ file_name);

    return user_root_ ~ "/" ~ parts[0] ~ "/" ~ parts[1];
}

/**
 * Validate a name of a mod directory.
 *
 * Params:  directory = Directory name.
 *
 * Returns: True if the directory name is valid, false otherwise.
 */
bool valid_mod_directory(string directory)
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
