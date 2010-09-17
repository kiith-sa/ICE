/*
 * Copyright (c) 2004-2009 Derelict Developers
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the names 'Derelict', 'DerelictUtil', nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
module derelict.util.exception;

/**
* Base class for all exceptions thrown by Derelict packages.
*/
class DerelictException : Exception
{
public:
    this(char[] msg)
    {
        super(msg);
    }
}

/**
* This exception is thrown by the when a shared library cannot be loaded
* because it is either missing or not on the system path.
*/
class SharedLibLoadException : DerelictException
{
public:
    static void throwNew(char[][] libNames, char[][] reasons)
    {
        char[] msg = "Failed to load one or more shared libraries.";
        foreach(i, n; libNames)
        {
            msg ~= "\n\t" ~ n ~ ": ";
            if(i < reasons.length)
                msg ~= reasons[i];
            else
                msg ~= "Unknown";
        }
        throw new SharedLibLoadException(msg);
    }

    this(char[] msg)
    {
        super(msg);
        _sharedLibName = "";
    }

    this(char[] msg, char[] sharedLibName)
    {
        super(msg);
        _sharedLibName = sharedLibName.dup;
    }

    char[] sharedLibName()
    {
        return _sharedLibName;
    }

private:
    char[] _sharedLibName;
}

/**
* This exception is thrown when a function or variable symbol cannot be loaded
* from a shared library, either because it does not exist in the library or
* because the library is corrupt.
*/
class SharedLibProcLoadException : DerelictException
{
public:
    this(char[] msg)
    {
        super(msg);
        _procName = null;
    }

    this(char[] sharedLibName, char[] procName)
    {
        super("Failed to load proc " ~ procName ~ " from shared library " ~ sharedLibName);
        _procName = procName.dup;
    }

    char[] procName()
    {
        return _procName;
    }

private:
    char[] _procName;
}

/**
* This exception *might* be thrown when an attempt is made to use a shared library
* handle that references an unloaded shared library.
*/
class InvalidSharedLibHandleException : DerelictException
{
public:

    this(char[] sharedLibName)
    {
        super("Attempted to use handle to unloaded shared library " ~ sharedLibName);
        _sharedLibName = sharedLibName.dup;
    }

    char[] sharedLibName()
    {
        return _sharedLibName;
    }

private:
    char[] _sharedLibName;
}

//******************************************************************************

/**
* The MissingProcCallback allows the app to handle the case of missing symbols. By default,
* a SharedLibProcLoadException is thrown. However, if a the app determines that
* particular symbol is not needed, the callback can return true. This will cause
* the shared library to continue loading. Returning false will cause the exception
* to be thrown.
*/
alias bool function(char[] libName, char[] procName) MissingProcCallback;

private MissingProcCallback missingProcCallback;

public void Derelict_HandleMissingProc(char[] libName, char[] procName)
{
    bool result = false;
    if(missingProcCallback !is null)
        result = missingProcCallback(libName, procName);
    if(!result)
        throw new SharedLibProcLoadException(libName, procName);
}

void Derelict_SetMissingProcCallback(MissingProcCallback callback)
{
    missingProcCallback = callback;
}