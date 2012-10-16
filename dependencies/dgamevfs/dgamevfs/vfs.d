
//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


module dgamevfs.vfs;


///Base classes and structs defining the general API of D:GameVFS.
import std.container;
import std.exception;
import std.path;
import std.string;
import std.typecons;

import dgamevfs.exceptions;


/**
 * A directory in the VFS.
 *
 * Provides basic directory information and access to files and 
 * subdirectories within the directory.
 *
 * Directory names in the VFS can contain any characters except $(B /),
 * which is used as directory separator, and the $(B ::) sequence, which is
 * used for explicit package lookup (see  $(D StackDir)).
 * 
 * Examples:
 * --------------------
 * //Construct the directory (ordinary physical file system directory in this case):
 * VFSDir dir = new FSDir("main", "./user_data/main", Yes.writable);
 *
 * //Print information about the directory:
 * writeln("name: ", dir.name, 
 *         ", full path: ", dir.path, 
 *         ", writable: ", dir.writable, 
 *         ", exists: ", dir.exists);
 * 
 * //Access a file. If it does not exist, it will be created when writing:
 * auto file = dir.file("logs/memory.log");
 *
 * //Access a subdirectory:
 * auto shaders = dir.dir("shaders"); 
 *
 * //Create a subdirectory. If the directory exists, nothing happens (no error):
 * auto shaders = dir.dir("does_not_exist").create(); 
 *
 *
 * //dirs() and files() methods can be used to get ranges of files and subdirectories:
 *
 * //Print paths of all immediate subdirectories and their files:
 * foreach(subdir; dir.dirs())
 * {
 *     writeln(dir.path, ":");
 *     foreach(file; subdir.files())
 *     {
 *         writeln("    ", file.path);
 *     }
 * }
 *
 * //Print paths of all subdirectories and their subdirectories, etc. recursively:
 * foreach(subdir; dir.dirs(Yes.deep))
 * {
 *     writeln(dir.path);
 * }
 *
 * //Glob patterns can be used to filter the results:
 *
 * //Print paths of all immediate subdirectories with paths containg "doc":
 * foreach(subdir; dir.dirs(No.deep, "*doc*"))
 * {
 *     writeln(dir.path);
 * }
 *
 * //Print paths of all files in the directory and in subdirectories with paths ending with ".txt":
 * foreach(file; dir.files(Yes.deep, "*.txt"))
 * {
 *     writeln(file.path);
 * }
 * --------------------
 */
abstract class VFSDir
{
    private:
        //Parent directory. If null, the directory has no parent.
        VFSDir parent_ = null;

        //Path of this directory within the parent (i.e. the name of this directory).
        string pathInParent_;

    public:
        ///Get the _name of this directory.
        final @property string name() const pure {return pathInParent_;}

        ///Get full _path of this directory in the VFS.
        final @property string path() const 
        {
            return parent_ is null ? pathInParent_ : parent_.composePath(this);
        }

        ///Is it possible to write to the directory?
        @property bool writable() const;

        ///Does the directory exist?
        @property bool exists() const;

        /**
         * Get _file with specified _path in the directory.
         *
         * The _file will be returned even if it does not exist -
         * it will be created when writing into it.
         *
         * Params:  path = Path of the _file to get.
         *
         * Throws:  $(D VFSNotFoundException) if the directory does not exist
         *          or the _file is in a nonexistent subdirectory.
         *          
         *          $(D VFSInvalidPathException) if the _path is invalid.
         *
         * Returns: File with specified _path.
         */
        VFSFile file(string path);

        /**
         * Get a subdirectory with specified _path in the directory.
         *
         * The subdirectory will be returned even if it does not exist -
         * it can be created with the $(D create()) method.
         *
         * Params:  path = Path of the subdirectory to get.
         *
         * Throws:  $(D VFSNotFoundException) if this VFSDir does not exist
         *          or the subdirectory is in a nonexistent subdirectory.
         *          
         *          $(D VFSInvalidPathException) if the _path is invalid.
         *
         * Returns: Subdirectory with specified _path.
         */
        VFSDir dir(string path);

        /**
         * Get a range of _files in the directory.
         *
         * Params:  deep = If true, recursively get _files in subdirectories.
         *                 Otherwise only get _files directly in this directory.
         *          glob = Glob pattern used to filter the results. 
         *                 If null (default), all _files will be returned.
         *                 Otherwise only _files whose VFS paths within this 
         *                 directory match glob (case sensitive) will be
         *                 returned. Some characters of _glob patterns
         *                 have special meanings: For instance, $(I *.txt)
         *                 matches any path ending with the $(B .txt) extension.
         *                 
         * Returns: Range of the _files.
         *
         * Throws:  $(D VFSNotFoundException) if the directory does not exist.
         * 
         * See_also:
         * $(LINK2 http://en.wikipedia.org/wiki/Glob_%28programming%29,Wikipedia: _glob (programming))
         */
        VFSFiles files(Flag!"deep" deep = No.deep, string glob = null);

        /**
         * Get a range of subdirectories.
         *
         * Params:  deep = If true, recursively get all subdirectories.
         *                 Otherwise just get subdirectories of this directory.
         *          glob = Glob pattern used to filter the results. 
         *                 If null (default), all subdirectories will be 
         *                 returned. Otherwise only subdirectories whose VFS
         *                 paths within this directory match glob 
         *                 (case sensitive) will be returned. Some characters of
         *                 _glob patterns have special meanings: For instance, 
         *                 $(I *.txt) matches any path ending with the $(B .txt) 
         *                 extension.
         *
         * Returns: Range of the directories.
         *
         * Throws:  $(D VFSNotFoundException) if the directory does not exist.
         */
        VFSDirs dirs(Flag!"deep" deep = No.deep, string glob = null);

        /**
         * Create the directory if it does not exist (otherwise do nothing).
         *
         * Throws:  $(D VFSIOException) if the directory could not be created.
         */
        final void create()
        {
            enforce(writable, 
                    ioError("Cannot create a non-writable directory (path: " ~ path ~ ")"));
            create_();
        }

        /**
         * Remove the directory if it exists (otherwise do nothing).
         *
         * Removes recursively, together with any subdirectories and files.
         *
         * Warning: This will make any references to subdirectories or 
         *          files in this directory invalid.
         *
         * Throws:  $(D VFSIOException) if the directory could not be removed.
         */
        void remove();

    protected:
        /**
         * Constructor to initialize state common for $(D VFSDir) implementations.
         *
         * Params:  parent       = Parent directory. If null, this directory has no _parent. 
         *          pathInParent = Path of the directory within the _parent.
         */
        this(VFSDir parent, string pathInParent)
        {
            parent_ = parent;
            pathInParent_ = pathInParent;
        }

        ///Construct a range from a set of directories.
        static VFSDirs dirsRange(VFSDirs.Items dirs) {return VFSDirs(dirs);}

        ///Construct a range from a set of _files.
        static VFSFiles filesRange(VFSFiles.Items files) {return VFSFiles(files);}

        ///Compose path for a _child directory. Used e.g. to allow $(D StackDir) to set children's paths.
        string composePath(const VFSDir child) const
        {
            return path ~ "/" ~ child.name;
        }

        ///Implementation of $(D create()). Caller contract guarantees that the directory is writable.
        void create_();

        ///Return a copy of this VFSDir without a parent. Used for mounting.
        VFSDir copyWithoutParent();

        ///Access for derived classes to call copyWithoutParent() of other instances.
        final VFSDir getCopyWithoutParent(VFSDir dir){return dir.copyWithoutParent();};

    package:
        //Get the parent directory.
        final @property VFSDir parent() {return parent_;}

        //Set the parent directory.
        final @property void parent(VFSDir parent) {parent_ = parent;}
}

/**
 * A bidirectional range of VFS items (files or directories).
 *
 * Examples:
 * --------------------
 * //VFSDirs is a VFSRange of directories - VFSFiles of files.
 * VFSDirs dirs;
 *
 * //Get the first directory.
 * auto f = dirs.front;
 *
 * //Get the last directory.
 * auto b = dirs.back;
 *
 * //Remove the first directory from the range (this will not remove the directory itself).
 * dirs.popFront();
 *
 * //Remove the last directory from the range (this will not remove the directory itself).
 * dirs.popBack();
 *
 * //Are there no files/directories ?
 * bool empty = r.empty;
 * --------------------
 */
struct VFSRange(T) if(is(T == VFSDir) || is(T == VFSFile))
{
    public:
        ///Function used to _compare items alphabetically.
        static bool compare(T a, T b){return 0 < cmp(a.path, b.path);}

        ///Type used to store the items.
        alias RedBlackTree!(T, compare, false) Items;

    private:
        //Item storage.
        Items items_;

        //Number of items.
        size_t length_;

    public:
        //Range used to access the items. (should be private, but DMD complains... DMD bug?)
        Items.Range range_;

        alias range_ this;

        //Destructor.
        ~this()
        {
            clear(items_);
        }

        ///Get number of items in the range.
        @property size_t length() const pure {return length_;}

        ///Pop the front element from the range.
        void popFront()
        {
            assert(length_, "Trying to popFront from an empty VFSRange");
            --length_;
            range_.popFront();
        }

        ///Pop the back element from the range.
        void popBack()
        {
            assert(length_, "Trying to popBack from an empty VFSRange");
            --length_;
            range_.popBack();
        }

    package:
        //Construct a VFSRange for specified items.
        this(Items items)
        {
            items_ = items;
            length_ = items_.length;
            range_ = items_[];
        }
}

///A VFSRange of directories.
alias VFSRange!VFSDir VFSDirs;

///A VFSRange of files.
alias VFSRange!VFSFile VFSFiles;


/**
 * A file in the VFS.
 *
 * Provides basic file information and access to I/O.
 *
 * File names in the VFS can contain any characters except $(B /),
 * which is used as directory separator, and the $(B ::) sequence, which is
 * used for explicit package lookup (see  $(D StackDir)).
 *
 * Examples:
 * --------------------
 * VFSDir dir = new FSDir("main", "./user_data/main", Yes.writable);
 *
 * //Get the file from a directory.
 * VFSFile file = dir.file("logs/memory.log");
 *
 * //Print information about the file (note that we can only get file size of an existing file):
 * writeln("name: ", file.name, ", full path: ", file.path, 
 *         ", writable: ", file.writable, ", exists: ", file.exists,
 *         ", size in bytes: ", file.bytes);
 * 
 * //Get access to read from the file:
 * auto input = file.input;
 *
 * //Simply read the file to a buffer:
 * auto buffer = new ubyte[file.bytes];
 * file.input.read(buffer);
 * 
 * //Get access to write to the file:
 * auto output = file.output;
 *
 * //Simply write a buffer to the file:
 * file.output.write(cast(const void[])"The answer is 42");
 * --------------------
 */
abstract class VFSFile
{
    protected:
        ///File mode (used by implementations);
        enum Mode
        {
            Closed,
            Read,
            Write,
            Append
        }

    private:
        //Parent directory of this file.
        VFSDir parent_;

        //Path of this file within the parent directory (name of the file).
        string pathInParent_;

    public:
        ///Get _name of the file.
        final @property string name() const 
        {
            invariant_(); scope(exit){invariant_();}
            return pathInParent_;
        }

        ///Get full _path of the file in the VFS.
        final @property string path() const 
        {
            invariant_(); scope(exit){invariant_();}
            return parent_.path ~ "/" ~ pathInParent_;
        }

        /**
         * Get file size in _bytes.
         *
         * Throws:  $(D VFSNotFoundException) if the file does not exist.
         */
        @property ulong bytes() const;

        ///Does the file exist?
        @property bool exists() const;

        ///Is it possible to write to this file?
        final @property bool writable() const 
        {
            invariant_(); scope(exit){invariant_();}
            return parent_.writable;
        }

        ///Is the file _open?
        @property bool open() const;

        /**
         * Open the file and get reading access. 
         *
         * Returns: $(D VFSFileInput) providing _input access to the file.
         *
         * Throws:  $(D VFSIOException) if the file does not exist or is already open.
         */
        final @property VFSFileInput input()
        {
            invariant_(); scope(exit){invariant_();}
            enforce(exists, 
                    ioError("Trying to open a nonexistent file for reading: ", path));
            enforce(!open, 
                    ioError("Trying to open for reading a file that is already open: ", path));
            return VFSFileInput(this);
        }

        /**
         * Open the file and get writing access. Must not already be open.
         *
         * Returns: $(D VFSFileOutput) providing _output access to the file.
         *
         * Throws:  $(D VFSIOException) if the file is not writable or is already open.
         */
        final @property VFSFileOutput output(Flag!"append" append = No.append)
        {
            invariant_(); scope(exit){invariant_();}
            enforce(writable, 
                    ioError("Trying to open a nonwritable file for writing: ", path));
            enforce(!open, 
                    ioError("Trying to open for writing a file that is already open: ", path));

            return VFSFileOutput(this, append);
        }

    protected:
        /**
         * Constructor to initialize state common for $(D VFSFile) implementations.
         *
         * Params:  parent       = Parent directory. Must not be null.
         *          pathInParent = Path of the file within the _parent.
         */
        this(VFSDir parent, string pathInParent)
        {
            assert(parent !is null, "Can't construct a file with no parent");
            parent_ = parent;
            pathInParent_ = pathInParent;
            invariant_();
        }

        ///Open the file for reading.
        void openRead();

        ///Open the file for writing/appending.
        void openWrite(Flag!"append" append);

        /**
         * Read up to $(D target.length) bytes to target from current file position.
         *
         * Params:  target = Buffer to _read to.
         *
         * Returns: Slice of _target containing the read data.
         */
        void[] read(void[] target);

        ///Write $(D data.length) bytes to file from current file position.
        void write(in void[] data);

        ///Seek offset bytes from origin within the file.
        void seek(long offset, Seek origin);

        ///Close the file, finalizing any file operations.
        void close();

        ///Proxies to for derived VFSFiles to call protected members of other VFSFiles.
        static void openReadProxy(VFSFile file){file.openRead();}
        ///Ditto
        static void openWriteProxy(VFSFile file, Flag!"append" append){file.openWrite(append);}
        ///Ditto
        static void[] readProxy(VFSFile file, void[] target){return file.read(target);}
        ///Ditto
        static void writeProxy(VFSFile file, in void[] data){file.write(data);}
        ///Ditto
        static void seekProxy(VFSFile file, long offset, Seek origin){file.seek(offset, origin);}
        ///Ditto
        static void closeProxy(VFSFile file){file.close();}

    private:
        //Using this due invariant related compiler bugs.
        void invariant_() const
        {
            assert(parent_.exists, "File with a nonexistent parent directory " 
                                   " - this shouldn't happen as a directory should only "
                                   "provide access to its files if it exists");
        }
}

///File seeking positions.
enum Seek
{
    ///Beginning of file.
    Set,
    ///_Current file position.
    Current,
    ///_End of file.
    End
}

/**
 * Provides basic file input functionality - seeking and reading.
 *
 * $(D VFSFileInput) uses reference counting so that the file is closed
 * when the last instance of $(D VFSFileInput) provided by the file is destroyed.
 *
 * Examples:
 * --------------------
 * VFSFile file; //initialized somewhere before
 *
 * auto input = file.input;
 * with(input)
 * {
 *     auto buffer = new ubyte[32];
 *     
 *     //Read the first 32 bytes from the file:
 *     read(buffer);
 *     
 *     //Read the next 32 bytes:
 *     read(buffer);
 *     
 *     //Read the last 32 bytes in the file:
 *     seek(-32, file);
 *     read(buffer);
 * }
 * --------------------
 */
struct VFSFileInput
{
    private:
        //Used for simple reference counting. Should be replaced by RefCounted once that is not bugged.
        class RefCount{int count;}

        RefCount refCount_ = null;

        //File we're working with.
        VFSFile file_;

        //Is this VFSFileInput "null" (uninitialized)?
        bool isNull_ = true;

    public:
        /**
         * Read at most $(D target.length) bytes starting at current file position to target.
         *
         * If the file does not have enough bytes to fill target or a _reading 
         * error is encountered, it reads as much data as possible and returns
         * the part of target containing the _read data.
         *
         * Params:  target = Buffer to _read to.
         *
         * Returns: Number of bytes _read.
         */
        void[] read(void[] target)
        {
            assert(!isNull_, "Trying to read using an uninitialized VFSFileInput");
            invariant_(); scope(exit){invariant_();}
            return file_.read(target);
        }

        /**
         * Set file position to offset bytes from specified origin.
         *
         * Params:  offset = Number of bytes to set file position relative to origin.
         *          origin = Position to which offset is added.
         *
         * Throws:  $(D VFSIOException) if trying to _seek before the beginning or beyond
         *          the end of file.
         */
        void seek(long offset, Seek origin)
        {
            assert(!isNull_, "Trying to seek using an uninitialized VFSFileInput");
            invariant_(); scope(exit){invariant_();}
            file_.seek(offset, origin);
        }

        //Postblit ctor (refcountng)
        this(this)
        {
            invariant_(); scope(exit){invariant_();}
            if(isNull_){return;}
            ++refCount_.count;
        }

        //Postblit dtor (refcountng)
        ~this()
        {
            invariant_();
            if(isNull_){return;}
            --refCount_.count;
            if(refCount_.count == 0){file_.close();}
        }

        //Assignment operator (refcounting)
        void opAssign(VFSFileInput rhs)
        {
            invariant_(); scope(exit){invariant_();}
            if(!rhs.isNull_){++rhs.refCount_.count;}
            if(!isNull_){--refCount_.count;}
            refCount_ = rhs.refCount_;
            file_     = rhs.file_;
            isNull_   = rhs.isNull_;
        }

    package:
        //Construct a VFSFileInput reading from specified file.
        this(VFSFile file)
        {
            isNull_ = false;
            refCount_ = new RefCount();
            refCount_.count = 1;
            file_ = file;
            file_.openRead();
            invariant_(); 
        }

    private:
        //Due to a compiler bug, invariant segfaults - so using this instead.
        void invariant_()
        {
            assert(isNull_ || (file_ !is null && file_.open),
                   "File worked on by VFSFileInput must be open during FileInput's lifetime");
        }
}

/**
 * Provides basic file output functionality - seeking and writing.
 *
 * $(D VFSFileOutput) uses reference counting so that the file is closed
 * when the last instance of $(D VFSFileOutput) provided by the file is destroyed.
 *
 * Examples:
 * --------------------
 * VFSFile file; //initialized somewhere before
 *
 * auto output = file.output;
 * with(output)
 * {
 *     //Write to the file:
 *     write(cast(const void[])"The answer is ??");
 *     
 *     //Change the last two characters in the file:
 *     seek(-2, Seek.End);
 *     write(cast(const void[])"42");
 * }
 * --------------------
 *
 * --------------------
 * //Appending:
 * //When appending to the file, every write writes to the end of file
 * //regardless of any calls to seek(), and sets the file position 
 * //to end of file. This
 * //(This is to stay in line with the C standard so we can use C functions directly)
 * auto output = file.output(Yes.append);
 * with(output)
 * {
 *     //Append to the file:
 *     write(cast(const void[])"The answer is ??");
 *     
 *     //This will NOT change the last 2 characters: it will append anyway:
 *     seek(-2, Seek.End);
 *     write(cast(const void[])"42");
 * }
 * --------------------
 */
struct VFSFileOutput
{
    private:
        //Used for simple reference counting. Should be replaced by RefCounted once that is not bugged.
        class RefCount{int count;}

        RefCount refCount_ = null;

        //File we're working with.
        VFSFile file_;

        //Is this VFSFileOutput "null" (uninitialized)?
        bool isNull_ = true;

    public:
        /**
         * Write data to file starting at current file position.
         *
         * Note:
         *
         * In append mode, any _write will _write to the end of file regardless 
         * of the current file position and file position will be set to the 
         * end of file. 
         *
         * (This is to stay in line with the C standard so we can use C I/O functions directly)
         *
         * Params:  data = Data to _write to the file.
         *
         * Throws:  $(D VFSIOException) on error (e.g. after running out of disk space).
         */
        void write(in void[] data)
        {
            assert(!isNull_, "Trying to write using an uninitialized VFSFileOutput");
            invariant_(); scope(exit){invariant_();}
            file_.write(data);
        }

        /**
         * Set file position to offset bytes from specified origin.
         *
         * Params:  offset = Number of bytes to set file position relative to origin.
         *          origin = Position to which offset is added.
         *
         * Throws:  $(D VFSIOException) if trying to _seek before the beginning or behind
         *          the end of file, or on a different error.
         */
        void seek(long offset, Seek origin)
        {
            assert(!isNull_, "Trying to seek using an uninitialized VFSFileOutput");
            invariant_(); scope(exit){invariant_();}
            file_.seek(offset, origin);
        }

        //Postblit ctor (refcountng)
        this(this)
        {
            invariant_(); scope(exit){invariant_();}
            if(isNull_){return;}
            ++refCount_.count;
        }

        //Postblit dtor (refcountng)
        ~this()
        {
            invariant_();
            if(isNull_){return;}
            --refCount_.count;
            if(refCount_.count == 0){file_.close();}
        }

        //Assignment operator (refcounting)
        void opAssign(VFSFileOutput rhs)
        {          
            invariant_(); scope(exit){invariant_();}
            if(!rhs.isNull_){++rhs.refCount_.count;}
            if(!isNull_){--refCount_.count;}
            refCount_ = rhs.refCount_;
            file_     = rhs.file_;
            isNull_   = rhs.isNull_;
        }

    package:
        //Construct a VFSFileOutput writing/appending to specified file.
        this(VFSFile file, Flag!"append" append)
        {
            isNull_ = false;
            refCount_ = new RefCount();

            refCount_.count = 1;
            file_ = file;
            file_.openWrite(append);

            invariant_(); 
        }

    private:
        //Due to a compiler bug(?), invariant segfaults - so using this instead.
        void invariant_()
        {
            assert(isNull_ || (file_ !is null && file_.open),
                   "File worked on by VFSFileOutput must be open during VFSFileOutput's lifetime");
        }
}
