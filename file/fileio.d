
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///File I/O utility functions.
module file.fileio;
@trusted


import core.stdc.stdio;

import std.exception;
import std.file;
import std.string;

public import file.file;
import memory.memory;


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
void add_mod_directory(in string directory)
{
    enforceEx!FileIOException
              (valid_mod_directory(directory),
              "Invalid data subdirectory: " ~ directory ~ " Only lowercase ASCII "
              "alphanumeric characters and '_' are allowed.");
    enforceEx!FileIOException
              (exists(root_ ~ "/" ~ directory) || exists(user_root_ ~ "/" ~ directory)
               , "Mod directory not found: " ~ directory);

    mod_directories_ ~= directory;
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
void ensure_directory_user(in string name)
{
    enforceEx!FileIOException
              (name.indexOf("::") >= 0, "Mod directory for directory creation not specified");
    try
    {
        string path = get_path_write(name);

        if(!exists(path))
        {
            mkdir(path);
            return;
        }
        enforceEx!(FileIOException)
                  (isDir(path), 
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
bool file_exists_user(in string name){return cast(bool)exists(get_path_write(name));}

/**
 * Set root data directory. Must be called exactly once at startup.
 *
 * Params:  root_data = Root data directory to set. 
 *
 * Throws:  FileIOException if the directory does not exist or is invalid.
 */
void root_data(in string root_data)
{
    root_ = root_data;
    const path = root_ ~ "/main";
    enforceEx!FileIOException
              (exists(path) && isDir(path), "Root data directory doesn't exist");
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
void user_data(in string user_data)
{
    user_root_ = user_data;
    const path = user_root_ ~ "/main";
    try
    {
        if(!exists(user_root_)){mkdir(user_root_);}
        if(!exists(path)){mkdir(path);}
    }
    catch(FileException e)
    {
        throw new FileIOException("Could not create directory: " ~ path ~ " " ~ e.msg);
    }
    enforceEx!FileIOException(isDir(path), "User data directory is not a directory");
}

package:
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
string get_path_read(in string file_name)
{
    const string[] parts = file_name.split("::");
    //can't have nested mod directory specifiers
    enforceEx!FileIOException(parts.length <= 2, "Invalid file name (reading): " ~ file_name);

    //mod directory specified
    if(parts.length == 2) foreach(root; [user_root_, root_])
    {
        const path = root ~ "/" ~ parts[0] ~ "/" ~ parts[1];
        if(exists(path)){return path;}
    }
    //mod directory not specified; look for the file in mod directories
    else foreach_reverse(dir; mod_directories_)
    {
        //try in user data, root data
        foreach(root; [user_root_, root_])
        {
            const path = root ~ "/" ~ dir ~ "/" ~ file_name;
            if(exists(path)){return path;}
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
string get_path_write(in string file_name)
{
    const string[] parts = file_name.split("::");
    //can't have nested mod directory specifiers
    enforceEx!FileIOException(parts.length == 2, "Invalid file name (writing): " ~ file_name);
    
    enforceEx!FileException(exists(user_root_ ~ "/" ~ parts[0]),
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
bool valid_mod_directory(in string directory)
{
    //only lowercase, digits and _ are allowed
    foreach(dchar c; directory)
    {
        if(!(inPattern(c, lowercase) || inPattern(c, digits) || c == '_'))
        {
            return false;
        }
    }
    return true;
}
