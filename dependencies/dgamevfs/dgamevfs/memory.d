//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


//Memory based VFS file/directory implementation used for testing.
module dgamevfs.memory;


import std.algorithm;
import std.exception;
import std.typecons;

import dgamevfs.exceptions;
import dgamevfs.vfs;
import dgamevfs.util;


package: 

/*
 * VFSDir implementation that works with memory as a file system.
 *
 * Used for testing.
 */
class MemoryDir : VFSDir
{
    private:
        //Subdirectories of this directory (these might contain more files/subdirectories).
        MemoryDir[] subdirs_;

        //Files immediately in this directory.
        MemoryFile[] files_;

        //Is it possible to write to this directory?
        Flag!"writable" writable_;

        //Does this directory exist?
        Flag!"exists" exists_;

    public:
        /*
         * Construct an empty MemoryDir.
         *
         * Params:  name     = Name of the directory.
         *          writable = Is the directory writable?
         *          exists   = Does the directory exist from start?
         *
         * Throws:  VFSInvalidPathException if name is not valid (contains '/' or "::").
         */
        this(string name, Flag!"writable" writable = Yes.writable, 
             Flag!"exists" exists = No.exists)
        {
            this(null, name, writable, exists);
        }

        override @property bool writable() const {return writable_;}

        //Set whether this directory (and its subdirectories) should be writable or not.
        @property void writable(bool rhs) 
        {
            writable_ = rhs ? Yes.writable : No.writable;
            foreach(dir; subdirs_) {dir.writable = rhs;}
        }
        
        override @property bool exists() const {return exists_;}

        override VFSFile file(string path)
        {
            enforce(exists, 
                    notFound("Trying to access file ", path, " in memory directory ",
                              this.path, " that does not exist"));
            string rest;
            string neededSubdir = expectSubdir(path, rest);
            //Dir is in a subdirectory.
            if(neededSubdir !is null)
            {
                foreach(dir; subdirs_) if(dir.exists && dir.name == neededSubdir)
                {
                    return dir.file(rest);
                }
                throw notFound("Unable to find subdirectory ", neededSubdir,
                                " in directory ", this.path,
                                " when looking for file ", path);
            }

            //File is in this directory.
            foreach(file; files_) if(file.name == path)
            {
                return file;
            }

            //File not found - create it.
            auto file = new MemoryFile(this, path);
            files_ ~= file;
            return file;
        }

        override VFSDir dir(string path)
        {
            enforce(exists, 
                    notFound("Trying to access subdirectory ", path, " in memory "
                              "directory ", this.path, " that does not exist"));
            string rest;
            string neededSubdir = expectSubdir(path, rest);
            //Dir is in a subdirectory.
            if(neededSubdir !is null)
            {
                foreach(dir; subdirs_) if(dir.exists && dir.name == neededSubdir)
                {
                    return dir.dir(rest);
                }
                throw notFound("Unable to find subdirectory ", neededSubdir,
                                " in directory ", this.path,
                                " when looking for directory ", path);
            }

            //Dir is in this directory.
            foreach(dir; subdirs_) if(dir.name == path)
            {
                return dir;
            }

            //Dir not found - create it.
            auto dir = new MemoryDir(this, path, writable_, No.exists);
            subdirs_ ~= dir;
            return dir;
        }

        override VFSFiles files(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access files of memory directory ", 
                              this.path, " that does not exist"));

            auto files = new VFSFiles.Items;

            //files in this directory
            foreach(file; files_) 
            {
                if(!file.exists){continue;}

                if(subPathMatch(file.path, path, glob))
                {
                    files.insert(file);
                }
            }
            //files in subdirectories
            if(deep) foreach(dir; subdirs_)
            {
                foreach(file; dir.files(deep)) 
                {
                    if(subPathMatch(file.path, path, glob))
                    {
                        files.insert(file);
                    }
                }
            }

            return filesRange(files);
        }

        override VFSDirs dirs(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access subdirectories of memory directory ", 
                              this.path, " that does not exist"));

            auto dirs = new VFSDirs.Items;

            foreach(dir; subdirs_)
            {
                if(!dir.exists){continue;}
                //this subdirectory

                if(subPathMatch(dir.path, path, glob))
                {
                    dirs.insert(dir);
                }

                //subdirs of this subdirectory
                if(deep) foreach(subdir; dir.dirs(deep))
                {
                    if(subPathMatch(subdir.path, path, glob))
                    {
                        dirs.insert(subdir);
                    }
                }
            }

            return dirsRange(dirs);
        }

        override void remove()
        {
            exists_ = No.exists;
        }

    protected:
        override void create_()
        {
            exists_ = Yes.exists;
        }

        override VFSDir copyWithoutParent()
        {
            auto result = new MemoryDir(name, writable_, exists_);
            result.subdirs_ = subdirs_;
            result.files_   = files_;
            return result;
        }

    private:
        /*
         * Construct a MemoryDir with a parent.
         *
         * Params:  parent   = Parent directory (can be null).
         *          name     = Name of the directory.
         *          writable = Is the directory writable?
         *          exists   = Does the directory exist from start?
         *
         * Throws:  VFSInvalidPathException if pathInParent is not valid 
         *          (contains '/' or "::").
         */
        this(VFSDir parent, string pathInParent, 
             Flag!"writable" writable, Flag!"exists" exists)
        {
            enforce(noSeparators(pathInParent),
                    invalidPath("Invalid directory name: ", pathInParent));
            writable_ = writable;
            exists_ = exists;
            super(parent, pathInParent);
        }
}

/*
 * VFSFile that implements a file in memory.
 *
 * Used for testing.
 */
class MemoryFile : VFSFile
{
    private:
        //File buffer. If null, the file does not exist.
        ubyte[] buffer_ = null;

        //File mode (open, reading, writing, appending).
        Mode mode_ = Mode.Closed;

        //Current position within the file.
        ulong seekPosition_ = 0;

    public:
        override @property ulong bytes() const 
        {
            enforce(buffer_ !is null,
                    notFound("Trying to get size of MemoryFile ", path, 
                              " that does not exist"));
            return buffer_.length;
        }

        override @property bool exists() const {return buffer_ !is null;}
            
        override @property bool open() const
        {
            return mode_ != Mode.Closed;
        }

    protected:    
        override void openRead()
        {
            assert(exists, "Trying to open a nonexistent file for reading: " ~ path);
            assert(mode_ == Mode.Closed, "Trying to open a file that is already open: " ~ path);

            if(buffer_ !is null)
            {
                mode_ = Mode.Read;
                return;
            }
        }

        override void openWrite(Flag!"append" append)
        {
            assert(mode_ == Mode.Closed, "Trying to open a file that is already open" ~ path);
            assert(writable, "Trying open a non-writable file for writing: " ~ path);

            mode_ = (append ? Mode.Append : Mode.Write);

            if(buffer_ is null){buffer_ = [];}
            //Write overwrites the buffer.
            else if(!append)   {clear(buffer_);}
        }

        override void[] read(void[] target)
        {
            assert(mode_ == Mode.Read, 
                   "Trying to read from a file not opened for reading: " ~ path);

            const seek = cast(size_t)seekPosition_;
            const read_size =  max(cast(size_t)0, min(buffer_.length - seek,
                                                      target.length));
            target[0 .. read_size] = buffer_[seek .. seek + read_size];
            seekPosition_ += read_size;
            return target[0 .. read_size];
        }

        override void write(in void[] data)
        {
            assert(mode_ == Mode.Write || mode_ == Mode.Append, 
                   "Trying to write to a file not opened for writing/appending: " ~ path);
            assert(writable, "Trying to write to a non-writable file: " ~ path);

            const data_bytes = cast(ubyte[])data;
            //Appending always to the end of file (C-like behavior).
            if(mode_ == Mode.Append)
            {
                buffer_ ~= data_bytes;
                seekPosition_ = buffer_.length;
                return;
            }
            const needed = cast(size_t)seekPosition_ + data_bytes.length;
            buffer_.length = max(buffer_.length, needed);
            buffer_[cast(size_t)seekPosition_ .. needed] = data_bytes[0 .. $];
            seekPosition_ += data_bytes.length;
        }

        override void seek(long offset, Seek origin)
        {
            assert(mode_ != Mode.Closed, "Trying to seek in an unopened file: " ~ path);

            const long base = origin == Seek.Set     ? 0 :
                              origin == Seek.Current ? seekPosition_ :
                                                       buffer_.length;
            const long position = base + offset;
            enforce(position >= 0, 
                    ioError("Trying to seek before the beginning of file: " ~ path));
            enforce(position <= buffer_.length,
                    ioError("Trying to seek beyond the end of file: " ~ path));
            seekPosition_ = cast(ulong)position;
        }

        override void close()
        {
            assert(mode_ != Mode.Closed, "Trying to close an unopened file: " ~ path);

            mode_ = Mode.Closed;
            seekPosition_ = 0;
        }

    private:
        /*
         * Construct a MemoryFile with specified parent and path.
         *
         * Params:  parent         = Parent directory.
         *          pathInParent = Path of the file in the parent directory (aka file name).
         *
         * Throws:  VFSInvalidPathException if pathInParent is not valid 
         *          (contains '/' or "::").
         */
        this(MemoryDir parent, string pathInParent)
        {
            enforce(noSeparators(pathInParent),
                    invalidPath("Invalid file name: ", pathInParent));
            super(parent, pathInParent);
        }
}

