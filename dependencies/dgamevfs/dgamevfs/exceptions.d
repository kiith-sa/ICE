
//          Copyright Ferdinand Majerech 2011 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Exceptions thrown by D:GameVFS and exception related code.
module dgamevfs.exceptions;


import std.conv;


///Parent class of all exceptions thrown at VFS errors.
abstract class VFSException : Exception
{
    public this(string msg, string file = __FILE__, int line = __LINE__) @trusted nothrow
    {
        super(msg, file, line);
    }
}

///Exception thrown when a file/directory was not found.
class VFSNotFoundException : VFSException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__) @safe nothrow
    {
        super(msg, file, line);
    }
}

///Exception thrown when an invalid path or file/directory name is detected.
class VFSInvalidPathException : VFSException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__) @safe nothrow
    {
        super(msg, file, line);
    }
}

///Exception thrown at input/output errors.
class VFSIOException : VFSException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__) @safe nothrow
    {
        super(msg, file, line);
    }
}

///Exception thrown at mounting errors.
class VFSMountException : VFSException 
{
    public this(string msg, string file = __FILE__, int line = __LINE__) @safe nothrow
    {
        super(msg, file, line);
    }
}


package:

//Template for shortcut functions to throw VFS exceptions.
template error(E) if(is(E : VFSException))
{
    E error(string file = __FILE__, int line = __LINE__, A ...)(A args) @trusted
    {
        string message;
        foreach(arg; args) {message ~= to!string(arg);}
        return new E(message, file, line);
    }
}

alias error!VFSNotFoundException    notFound;
alias error!VFSInvalidPathException invalidPath;
alias error!VFSIOException          ioError;
alias error!VFSMountException       mountError;
