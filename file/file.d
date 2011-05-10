
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///File I/O struct.
module file.file;
@trusted


import std.c.stdio;

import std.algorithm;
import std.exception;
import std.file;
import std.string;

import file.fileio;
import memory.memory;
import math.math;


///File open modes.
enum FileMode
{
    ///Reading
    Read,
    ///Writing (overwriting if file exists)
    Write,
    ///Appending
    Append
}

/**
 * Used to read from and write to files.
 *
 * Mostly manipulated by functions in the file package, not with its own methods.
 */
struct File
{
    private:
        alias std.string.indexOf indexOf;
    package:
        ///In-engine file name, such as fonts/font.ttf or mod::fonts/font.ttf .
        string name_;
        ///Actual file path in the real filesystem.
        string path_;
        ///Mode the file was opened with.
        FileMode mode_;
        ///File contents loaded into memory in read mode: manually allocated.
        ubyte[] data_;

        ///Number of used bytes in write_data_ .
        uint write_used_;
        ///Data to write to file: manually allocated, reallocated if not sufficient.
        ubyte[] write_data_;

    public:
        /**
         * Open a file with given name and mode.
         *
         * The file will be closed when its destructor is called,
         * e.g. when it goes out of scope.
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
         * Throws:  FileIOException if the file to read could not be found, file name is invalid 
         *                          or the mod directory was not specified for writing/appending.
         *
         * Examples:
         * --------------------
         * //Read fonts/Font42.ttf from any mod directory (depending on font directories' order).
         * File file = File("fonts/Font42.ttf", FileMode.Read); 
         * //will be closed at the end of scope
         * --------------------
         *
         * --------------------
         * //Read fonts/Font42.ttf from "main" directory.
         * File file = File("main::fonts/Font42.ttf", FileMode.Read); 
         * //will be closed at the end of scope
         * --------------------
         *
         * --------------------
         * //ERROR: must specify mod directory for writing.
         * File file = File("fonts/Font42.ttf, FileMode.Write"); 
         * //will be closed at the end of scope
         * --------------------
         *
         * --------------------
         * //Open fonts/Font42.ttf from the "main" directory for writing.
         * File file = File("main::fonts/Font42.ttf, FileMode.Write"); 
         * //will be closed at the end of scope
         * --------------------
         */
        this(in string name, in FileMode mode)
        {
            name_ = name;
            mode_ = mode;
            switch(mode)
            {
                case FileMode.Read:
                    path_ = get_path_read(name);
                    //load file into memory
                    load();
                    break;
                case FileMode.Write, FileMode.Append:
                    enforceEx!(FileIOException) 
                              (name.indexOf("::") >= 0, "Mod directory for writing and/or appending "
                                                        "not specified");
                    path_ = get_path_write(name);
                    write_data_ = alloc_array!(ubyte)(write_reserve_);
                    break;
                default:
                    assert(false, "Unsupported file mode");
            }
        }

        ///Close the file.
        ~this()
        {
            if(mode_ == FileMode.Write || mode_ == FileMode.Append){write_out();}
            if(data_ !is null){free(data_);}
            if(write_data_ !is null){free(write_data_);}
            data_ = write_data_ = null;
        }

        ///Access data of a loaded file (only applicable in Read mode).
        @property const void[] data() const
        in
        {
            assert(mode_ == FileMode.Read, 
                   "Can only read data from a file opened for reading");
        }
        body{return cast(void[])data_;}

        ///Get OS filesystem path of the file.
        @property string path() const {return path_;}

        ///Get file mode.
        @property FileMode mode() const {return mode_;}

        /**
         * Write data to file (only applicable in Write, Append modes).
         * 
         * This does not necessarily write data out to the file,
         * data might be buffered until the file is closed.
         */
        void write(in void[] data)
        in
        {
            assert(mode_ != FileMode.Read, "Can't write to a file opened for reading");
            assert(write_data_ !is null, "Trying to read from a closed file");
        }
        body
        {
            const data_bytes = cast(ubyte[])data;
            const needed = write_used_ + data_bytes.length;
            const allocated = write_data_.length;

            //reallocate if not enough space
            if(needed > allocated)
            {
                write_data_ = realloc(write_data_, cast(uint)max(needed, allocated * 2));
            }

            write_data_[cast(uint)write_used_ .. cast(uint)needed] = data_bytes[];
            write_used_ = cast(uint)needed;
        }

    private:
        ///Load the file into memory. Should only be called by the constructor.
        void load()
        in
        {
            assert(mode_ == FileMode.Read, "Can only load a file in Read file mode");
        }
        body
        {
            const size = getSize(path_);
            assert(size <= uint.max, "Reading files over 4GiB not supported");

            data_ = alloc_array!(ubyte)(cast(uint)size);

            //create a file object with allocated data_ buffer
            scope(failure){free(data_);}
            
            //don't need to read if the file is empty
            if(size == 0){return;}

            FILE* handle = fopen(toStringz(path_), "rb");
            enforceEx!(FileIOException)(handle !is null, 
                                        "Could not open file " ~ path_ ~ " for reading");

            //read to file
            const blocks_read = fread(data_.ptr, cast(uint)size, 1u, handle);
            fclose(handle);

            enforceEx!(FileIOException)(blocks_read == 1, 
                                        "Could open but could not read file: " ~ path_ ~
                                        " File might be corrupted or you might not have "
                                        "sufficient rights");
        }

        ///Write out the file to a physical file. Should only be called by the destructor.
        void write_out()
        in
        {
            assert(mode_ == FileMode.Write || mode_ == FileMode.Append, 
                   "Can only write to file in Write or Append file mode");
        }
        body
        {
            FILE* handle;

            switch(mode_)
            {
                case FileMode.Write:
                    handle = fopen(toStringz(path_), "wb");
                    break;
                case FileMode.Append:
                    handle = fopen(toStringz(path_), "ab");
                    break;
                default:
                    assert(false, "Unsupported file mode for writing");
            }

            enforceEx!(FileIOException)(handle !is null, 
                                        "Could not open file " ~ path_ ~ " for writing");

            //close the file at exit
            scope(exit){fclose(handle);}
            //nothing to write
            if(write_used_ == 0){return;}

            const blocks_written = fwrite(write_data_.ptr, write_used_, 1, handle);

            enforceEx!(FileIOException)
                      (blocks_written == 1, "Couldn't write to file " ~ path_ ~ " Maybe you " ~ 
                                            "don't have sufficient rights");
        }
}
