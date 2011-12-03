
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

///Stream implementation based on File.
module file.filestream;
@safe


import std.stream;
import std.algorithm;

import file.file;


///Stream wrapper of File.
class FileStream : Stream
{
    private:
        alias file.file.File File;
        alias file.file.FileMode FileMode;

        ///File we're reading from or writing to.
        File* file_;

    public:
        /**
         * Construct a FileStream.
         *
         * Params: file = File to work with.
         */
        this(ref File file)
        {
            file_     = &file;
            readable  = can_read();
            writeable = can_write();
            seekable  = true;
        }

    protected:
        override size_t readBlock(void* buffer, size_t size) 
        {
            assert(can_read, "File stream trying to read from a file not opened for reading");

            size    = file_.read(buffer[0 .. size]);
            readEOF = (size == 0);
            return size;
        }

        override size_t writeBlock(const void* buffer, size_t size) 
        {
            assert(can_write, "File stream trying to write to a file not opened "
                              "for writing/appending");

            file_.write(buffer[0 .. size]);
            return size;
        }

        override ulong seek(long offset, SeekPos rel)
        {
            readEOF = false;
            Seek origin = rel == SeekPos.Set     ? Seek.Set :
                          rel == SeekPos.Current ? Seek.Current :
                                                   Seek.End;
            return file_.seek(offset, origin);
        }

        override size_t available() 
        {
            assert(can_read, "File stream trying to get available data size of "
                             "file not opened for reading");

            return cast(size_t)max(0, file_.data.length - file_.seek_position_);
        }

    private:
        ///Determine whether or not we can read from file_ .
        @property bool can_read() const {return file_.mode == FileMode.Read;}

        ///Determine whether or not we can write to file_ .
        @property bool can_write() const
        {
            return [FileMode.Write, FileMode.Append].canFind(file_.mode);
        }

    unittest
    {
        File file;
        string read_contents =
            "line 1\n"
            "line 2\n"
            "42 3.14  ";
        file_dummy_read(file, read_contents);
        InputStream input = new FileStream(file);
        
        assert(input.readLine() == "line 1");
        assert(input.readLine() == "line 2");
        assert(input.readLine() == "42 3.14  ");
        assert(input.eof);
    }
    unittest
    {
        File file;
        int[] read_contents = [42, 4];
        file_dummy_read(file, read_contents);
        InputStream input = new FileStream(file);
        
        int result;
        input.read(result);
        assert(result == 42);
        input.read(result);
        assert(result == 4);
    }
    unittest
    {
        File file;
        file_dummy_write(file);
        OutputStream output = new FileStream(file);

        output.writeLine("line 1");
        output.writeLine("line 2");
        output.writeLine("42 3.14  ");

        ubyte[] expected = cast(ubyte[])
            "line 1\n"
            "line 2\n"
            "42 3.14  ";

        assert(file.write_data_[0 .. expected.length] == expected);
    }
    unittest
    {
        File file;
        file_dummy_append(file);
        OutputStream output = new FileStream(file);

        output.writeLine("line 1");
        output.writeLine("line 2");
        output.writeLine("42 3.14  ");

        ubyte[] expected = cast(ubyte[])
            "line 1\n"
            "line 2\n"
            "42 3.14  ";

        assert(file.write_data_[0 .. expected.length] == expected);
    }
}
