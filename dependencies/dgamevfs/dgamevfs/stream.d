
//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module dgamevfs.stream;


import std.algorithm;
import std.stream;

import dgamevfs.exceptions;
import dgamevfs.vfs;


/**
 * Provides a $(D std.stream.Stream) interface to $(D VFSFileInput) and $(D VFSFileOutput) wrapped in an RAII struct.
 *
 * Reference to the $(D Stream) itself can be accessed through the stream property.
 *
 *
 * Note that the $(D std.stream) module in Phobos will be rewritten, which will 
 * almost certainly result in API breaking changes in $(D VFSStream).
 * Current implementation of $(D VFSStream) is hacked to fit the current $(D std.stream) 
 * and doesn't always work correctly - in particular, formatted reading crashes -
 * and it's not certain if the cause is in $(D std.stream) or $(D VFSStream).
 * This should be resolved once $(D std.stream) is rewritten.
 *
 *
 * $(D VFSStream) stores a single reference to the $(D VFSFileInput)/$(D VFSFileOutput) it wraps,
 * so it won't be closed until the $(D VFSStream) is destroyed. The user must take care 
 * not to use any $(D Stream) references provided
 * by the $(D stream) property after the $(D VFSStream) is destroyed.
 */
struct VFSStream
{
    private:
        //Internal Stream implementation.
        class VFSStream_ : Stream
        {
            private:
                //File input access (if this is an input steam).
                VFSFileInput* input_ = null;

                //File output access (if this is an output steam).
                VFSFileOutput* output_ = null;

                //Used for errors if the VFSStream_ is used after owner VFSStream is destroyed.
                bool closed_ = false;

                //File size in bytes.
                ulong bytes_;

                /*
                 * File position in bytes from file start. 
                 *
                 * Note that we don't get file position from the opened file -
                 * we keep track of it ourselves, so we can't keep track of it 
                 * correctly if the file is opened for appending.
                 *
                 * We do this because we don't want to break the VFSFile API
                 * just to perfectly support $(D std.stream) that is going to be
                 * rewritten soon anyway.
                 */
                ulong position_;

            public:
                //Construct a VFSStream reading from provided input with specified file size.
                this(VFSFileInput* input, ulong bytes)
                {
                    input_    = input;
                    bytes_    = bytes;
                    readable  = true;
                    writeable = false;
                    seekable  = true;
                }

                //Construct a VFSStream writing to provided output.
                this(VFSFileOutput* output)
                {
                    output_   = output;
                    bytes_    = 0;
                    readable  = false;
                    writeable = true;
                    seekable  = true;
                }

                //Close the VFSStream (any further I/O operations will cause assert errors).
                override void close()
                {
                    closed_ = true;
                    super.close();
                }

            protected:
                override size_t readBlock(void* buffer, size_t size)
                {
                    assert(!closed_, "Trying to read from a closed VFSFileStream");
                    assert(input_ !is null, 
                           "Trying to read from an output VFSFileStream");

                    size = input_.read(buffer[0 .. size]).length;
                    position_ += size;
                    readEOF = (size == 0);
                    return size;
                }

                override size_t writeBlock(const void* buffer, size_t size)
                {
                    assert(!closed_, "Trying to write to a closed VFSFileStream");
                    assert(output_ !is null, 
                           "Trying to write to an input VFSFileStream");

                    try
                    {
                        output_.write(buffer[0 .. size]);
                        bytes_ = max(bytes_, position_ + size);
                        position_ += size;
                        return size;
                    }
                    catch(VFSIOException e)
                    {
                        return 0;
                    }
                }

                override ulong seek(long offset, SeekPos rel)
                {
                    assert(!closed_, "Trying to seek in a closed VFSFileStream");

                    readEOF = false;

                    const origin = rel == SeekPos.Set     ? Seek.Set :
                                   rel == SeekPos.Current ? Seek.Current :
                                                            Seek.End;

                    try
                    {
                        input_ !is null ? input_.seek(offset, origin)
                                        : output_.seek(offset, origin);

                        //If the position is invalid, this doesn't execute
                        //since seek() throws - so no need for error checking here.
                        final switch(origin)
                        {
                            case Seek.Set:     position_ = offset;             break;
                            case Seek.End:     position_ = bytes_ + offset;    break;
                            case Seek.Current: position_ = position_ + offset; break;
                        }

                        return position_;
                    }
                    catch(VFSIOException e)
                    {
                        assert(false, "VFSStream seeking outside file bounds");
                    }
                }

                override @property size_t available()
                {
                    assert(!closed_, "Trying to get available byte count from "
                                     "a closed VFSFileStream");
                    assert(input_ !is null, 
                           "Output VFSStream trying to get length of available data to read");

                    return max(0, cast(size_t)(bytes_ - position_));
                }
        }

        //File input access (if this is an input steam).
        VFSFileInput input_;

        //File output access (if this is an output steam).
        VFSFileOutput output_;

    public:
        //Stream implementation.
        VFSStream_ stream_;

        alias stream_ this;

        /**
         * Construct an _input $(D VFSStream).
         *
         * Note that a $(D VFSStream) constructed for input can only be read from,
         * not written to.
         *
         * Params:  input = $(D VFSFileInput) to read from the file.
         *          bytes = File size in _bytes.
         */
        this(VFSFileInput input, ulong bytes)
        {
            input_ = input;
            stream_ = new VFSStream_(&input_, bytes);
        }

        /**
         * Construct an _output $(D VFSStream).
         *
         * Note that a $(D VFSStream) constructed for output can only be written to,
         * not read from.
         *
         * Warning: Only writing mode is supported - passing a $(D VFSFileOutput)
         *          opened for appending can result in undefined behavior.
         *          This might change once the Phobos $(D std.stream) API is rewritten.
         *
         * Params:  output = $(D VFSFileOutput) to write to the file.
         */
        this(VFSFileOutput output)
        {
            output_ = output;
            stream_ = new VFSStream_(&output_);
        }

        ///Destroy the $(D VFSStream), closing the file input/output if this is the last reference to it.
        ~this()
        {
            stream_.close();
        }

        ///Access the $(D std._stream.Stream) object.
        @property Stream stream()
        {
            return stream_;
        }
}
