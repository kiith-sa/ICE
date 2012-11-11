//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


//Normal file system based VFS file/directory implementation.
module dgamevfs.fs;


import std.c.stdio;

import std.algorithm;
import std.exception;
import std.file;
import std.path;
import std.string;
import std.typecons;

import dgamevfs.exceptions;
import dgamevfs.vfs;
import dgamevfs.util;


/**
 * Directory in the physical filesystem.
 *
 * Note that paths behave as in the backend filesystem.
 *
 * For example, if you are working with Windows, paths are not case sensitive.
 */
class FSDir : VFSDir 
{
    private:
        //Path of the directory in the physical filesystem.
        string physicalPath_;

        //Is this directory writable?
        Flag!"writable" writable_;

    public:
        /**
         * Construct an $(D FSDir).
         *
         * Params: name         = Name of the directory in the VFS.
         *         physicalPath = Path of the directory in the physical filesystem.
         *         writable     = Is this directory _writable?
         *                        $(D FSDir) can't determine whether you have permission
         *                        to write in a directory - you must specify this 
         *                        explicitly.
         */
        this(string name, string physicalPath, Flag!"writable" writable = Yes.writable)
        {
            this(null, name, physicalPath, writable);
        }

        override @property bool writable() const {return writable_;}

        override @property bool exists() const {return .exists(physicalPath_);}

        override VFSFile file(string path)
        {
            enforce(isValidPath(path), invalidPath("Invalid physical file path: ", path));
            enforce(noPackageSeparators(path), 
                    invalidPath("File path contains unexpected package separators: ", path));
            enforce(exists, 
                    notFound("Trying to access file ", path, " in filesystem directory ",
                             this.path, " with physical path ", physicalPath_, 
                             " that does not exist"));

            //Full physical path of the file.
            const filePath = physicalPath_ ~ "/" ~ path;
            //Direct parent of requested file - must exist for us to return the file.
            const dirPath = dirName(filePath);

            enforce(.exists(dirPath),
                    notFound("Trying to access file ", baseName(filePath), 
                             " in filesystem directory with physical path ", 
                             dirPath, " that does not exist"));
            enforce(isDir(dirPath),
                    invalidPath("Trying to access file ", baseName(filePath), 
                                " in filesystem directory with physical path ", 
                                dirPath, " that is not a directory"));

            return new FSFile(this, path, filePath);
        }

        override VFSDir dir(string path)
        {
            enforce(isValidPath(path), invalidPath("Invalid physical directory path: ", path));
            enforce(noPackageSeparators(path), 
                    invalidPath("Directory path contains unexpected package separators: ", 
                                path));
            enforce(exists, 
                    notFound("Trying to access directory ", path, " in filesystem directory ",
                             this.path, " with physical path ", physicalPath_, 
                             " that does not exist"));

            //Full physical path of the dir.
            const subdirPath = physicalPath_ ~ "/" ~ path;
            //Direct parent of requested dir - must exist for us to return the dir.
            const dirPath = dirName(subdirPath);

            enforce(.exists(dirPath),
                    notFound("Trying to access directory ", baseName(subdirPath), 
                             " in filesystem directory with physical path ", dirPath, 
                             " that does not exist"));
            enforce(isDir(dirPath),
                    invalidPath("Trying to access file ", baseName(subdirPath), 
                                " in filesystem directory with physical path ", 
                                dirPath, " that is not a directory"));

            return new FSDir(this, path, subdirPath, writable_);
        }

        override VFSFiles files(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access files of filesystem directory", path, 
                             " with physical path ", physicalPath_, " that does not exist"));

            auto files = new VFSFiles.Items;

            foreach(DirEntry e; dirEntries(physicalPath_, deep ? SpanMode.depth 
                                                               : SpanMode.shallow))
            {
                if(!e.isFile()){continue;}
                auto relative = e.name;
                relative.skipOver(physicalPath_);
                relative.skipOver("/");
                relative.skipOver("\\");
                if(glob is null || globMatch(relative, glob)) 
                {
                    files.insert(new FSFile(this, relative, e.name));
                }
            }

            return filesRange(files);
        }

        override VFSDirs dirs(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access directories of filesystem directory", path, 
                             " with physical path ", physicalPath_, " that does not exist"));

            auto dirs = new VFSDirs.Items;

            foreach(DirEntry e; dirEntries(physicalPath_, deep ? SpanMode.depth 
                                                               : SpanMode.shallow))
            {
                if(!e.isDir()){continue;}
                auto relative = e.name;
                relative.skipOver(physicalPath_);
                relative.skipOver("/");
                relative.skipOver("\\");
                if(glob is null || globMatch(relative, glob)) 
                {
                    dirs.insert(new FSDir(this, relative, e.name, writable_));
                }
            }

            return dirsRange(dirs);
        }

        override void remove()
        {
            if(!exists){return;}
            try
            {
                rmdirRecurse(physicalPath_);
            }
            catch(FileException e)
            {
                throw ioError("Failed to remove filesystem directory ", path,
                              " with physical path ", physicalPath_);
            }
        }

    protected:
        override void create_()
        {
            if(exists){return;}
            try
            {
                mkdir(physicalPath_);
            }
            catch(FileException e)
            {
                throw ioError("Failed to create filesystem directory ", path,
                              " with physical path ", physicalPath_);
            }
        }

        override VFSDir copyWithoutParent()
        {
            return new FSDir(name, physicalPath_, writable_);
        }

    private:
        /*
         * Construct an FSDir.
         *
         * Params: parent       = Parent directory.
         *         name         = Name of the directory in the VFS.
         *         physicalPath = Path of the directory in the physical filesystem.
         *         writable     = Is this directory writable?
         *                        FSDir can't determine whether you have permission
         *                        to write in a directory - you must specify this 
         *                        explicitly.
         */
        this(FSDir parent, string pathInParent, string physicalPath, 
             Flag!"writable" writable)
        {
            physicalPath = cleanFSPath(physicalPath);
            pathInParent = cleanFSPath(pathInParent);
            enforce(isValidPath(physicalPath), 
                    invalidPath("Invalid physical directory path: ", physicalPath));
            physicalPath_ = physicalPath;
            if(exists)
            {
                enforce(isDir(physicalPath_),
                        invalidPath("Trying to construct a FSDir with physical path ",
                                     physicalPath_, " that is not a directory."));
            }
            writable_ = writable;
            super(parent, pathInParent);
        }
}


/**
 * $(D VFSFile) implementation representing a file in the file system.
 */
class FSFile : VFSFile
{
    private:
        //File handle when the file is open.
        FILE* file_ = null;

        //File mode (open, reading, writing, appending).
        Mode mode_ = Mode.Closed;

        //Path of the file in the physical filesystem.
        string physicalPath_;

    public:
        override @property ulong bytes() const 
        {
            enforce(exists,
                    notFound("Trying to get size of FSFile ", path, 
                             " that does not exist"));
            try
            {
                return getSize(physicalPath_);
            }
            catch(FileException e)
            {
                throw notFound("Trying to get size of FSFile ", path, 
                               " that does not exist");
            }
        }

        override @property bool exists() const {return .exists(physicalPath_);}

        override @property bool open() const {return mode_ != Mode.Closed;}

    protected:
        override void openRead()
        {
            assert(exists, "Trying to open a nonexistent file for reading: " ~ path);
            assert(mode_ == Mode.Closed, "Trying to open a file that is already open: " ~ path);

            auto file = fopen(toStringz(physicalPath_), toStringz("rb"));
            enforce(file !is null,
                    ioError("FSFile ", path, " with physical path ", physicalPath_, 
                            " could not be opened for reading"));
            file_ = file;
            mode_ = Mode.Read;
        }

        override void openWrite(Flag!"append" append)
        {
            assert(mode_ == Mode.Closed, "Trying to open a file that is already open" ~ path);
            assert(writable, "Trying open a non-writable file for writing: " ~ path);

            auto file = fopen(toStringz(physicalPath_), 
                              toStringz(append ? "ab" : "wb"));
            enforce(file !is null,
                    ioError("FSFile ", path, " with physical path ", physicalPath_, 
                            " could not be opened for writing"));
            file_ = file;
            mode_ = (append ? Mode.Append : Mode.Write);
        }

        override void[] read(void[] target)
        {
            assert(mode_ == Mode.Read, 
                   "Trying to read from a file not opened for reading: " ~ path);

            return target[0 .. fread(target.ptr, 1, target.length, file_)];
        }

        override void write(const void[] data)
        {
            assert(mode_ == Mode.Write || mode_ == Mode.Append, 
                   "Trying to write to a file not opened for writing/appending: " ~ path);
            assert(writable, "Trying to write to a non-writable file: " ~ path);

            auto bytesWritten = fwrite(data.ptr, 1, data.length, file_);
            enforce(bytesWritten == data.length,
                    ioError("Error writing to FSFile ", path, " with physical path ",
                            physicalPath_, " (Possibly out of disk space?)."));
            enforce(fflush(file_) == 0,
                    ioError("Error writing to FSFile ", path, " with physical path ",
                            physicalPath_));
        }

        override void seek(long offset, Seek origin)
        {
            assert(mode_ != Mode.Closed, "Trying to seek in an unopened file: " ~ path);

            const length = bytes();
            const long base = origin == Seek.Set     ? 0 :
                              origin == Seek.Current ? seekPosition() :
                                                       length;
            const long position = base + offset;
            enforce(position >= 0, 
                    ioError("Trying to seek before the beginning of file: " ~ path));
            enforce(position <= length,
                    ioError("Trying to seek beyond the end of file: " ~ path));

            static if(size_t.sizeof == 4)
            {
                enforce(offset <= int.max, 
                        ioError("Seeking beyond 2 GiB not supported on 32bit. File: " ~ path));
                const platformOffset = cast(int)offset;
            }
            else
            {
                alias offset platformOffset;
            }

            if(fseek(file_, platformOffset, 
                     origin == Seek.Set     ? SEEK_SET :
                     origin == Seek.Current ? SEEK_CUR :
                                              SEEK_END))
            {
                throw ioError("Error seeking in FSFile ", path, " with physical path ",
                               physicalPath_);
            }
        }

        override void close()
        {
            assert(mode_ != Mode.Closed, "Trying to close an unopened file: " ~ path);

            fclose(file_);
            file_ = null;
            mode_ = Mode.Closed;
        }

    private:
        /*
         * Construct a FSFile.
         *
         * Params:  parent       = Parent directory.
         *          pathInParent = Path of the file in the parent directory (aka file name).
         *          physicalPath = Path in the physical filesystem.
         *
         * Throws:  VFSInvalidPathException if pathInParent is not valid 
         *          (contains '/' or "::").
         */
        this(FSDir parent, string pathInParent, string physicalPath)
        {
            physicalPath = cleanFSPath(physicalPath);
            pathInParent = cleanFSPath(pathInParent);
            enforce(isValidPath(pathInParent),
                    invalidPath("Invalid file name: ", pathInParent));
            physicalPath_ = physicalPath;
            if(exists)
            {
                enforce(isFile(physicalPath_),
                        invalidPath("Trying to construct a FSFile with physical path ",
                                     physicalPath_, " that is not a file."));
            }
            super(parent, pathInParent);
        }

        //Determine seek position in the file.
        @property final ulong seekPosition()
        {
            assert(file_ !is null, "Can only get seek position of an open FSFile");
            const result = ftell(file_);
            if(result < 0)
            {
                throw ioError("Error determining file position in FSFile ", path, 
                              " with physical path ", physicalPath_);
            }
            return result;
        }
}

