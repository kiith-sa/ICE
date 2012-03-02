
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

///File I/O struct.
module file.file;


import core.stdc.stdio;

import std.algorithm;
import std.exception;
import std.file;
import std.string;

import file.fileio;
import memory.memory;
import math.math;


alias std.algorithm.indexOf indexOf;


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

///Seek positions.
enum Seek
{
    ///Beginning of file.
    Set,
    ///Current file position.
    Current,
    ///End of file.
    End
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

        ///Number of used bytes in writeData_ .
        size_t writeUsed_;
        ///Data to write to file: manually allocated, reallocated if not sufficient.
        ubyte[] writeData_;

        ///Current position in the file.
        size_t seekPosition_ = 0;

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
         * it doesn't need to be registered with addModDirectory().
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
                    path_ = getPathRead(name);
                    //load file into memory
                    load();
                    break;
                case FileMode.Write, FileMode.Append:
                    enforceEx!FileIOException 
                              (name.indexOf("::") >= 0, "Mod directory for writing and/or appending "
                                                        "not specified");
                    path_ = getPathWrite(name);
                    writeData_ = allocArray!ubyte(writeReserve_);
                    break;
                default:
                    assert(false, "Unsupported file mode");
            }
        }

        ///Close the file.
        ~this()
        {
            //dummy unittest files have empty names, don't need to be written out
            if(name_ != "" && (mode_ == FileMode.Write || mode_ == FileMode.Append))
            {
                writeOut();
            }
            if(data_ !is null){free(data_);}
            if(writeData_ !is null){free(writeData_);}
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
         * Read data from file (only applicable in Read mode).
         *
         * Will change file position to the end of read data, stopping at EOF.
         *
         * Params:  target = Buffer to read to. At most target.length bytes will be read.
         *
         * Returns: Number of bytes read.
         */
        size_t read(ref void[] target)
        in
        {
            assert(mode_ == FileMode.Read, 
                   "Can only read data from a file opened for reading");
        }
        body
        {
            const readSize = clamp(cast(long)target.length, 0L, 
                                    cast(long)data_.length - cast(long)seekPosition_);
            target[0 .. readSize] = data_[seekPosition_ .. seekPosition_ + readSize];
            seekPosition_ += readSize;
            return readSize;
        }

        /**
         * Write data to file (only applicable in Write, Append modes).
         * 
         * This does not necessarily write data out to the file,
         * data might be buffered until the file is closed.
         *
         * Will change file position to the end of written data.
         *
         * Params:  data = Data to write.
         */
        void write(in void[] data)
        in
        {
            assert(mode_ != FileMode.Read, "Can't write to a file opened for reading");
            assert(writeData_ !is null, "Trying to write to a closed file");
        }
        body
        {
            const dataBytes = cast(ubyte[])data;
            const needed = seekPosition_ + dataBytes.length;
            const allocated = writeData_.length;

            //reallocate if not enough space
            if(needed > allocated)
            {
                writeData_ = realloc(writeData_, max(needed, allocated * 2));
            }

            writeData_[seekPosition_ .. needed] = dataBytes[];
            writeUsed_ = max(writeUsed_, needed);

            seekPosition_ += dataBytes.length;
        }
        
        /**
         * Set file position.
         *
         * File position can be set beyond file end but not before file start.
         *
         * Params:  offset = Offset, in bytes, relative to origin.
         *          origin = Position to which offset is added. 
         *                   Can be the beginning of file, end of file, or
         *                   current file position.
         *
         * Returns: Resulting file position in bytes from the beginning of the file.
         */
        ulong seek(long offset, Seek origin)
        {
            //XXX this is still wrong in append mode - it must be
            //fileSize + writeUsed in the Seek.End mode then
            const long base = origin == Seek.Set     ? 0 :
                              origin == Seek.Current ? seekPosition_ :
                              mode_  == FileMode.Read ? data_.length : writeUsed_;
            const long position = base + offset;
            assert(position >= 0, "Can't seek before the beginning of a file");
            seekPosition_ = cast(size_t)position;
            return seekPosition_;
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

            data_ = allocArray!ubyte(size);

            //create a file object with allocated data_ buffer
            scope(failure){free(data_);}
            
            //don't need to read if the file is empty
            if(size == 0){return;}

            FILE* handle = fopen(toStringz(path_), "rb");
            enforceEx!FileIOException(handle !is null, 
                                      "Could not open file " ~ path_ ~ " for reading");

            //read to file
            const blocksRead = fread(data_.ptr, size, 1u, handle);
            fclose(handle);

            enforceEx!FileIOException(blocksRead == 1, 
                                      "Could open but could not read file: " ~ path_ ~
                                      " File might be corrupted or you might not have "
                                      "sufficient rights");
        }

        ///Write out the file to a physical file. Should only be called by the destructor.
        void writeOut()
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
                case FileMode.Write:  handle = fopen(toStringz(path_), "wb"); break;
                case FileMode.Append: handle = fopen(toStringz(path_), "ab"); break;
                default: assert(false, "Unsupported file mode for writing");
            }

            enforceEx!FileIOException(handle !is null, 
                                      "Could not open file " ~ path_ ~ " for writing");

            //close the file at exit
            scope(exit){fclose(handle);}
            //nothing to write
            if(writeUsed_ == 0){return;}

            const blocksWritten = fwrite(writeData_.ptr, writeUsed_, 1, handle);

            enforceEx!FileIOException
                      (blocksWritten == 1, "Couldn't write to file " ~ path_ ~ " Maybe you " ~ 
                                            "don't have sufficient rights");
        }
}

package:

/**
 * Create a dummy file for reading for unittest purposes.
 *
 * Params: file     = File struct to write to.
 *         contents = Contents of the dummy file.
 */
void fileDummyRead(T)(out File file, T[] contents)
{
    file.mode_ = FileMode.Read;
    const bytes = contents.length * T.sizeof;
    file.data_ = allocArray!ubyte(bytes);
    file.data_[] = (cast(ubyte*)contents.ptr)[0 .. bytes].dup;
}

/**
 * Create a dummy file for writing for unittest purposes.
 *
 * Params: file = File struct to write to.
 */
void fileDummyWrite(out File file)
{
    file.mode_ = FileMode.Write;
    file.writeData_ = allocArray!(ubyte)(writeReserve_);
}

/**
 * Create a dummy file for appending for unittest purposes.
 *
 * Params: file = File struct to write to.
 */
void fileDummyAppend(out File file)
{
    file.mode_ = FileMode.Append;
    file.data_ = allocArray!(ubyte)(0);
    file.writeData_ = allocArray!(ubyte)(writeReserve_);
}
