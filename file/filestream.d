
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

///Stream implementation based on File.
module file.filestream;


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
            readable  = canRead();
            writeable = canWrite();
            seekable  = true;
        }

    protected:
        override size_t readBlock(void* buffer, size_t size) 
        {
            assert(canRead, "File stream trying to read from a file not opened for reading");

            size    = file_.read(buffer[0 .. size]);
            readEOF = (size == 0);
            return size;
        }

        override size_t writeBlock(const void* buffer, size_t size) 
        {
            assert(canWrite, "File stream trying to write to a file not opened "
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
            assert(canRead, "File stream trying to get available data size of "
                             "file not opened for reading");

            return cast(size_t)max(0, file_.data.length - file_.seekPosition_);
        }

    private:
        ///Determine whether or not we can read from file_ .
        @property bool canRead() const {return file_.mode == FileMode.Read;}

        ///Determine whether or not we can write to file_ .
        @property bool canWrite() const
        {
            return [FileMode.Write, FileMode.Append].canFind(file_.mode);
        }

    unittest
    {
        File file;
        string readContents =
            "line 1\n"
            "line 2\n"
            "42 3.14  ";
        fileDummyRead(file, readContents);
        InputStream input = new FileStream(file);
        
        assert(input.readLine() == "line 1");
        assert(input.readLine() == "line 2");
        assert(input.readLine() == "42 3.14  ");
        assert(input.eof);
    }
    unittest
    {
        File file;
        int[] readContents = [42, 4];
        fileDummyRead(file, readContents);
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
        fileDummyWrite(file);
        OutputStream output = new FileStream(file);

        output.writeLine("line 1");
        output.writeLine("line 2");
        output.writeLine("42 3.14  ");

        ubyte[] expected = cast(ubyte[])
            "line 1\n"
            "line 2\n"
            "42 3.14  ";

        assert(file.writeData_[0 .. expected.length] == expected);
    }
    unittest
    {
        File file;
        fileDummyAppend(file);
        OutputStream output = new FileStream(file);

        output.writeLine("line 1");
        output.writeLine("line 2");
        output.writeLine("42 3.14  ");

        ubyte[] expected = cast(ubyte[])
            "line 1\n"
            "line 2\n"
            "42 3.14  ";

        assert(file.writeData_[0 .. expected.length] == expected);
    }
}
