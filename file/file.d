module file.file;


import std.file;

import memory.memory;
import math.math;


///File open modes
enum FileMode
{
    Read,
    Write,
    Append
}

///Used to access files, either to read their contents or to write to them.
struct File
{
    invariant
    {
        assert(write_used_ <= uint.max, "Writing over 4GiB files not yet supported");
    }
    package:
        //In-engine file name, such as fonts/font.ttf or mod::fonts/font.ttf .
        string name_;
        //Actual file path in the real filesystem.
        string path_;
        //Mode the file was opened with.
        FileMode mode_;
        //File contents loaded into memory (in read mode)- manually allocated.
        ubyte[] data_;

        //Number of used bytes in write_data_ .
        ulong write_used_;
        //Data to write to file- manually allocated, reallocated if not sufficient.
        ubyte[] write_data_;
        
        //Fake constructor. Returns file with given in-engine name, mode
        //and space allocated to read data from a file or space reserved for writing,
        //depending on mode.
        static File opCall(string name, string path, FileMode mode, ulong read_size, 
                           uint write_reserve)
        in
        {
            if(read_size)
            {
                assert(read_size <= uint.max, "Reading over 4GiB files not yet supported");
                assert(mode == FileMode.Read, 
                       "Can't open a file for writing/appending with read buffer");
            }
            if(write_reserve)
            {
                assert(mode != FileMode.Read,
                       "Can't open a file for reading with write buffer");
            }
        }
        body
        {
            File file;
            file.name_ = name;
            file.path_ = path;
            file.mode_ = mode;
            if(mode == FileMode.Read){file.data_ = alloc!(ubyte)(read_size);}
            else if(mode == FileMode.Write || mode == FileMode.Append)
            {
                file.write_data_ = alloc!(ubyte)(write_reserve);
            }
            return file;
        }

        //Destroy the file object and deallocate its buffers.
        void die()
        {
            if(data_ !is null){free(data_);}
            if(write_data_ !is null){free(write_data_);}
            data_ = write_data_ = null;
        }

    public:
        ///Access data of a loaded file (only applicable in Read mode).
        void[] data()
        in
        {
            assert(mode_ == FileMode.Read, 
                   "Can only read data from a file opened for reading");
            assert(data_ !is null, "Trying to read from a closed file");
        }
        body{return cast(void[])data_;}

        ///Return OS filesystem path of the file.
        string path(){return path_;}

        ///Write data to file (only applicable in Write, Append modes)
        void write(void[] data)
        in
        {
            assert(mode_ != FileMode.Read, "Can't write to a file opened for reading");
            assert(write_data_ !is null, "Trying to read from a closed file");
        }
        body
        {
            ubyte[] data_bytes = cast(ubyte[])data;
            ulong needed = write_used_ + data_bytes.length;
            assert(needed <= uint.max, "Writing over 4GiB files not yet supported");
            ulong allocated = write_data_.length;

            //reallocate if not enough space
            if(needed > allocated)
            {
                write_data_ = realloc(write_data_, max(needed, allocated * 2));
            }

            write_data_[cast(uint)write_used_ .. cast(uint)needed] = data_bytes[];
            write_used_ = needed;
        }
}
