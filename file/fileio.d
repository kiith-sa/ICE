module file.fileio;


import std.file;
import std.c.stdio;
import std.string;

public import file.file;
import memory.memory;


public:
    ///Add a mod directory (subdirectory of ./data/) to read data from. 
    /**
     * Directories added later take precedence over directories
     * added before, e.g., if we add 3 directories, "main", "mod1" and "mod2",
     * file "file.txt" will be first searched for as "./data/mod2/file.txt",
     * then "./data/mod1/file.txt" and finally "./data/main/file.txt"
     *
     * If the directory name is invalid or the directory doesn't exist, an Exception
     * is thrown. Only lowercase letters, numbers and the '_' character are allowed
     * in mod directory names.
     */
    void add_mod_directory(string directory)
    {
        if(!valid_directory(directory) || !exists(root_ ~ "/" ~ directory))
        {
            throw new Exception("Invalid data subdirectory: " ~ directory ~
                                " Only lowercase ASCII alphanumeric characters and _"
                                "are allowed.");
        }
        mod_directories_ ~= directory;
    }

    ///Open a file with given name and mode.
    /**
     * Files are searched for in known ./data/ subdirectories, e.g. if "main" and "mod"
     * are known subdirectories, file "file.txt" is first searched for in "./data/mod"
     * and the "./data/main". Alternatively, subdirectory can be specified explicitly,
     * e.g. "mod::file.txt" will always open "./data/mod/file.txt" .
     * In case of an error, an Exception will be thrown.
     * Reading a file that doesn't exist is an error.
     * Also, file name for writing and appending must explicitly set mod directory
     * (e.g. mod::file.txt).
     */
    File open_file(string name, FileMode mode)
    {
        bool exists;
        string path = get_path(name, exists);
        switch(mode)
        {
            case FileMode.Read:
                //get the file path
                if(!exists)
                {
                    throw new Exception("File requested for reading does not exist: "
                                        ~ name ~ " path: " ~ path);
                }
                //load file into memory
                return load_file(name, path, mode);
            case FileMode.Write, FileMode.Append:
                if(name.find("::") < 0)
                {
                    throw new Exception("File path for writing and/or appending "
                                        "must be specified explicitly");
                }
                return File(name, path, mode, 0, write_reserve_);
            default:
                assert(false, "Unsupported file mode");
        }
    }

    ///Close a file. This will write out any changes and delete any buffers.
    void close_file(File file)
    {
        FILE* handle;
        //destroy the file object at exit
        scope(exit){file.die();}

        switch(file.mode_)
        {
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

        assert(file.write_used_ <= uint.max, 
               "Writing over 4GiB files is not yet supported.");

        int blocks_written = fwrite(file.write_data_.ptr, 
                                    cast(uint)file.write_used_, 1, handle);
        if(blocks_written == 0)
        {
            throw new Exception("Couldn't write to file " ~ file.path_ ~ 
                                " Maybe you don't have sufficient rights to write "
                                "to that file");
        }
    }

    static this()
    {
        if(!exists(root_ ~ "/main"))
        {
            throw new Exception("Main data directory doesn't exist");
        }
        add_mod_directory("main");
    }

private:
    //Default amount of bytes to reserve for file writing buffers - to prevent
    //frequent reallocations.
    const write_reserve_ = 4096;

    //known (added) mod directories.
    string[] mod_directories_;

    //directory mod directories are in.
    string root_ = "./data";
    
    //Convert an in-engine filename to real file path and determine if the file exists.
    string get_path(string file_name, out bool file_exists)
    {
        string[] parts = file_name.split("::");
        string path;
        //can't have nested absolute mod directory specifiers
        if(parts.length > 2)
        {
            throw new Exception("Invalid file name: " ~ file_name);
        }
        //absolute mod directory in the file name (e.g. mod::fonts/font.ttf)
        else if(parts.length == 2)
        {
            path = root_ ~ "/" ~ parts[0];
            //does the mod directory exist?
            if(!exists(path))
            {
                throw new Exception("File name with invalid mod directory: " 
                                    ~ file_name);
            }
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

    //Validate a name of a mod directory.
    bool valid_directory(string directory)
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

    //Load a file with specified parameters from specified path.
    File load_file(string name, string path, FileMode mode)
    in
    {
        assert(mode == FileMode.Read, "Can't load a file with mode other than reading");
    }
    body
    {
        ulong size = getSize(path);
        assert(size <= uint.max, "Reading over 4GiB files not yet supported");

        //create a file object with allocated data_ buffer
        File file = File(name, path, mode, size, 0);
        scope(failure){file.die();}
        
        //don't need to read if the file is empty
        if(size == 0){return file;}

        FILE* handle = fopen(toStringz(path), "rb");
        //read to file
        size_t blocks_read = fread(file.data_.ptr, cast(uint)size, 1, handle);
        fclose(handle);

        if(blocks_read == 0)
        {
            throw new Exception("Could open but could not read file: " ~ path ~
                                " File might be corrupted or you might not have "
                                "sufficient rights to read from it.");
        }
        return file;
    }
