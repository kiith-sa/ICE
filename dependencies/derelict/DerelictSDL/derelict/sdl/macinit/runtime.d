/*
 * Copyright (c) 2004-2008 Derelict Developers
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
 * * Neither the names 'Derelict', 'DerelictSDL', nor the names of its contributors
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
module derelict.sdl.macinit.runtime;

version(OSX) version = darwin;

version (darwin):

import derelict.sdl.macinit.string;

version (Tango)
    import tango.stdc.stringz : fromStringz, toStringz;

else
{
    static import std.string;

    alias std.string.toStringz toStringz;
    alias std.string.toString fromStringz;
}

import derelict.sdl.macinit.NSGeometry;
import derelict.util.loader;
import derelict.util.exception;

package:

alias objc_ivar* Ivar;
alias objc_method* Method;
alias objc_object Protocol;

alias char* SEL;
alias objc_class* Class;
alias objc_object* id;

alias extern (C) id function(id, SEL, ...) IMP;

struct objc_object
{
    Class isa;
}

struct objc_super
{
    id receiver;
    Class clazz;
}

struct objc_class
{
    Class isa;
    Class super_class;
    /*const*/ char* name;
    int versionn;
    int info;
    int instance_size;
    objc_ivar_list* ivars;
    objc_method_list** methodLists;
    objc_cache* cache;
    objc_protocol_list* protocols;
}

struct objc_ivar
{
    char* ivar_name;
    char* ivar_type;
    int ivar_offset;

    version (X86_64)
        int space;
}

struct objc_ivar_list
{
    int ivar_count;

    version (X86_64)
        int space;

    /* variable length structure */
    objc_ivar ivar_list[1];
}

struct objc_method
{
    SEL method_name;
    char* method_types;
    IMP method_imp;
}

struct objc_method_list
{
    objc_method_list* obsolete;

    int method_count;

    version (X86_64)
        int space;

    /* variable length structure */
    objc_method method_list[1];
}

struct objc_cache
{
    uint mask /* total = mask + 1 */;
    uint occupied;
    Method buckets[1];
}

struct objc_protocol_list
{
    objc_protocol_list* next;
    long count;
    Protocol* list[1];
}

// Objective-C runtime bindings from the Cocoa framework
extern (C)
{
    Class function (Class superclass, /*const*/char* name, size_t extraBytes) c_objc_allocateClassPair;
    Class function (Class superclass) objc_registerClassPair;
    id function (/*const*/char* name) c_objc_getClass;
    id function (id theReceiver, SEL theSelector, ...) c_objc_msgSend;
    SEL function (/*const*/char* str) c_sel_registerName;

    bool function () NSApplicationLoad;

    public void function (Class myClass) objc_addClass;
    void function (Class arg0, objc_method_list* arg1) class_addMethods;
}

static this ()
{
    SharedLib cocoa = Derelict_LoadSharedLib("Cocoa.framework/Cocoa");

    /*try
    {
        bindFunc(c_objc_allocateClassPair)("objc_allocateClassPair", cocoa);
        bindFunc(objc_registerClassPair)("objc_registerClassPair", cocoa);
    }

    catch (SharedLibProcLoadException e)*/
        bindFunc(objc_addClass)("objc_addClass", cocoa);

    bindFunc(class_addMethods)("class_addMethods", cocoa);
    bindFunc(c_objc_getClass)("objc_getClass", cocoa);
    bindFunc(c_objc_msgSend)("objc_msgSend", cocoa);
    bindFunc(c_sel_registerName)("sel_registerName", cocoa);

    bindFunc(NSApplicationLoad)("NSApplicationLoad", cocoa);
}

Class objc_allocateClassPair (string name) (Class superclass, size_t extraBytes)
{
    return c_objc_allocateClassPair(superclass, name.ptr, extraBytes);
}

id objc_getClass (string name) ()
{
    return c_objc_getClass(name.ptr);
}

string sel_registerName (string str) ()
{
    return fromStringz(c_sel_registerName(str.ptr));
}

id objc_msgSend (ARGS...)(id theReceiver, string theSelector, ARGS args)
{
    return c_objc_msgSend(theReceiver, theSelector.ptr, args);
}
