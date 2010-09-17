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
module derelict.util.loader;

private
{
    import derelict.util.exception;
    import derelict.util.wrapper;
}

version(linux)
{
    version = Nix;
}
version(darwin)
{
    version = Nix;
}
else version(Unix)
{
    version = Nix;
}
else version (FreeBSD)
{
	version = Nix;
	version = freebsd;
}
else version (freebsd)
{
	version = Nix;
}

version (Nix)
{
    // for people using DSSS, tell it to link the executable with libdl
    version(build)
    {
        version (freebsd)
        {
        	// the dl* functions are in libc on freebsd which the compiler links automatically 
        }
        	
        else
        	pragma(link, "dl");
    }
}


private alias void* SharedLibHandle;

//==============================================================================
class SharedLib
{
public:
    char[] name()
    {
        return _name;
    }

private:
    SharedLibHandle _handle;
    char[] _name;

    this(SharedLibHandle handle, char[] name)
    {
        _handle = handle;
        _name = name;
    }
}
//==============================================================================
SharedLib Derelict_LoadSharedLib(char[] libName)
in
{
    assert(libName !is null);
}
body
{
    SharedLibHandle handle = Platform_LoadSharedLib(libName);
    if(handle is null)
        throw new SharedLibLoadException("Failed to load shared lib " ~ libName ~ ": " ~ GetErrorStr());
    return new SharedLib(handle, libName);
}

//==============================================================================
SharedLib Derelict_LoadSharedLib(char[][] libNames)
in
{
    assert(libNames !is null);
}
body
{
    char[][] failedLibs;
    char[][] reasons;

    foreach(char[] libName; libNames)
    {
        SharedLibHandle handle = Platform_LoadSharedLib(libName);
        if(handle !is null)
        {
            return new SharedLib(handle, libName);
        }
        else
        {
            failedLibs ~= libName;
            reasons ~= GetErrorStr();
        }

    }
    SharedLibLoadException.throwNew(failedLibs, reasons);
    return null; // to shut the compiler up
}

//==============================================================================
void Derelict_UnloadSharedLib(SharedLib lib)
{
    if(lib !is null && lib._handle !is null)
        Platform_UnloadSharedLib(lib);
}
//==============================================================================
void* Derelict_GetProc(SharedLib lib, char[] procName)
in
{
    assert(lib !is null);
    assert(procName !is null);
}
body
{
    if(lib._handle is null)
        throw new InvalidSharedLibHandleException(lib._name);
    return Platform_GetProc(lib, procName);
}
//==============================================================================
version(Windows)
{
    private import derelict.util.wintypes;

    SharedLibHandle Platform_LoadSharedLib(char[] libName)
    {
        return LoadLibraryA(toCString(libName));
    }

    void Platform_UnloadSharedLib(SharedLib lib)
    {
        FreeLibrary(cast(HMODULE)lib._handle);
        lib._handle = null;
    }

    void* Platform_GetProc(SharedLib lib, char[] procName)
    {
        void* proc = GetProcAddress(cast(HMODULE)lib._handle, toCString(procName));
        if(null is proc)
            Derelict_HandleMissingProc(lib._name, procName);

        return proc;
    }

    private char[] GetErrorStr()
    {
        // adapted from Tango

        DWORD errcode = GetLastError();

        LPCSTR msgBuf;
        DWORD i = FormatMessageA(
            FORMAT_MESSAGE_ALLOCATE_BUFFER |
            FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            null,
            errcode,
            MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            cast(LPCSTR)&msgBuf,
            0,
            null);

        char[] text = toDString(msgBuf);
        LocalFree(cast(HLOCAL)msgBuf);

        if(i >= 2)
            i -= 2;
        return text[0 .. i];
    }

}
else version(Nix)
{

    extern(C)
    {
        enum
        {
            RTLD_NOW = 0x2,
            RTLD_NOLOAD = 0x10,
        }

        void *dlopen(char* file, int mode);
        int dlclose(void* handle);
        void *dlsym(void* handle, char* name);
        char* dlerror();
    }


    SharedLibHandle Platform_LoadSharedLib(char[] libName)
    {
        return dlopen(toCString(libName), RTLD_NOW);
    }

    void Platform_UnloadSharedLib(SharedLib lib)
    {
        dlclose(lib._handle);
        lib._handle = null;
    }

    void* Platform_GetProc(SharedLib lib, char[] procName)
    {
        void* proc = dlsym(lib._handle, toCString(procName));
        if(null is proc)
            Derelict_HandleMissingProc(lib._name, procName);

        return proc;
    }

    private char[] GetErrorStr()
    {
        char* err = dlerror();
        if(err is null)
            return "Uknown Error";

        return toDString(err).dup;
    }
}
else
{
    static assert(0);
}

//==============================================================================

struct GenericLoader {
    void setup(char[] winLibs, char[] nixLibs, char[] macLibs, void function(SharedLib) userLoad, char[] versionStr = "") {
        assert (userLoad !is null);
        this.winLibs = winLibs;
        this.nixLibs = nixLibs;
        this.macLibs = macLibs;
        this.userLoad = userLoad;
        this.versionStr = versionStr;
    }

    void load(char[] libNameString = null)
    {
        if (myLib !is null) {
            return;
        }

        // make sure the lib will be unloaded at progam termination
        registeredLoaders ~= this;


        if (libNameString is null) {
            version (Windows) {
                libNameString = winLibs;
            }
            else version (freebsd) {
            	libNameString = nixLibs;
            }
            else version (linux) {
                libNameString = nixLibs;
            }
            else version(darwin) {
                libNameString = macLibs;
            }

            if(libNameString is null || libNameString == "")
            {
                throw new DerelictException("Invalid library name");
            }
        }

        char[][] libNames = libNameString.splitStr(",");
        foreach (inout char[] l; libNames) {
            l = l.stripWhiteSpace();
        }

        load(libNames);
    }

    void load(char[][] libNames)
    {
        myLib = Derelict_LoadSharedLib(libNames);

        if(userLoad is null)
        {
            // this should never, ever, happen
            throw new DerelictException("Something is horribly wrong -- internal load function not configured");
        }
        userLoad(myLib);
    }

    char[] versionString()
    {
        return versionStr;
    }

    void unload()
    {
        if (myLib !is null) {
            Derelict_UnloadSharedLib(myLib);
            myLib = null;
        }
    }

    bool loaded()
    {
        return (myLib !is null);
    }

    char[] libName()
    {
        return loaded ? myLib.name : null;
    }

    static ~this()
    {
        foreach (x; registeredLoaders) {
            x.unload();
        }
    }

    private {
        static GenericLoader*[] registeredLoaders;

        SharedLib myLib;
        char[] winLibs;
        char[] nixLibs;
        char[] macLibs;
        char[] versionStr = "";

        void function(SharedLib) userLoad;
    }
}

//==============================================================================

struct GenericDependentLoader {
    void setup(GenericLoader* dependence, void function(SharedLib) userLoad) {
        assert (dependence !is null);
        assert (userLoad !is null);

        this.dependence = dependence;
        this.userLoad = userLoad;
    }

    void load()
    {
        assert (dependence.loaded);
        userLoad(dependence.myLib);
    }

    char[] versionString()
    {
        return dependence.versionString;
    }

    void unload()
    {
    }

    bool loaded()
    {
        return dependence.loaded;
    }

    char[] libName()
    {
        return dependence.libName;
    }

    private {
        GenericLoader*              dependence;
        void function(SharedLib)    userLoad;
    }
}

//==============================================================================

package struct Binder(T) {
    void opCall(char[] n, SharedLib lib) {
        *fptr = Derelict_GetProc(lib, n);
    }


    private {
        void** fptr;
    }
}


template bindFunc(T) {
    Binder!(T) bindFunc(inout T a) {
        Binder!(T) res;
        res.fptr = cast(void**)&a;
        return res;
    }
}
