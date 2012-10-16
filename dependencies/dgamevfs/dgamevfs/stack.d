
//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Stacked files/directories for seamless access to multiple directories as if they were a single directory.
module dgamevfs.stack;


import std.algorithm;
import std.exception;
import std.typecons;
import std.range;

import dgamevfs.exceptions;
import dgamevfs.vfs;
import dgamevfs.util;


/**
 * A directory seamlessly working on a stack of multiple directories.
 *
 * Directories can be mounted using the $(D mount()) method.
 *
 * When looking for a file or directory in a $(D StackDir), the last directory
 * is searched first, then the second last, and so on. This means that directories
 * mounted later override those mounted before.
 *
 * Example:
 *
 * We have a directory called $(I data) with the following contents:
 * --------------------
 * shaders:
 *     font.frag 
 *     font.vert 
 * logs:
 *     (empty)
 * main.cfg
 * --------------------
 * and a directory called $(I user_data) with the following contents:
 * --------------------
 * shaders: 
 *      font.frag
 * logs:
 *      (empty)
 * custom.cfg
 * --------------------
 * the following code will work as specified in the comments:
 * --------------------
 * VFSDir data, user_data; //initialized somewhere before
 * 
 * auto stack = new StackDir("stack");
 * stack.mount(data);
 * stack.mount(user_data);
 *
 * //This will access user_data/shaders/font.frag
 * auto frag = stack.file("shaders/font.frag");
 * //This will access data/shaders/font.vert
 * auto vert = stack.file("shaders/font.vert");
 * //This will return a StackDir (as VFSDir) with "data/logs" and "user_data/logs"
 * //mounted, in that order:
 * auto logs = stack.dir("logs");
 * --------------------
 *
 * Accessing a file in a $(D StackDir) will actually return a $(D StackFile),
 * which decides which file to access on read, write and other operations.
 * The $(D StackFile) is a stack of all files that map to the same path in
 * the $(D StackDir) in the same order as $(D StackDir)'s mounted directories.
 *
 * For example, when reading or determining file size, the directories in the 
 * stack will be searched from newest to oldest and the first file found will 
 * be used.
 *
 * When writing, the file in the newest writable directory will be written to.
 *
 *
 * In some cases, it might be required to access a particular directory in the 
 * stack. E.g. a game might have multiple packages stacked on top of each other,
 * but sometimes default, non-overridden version of a file could be needed.
 * This can be done using the $(B ::) separator. 
 *
 * In the context of the previous example:
 *
 * --------------------
 * //This will access data/shaders/font.frag even though user_data/shaders/font.frag exists
 * auto default_frag = stack.file("data::shaders/font.frag");
 * --------------------
 *
 * $(D StackDir) is considered writable when any directory in the stack is writable.
 * Similarly, it exists when any directory in the stack exists.
 *
 * When we have a $(D StackDir) that does not exist and we $(D create()) it,
 * the newest directory that is writable will be created.
 * (This can happen when getting a nonexistent subdirectory of a $(D StackDir).)
 */
class StackDir : VFSDir
{
    private:
        //Directory stack.
        VFSDir[] stack_;

    public:
        /**
         * Construct a  $(D StackDir).
         * 
         * Params:  name = Name of the  $(D StackDir).
         *
         * Throws:  $(D VFSInvalidPathException) if name is not valid (contains '/' or "::").
         */
        this(string name)
        {
            enforce(noSeparators(name),
                    invalidPath("Invalid directory name: ", name));
            super(null, name);
        }

        override @property bool writable() const
        {
            foreach(pkg; stack_) if(pkg.writable)
            {
                return true;
            }
            return false;
        }

        override @property bool exists() const
        {
            foreach(pkg; stack_) if(pkg.exists)
            {
                return true;
            }
            return false;
        }

        override VFSFile file(string path)
        {
            enforce(exists, 
                    notFound("Trying to access file ", path, " in stack directory ",
                              this.path, " that does not exist"));
            enforce(stack_. length > 0, 
                    notFound("Trying to access file ", path, " in stack directory",
                              this.path, " which has no mounted directories"));

            string rest;
            const pkg = expectPackage(path, rest);
            //explicit package
            if(pkg !is null)
            {
                foreach_reverse(dir; stack_) if(dir.name == pkg)
                {
                    return dir.file(rest);
                }
            }

            //no package
            VFSFile[] stack;
            foreach(dir; stack_)
            {
                VFSFile file;
                try
                {
                    file = dir.file(path);
                }
                catch(VFSNotFoundException e){continue;}
                stack ~= file;
            }
            enforce(!stack.empty,
                    notFound("Unable to find file ", path, " in stack directory ", this.path));

            return new StackFile(this, path, stack);
        }

        override VFSDir dir(string path)
        {
            enforce(exists, 
                    notFound("Trying to access subdirectory ", path, 
                              " in stack directory ", this.path, " that does not exist"));
            enforce(stack_. length > 0, 
                    notFound("Trying to access subdirectory ", path, " in stack directory",
                              this.path, " which has no mounted directories"));

            string rest;
            const pkg = expectPackage(path, rest);
            //explicit package
            if(pkg !is null)
            {
                foreach_reverse(dir; stack_) if(dir.name == pkg)
                {
                    return dir.dir(rest);
                }
            }

            //no package
            VFSDir[] stack;
            foreach(dir; stack_)
            {
                VFSDir subdir;
                try{subdir = dir.dir(path);}
                catch(VFSNotFoundException e){continue;}
                stack ~= subdir;
            }
            enforce(!stack.empty,
                    notFound("Unable to find directory ", path, " in stack directory ", this.path));

            //Note that dirs in returned StackDir don't have that StackDir as parent.
            //Their paths are still correctly resolved through their respective parents.
            return new StackDir(this, path, stack);
        }

        override VFSFiles files(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access files of stack directory ", 
                              this.path, " that does not exist"));

            auto files = new VFSFiles.Items;
            //items inserted earlier to a RBTree override ones inserted later
            //so we insert directories in reverse order.
            //Then the newer directories override the older ones.
            foreach_reverse(dir; stack_)
            {
                if(!dir.exists){continue;}
                foreach(file; dir.files(deep, glob))
                {
                    files.insert(file);
                }
            }

            return filesRange(files);
        }

        override VFSDirs dirs(Flag!"deep" deep = No.deep, string glob = null)
        {
            enforce(exists, 
                    notFound("Trying to access subdirectories of stack directory ", 
                              this.path, " that does not exist"));

            auto dirs = new VFSDirs.Items;
            //Items inserted earlier to a RBTree override ones inserted later
            //so we insert directories in reverse order.
            //Then the newer directories override the older ones.
            foreach_reverse(dir; stack_)
            {
                if(!dir.exists){continue;}
                foreach(subdir; dir.dirs(deep, glob))
                {
                    dirs.insert(subdir);
                }
            }

            return dirsRange(dirs);
        }

        /**
         * Mount a directory.
         *
         * Files and directories of a directory mounted later will override
         * those of a directory mounted earlier.
         *
         * If dir has a parent in the VFS, a parent-less copy will be created and 
         * mounted. (This has no effect whatsoever on the underlying filesystem -
         * it just removes the need for directories to have multiple parents).
         *
         * Params:  dir = Directory to _mount.
         *
         * Throws:  $(D VFSMountException) if a directory with the same name is
         *          already mounted, or if dir has this directory as its child 
         *          or a child of any of its subdirectories (circular mounting).
         */ 
        void mount(VFSDir dir)
        {
            enforce(!canFind!((a, b){return a.name == b.name;})(stack_, dir),
                    mountError("Could not mount directory ", dir.path, " to stacked "
                                "directory ", this.path, " as there is already a "
                                "mounted directory  with the same name"));
            if(dir.parent !is null)
            {
                dir = getCopyWithoutParent(dir);
            }

            VFSDir parent = this.parent;
            while(parent !is null)
            {
                if(parent is dir)
                {
                    throw mountError("Attemted to circularly mount directory ",
                                      dir.path, " to stacked directory ", this.path);
                }
                parent = parent.parent;
            }
            stack_ ~= dir;
            dir.parent = this;
        }

        override void remove()
        {
            const removable = !stack_.canFind!((d) => !d.writable)();
            enforce(removable,
                    ioError("Couldn't remove stack directory ", path, " at ",
                            "least one directory in the stack is not writable"));
            foreach(dir; stack_)
            {
                dir.remove();
            }
        }

    protected:
        override string composePath(const VFSDir child) const
        {
            //child is in stack_ - override its path:
            foreach(pkg; stack_) if (pkg is child)
            {
                return path;
            }
            //child was returned by dir():
            return path ~ "/" ~ child.name;
        }

        override void create_()
        {
            foreach_reverse(dir; stack_) if(dir.writable)
            {
                dir.create();
                return;
            }
            assert(false, "create_() called on a non-writable StackDir");
        }

        override VFSDir copyWithoutParent()
        {
            auto result = new StackDir(name);
            foreach(dir; stack_)
            {
                result.mount(getCopyWithoutParent(dir));
            }
            return result;
        }

    private:
        /**
         * Construct a stack directory as a subdirectory of parent.
         *
         * Params:  parent       = Parent directory.
         *          pathInParent = Path of the subdir in all directories of parent's stack.
         *          stack        = Directory stack of the subdirectory.
         */
        this(StackDir parent, string pathInParent, VFSDir[] stack)
        {
            super(parent, pathInParent);
            stack_ = stack;
        }
}

/**
 * A file seamlessly working on a stack of multiple files.
 *
 * This is the file implementation returned by  $(D StackDir) methods.
 *
 * It has one file from each directory in the  $(D StackDir) - all of these
 * files map to the same path in the $(D StackDir).
 *
 * When reading from $(D StackFile), it will read from the newest file
 * in the stack that exists.
 *
 * When writing, it will write to the newest file that is writable
 * regardless of whether it already exists or not.
 */
class StackFile : VFSFile 
{
    private:
        ///File stack.
        VFSFile[] stack_;

        ///Currently open file, if any.
        VFSFile openFile_ = null;

    public:
        override @property ulong bytes() const
        {
            //Get size of the newest file that exists.
            foreach_reverse(file; stack_) if(file.exists)
            {
                return file.bytes;
            }
            throw notFound("Trying to get size of a non-existent file: ", path);
        }

        override @property bool exists() const
        {
            //If any file in the stack exists, this file exists.
            foreach_reverse(file; stack_) if(file.exists)
            {
                return true;
            }
            return false;
        }

        override @property bool open() const {return openFile_ !is null;}

    protected:
        override void openRead()
        {
            assert(openFile_ is null, "Trying to open a file that is already open: " ~ path);

            //Choose the file to read from - will read from the newest file that exists.
            foreach_reverse(file; stack_) if(file.exists)
            {
                openFile_ = file;
                openReadProxy(openFile_);
                return;
            }
            assert(false, "Trying to open a non-existent file for reading: " ~ path);
        }

        override void openWrite(Flag!"append" append)
        {
            assert(openFile_ is null, "Trying to open a file that is already open: " ~ path);
            assert(writable, "Trying open a non-writable file for writing: " ~ path);
                                     
            //Choose the file to write to - will write to the newest file that is writable.
            foreach_reverse(file; stack_) if(file.writable)
            {
                openFile_ = file;
                openWriteProxy(openFile_, append);
                return;
            }
            //At least one file must be writable, so this can not be reached.
            assert(false);
        }

        override void[] read(void[] target)
        {
            assert(openFile_ !is null, "Trying to read from an unopened file: " ~ path);
            return readProxy(openFile_, target);
        }

        override void write(in void[] data)
        {
            assert(openFile_ !is null, "Trying to write to an unopened file: " ~ path);
            assert(writable, "Trying to write to a non-writable file");
            writeProxy(openFile_, data);
        }

        override void seek(long offset, Seek origin)
        {
            assert(openFile_ !is null, "Trying to seek in an unopened file: " ~ path);
            seekProxy(openFile_, offset, origin);
        }

        override void close()
        {
            assert(openFile_ !is null, "Trying to close an unopened file: " ~ path);
            closeProxy(openFile_);
            openFile_ = null;
        }

    private:
        /**
         * Construct a $(D StackFile).
         *
         * Params:  parent       = Parent directory of the file.
         *          pathInParent = Path of the file within the parent directory.
         *          stack        = File stack.
         */
        this(StackDir parent, string pathInParent, VFSFile[] stack)
        {
            super(parent, pathInParent);
            stack_ = stack;
        }
}
