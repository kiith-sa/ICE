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
module derelict.sdl.macinit.CoreFoundation;

version(OSX) version = darwin;

version (darwin):

import derelict.util.loader;

package:

// CFBase types
private struct __CFAllocator;
alias __CFAllocator* CFAllocatorRef;

alias int CFIndex;
alias /*const*/ void* CFTypeRef;



// CFBundle types
private typedef void* __CFBundle;
alias __CFBundle *CFBundleRef;



// CFDictionary types;
private typedef void* __CFDictionary;
alias __CFDictionary* CFDictionaryRef;



// CFURL types;
private typedef void* __CFURL;
alias __CFURL* CFURLRef;




extern (C)
{
    //  CFBase bindings from the CoreFoundation framework
    typedef void function(CFTypeRef cf) pfCFRelease;
    pfCFRelease CFRelease;



    //   CFBundle bindings from the CoreFoundation framework
    CFDictionaryRef function(CFBundleRef bundle) CFBundleGetInfoDictionary;
    CFBundleRef function() CFBundleGetMainBundle;
    CFURLRef function(CFBundleRef bundle) CFBundleCopyBundleURL;



    //   CFURL bindings from the CoreFoundation framework
    CFURLRef function(CFAllocatorRef allocator, CFURLRef url) CFURLCreateCopyDeletingLastPathComponent;
    bool function(CFURLRef url, bool resolveAgainstBase, ubyte* buffer, CFIndex maxBufLen) CFURLGetFileSystemRepresentation;
}

static this ()
{
    // The CoreFoundation framework
    SharedLib coreFoundation = Derelict_LoadSharedLib("CoreFoundation.framework/CoreFoundation");

    bindFunc(CFRelease)("CFRelease", coreFoundation);
    bindFunc(CFBundleGetInfoDictionary)("CFBundleGetInfoDictionary", coreFoundation);
    bindFunc(CFBundleGetMainBundle)("CFBundleGetMainBundle", coreFoundation);
    bindFunc(CFBundleCopyBundleURL)("CFBundleCopyBundleURL", coreFoundation);
    bindFunc(CFURLCreateCopyDeletingLastPathComponent)("CFURLCreateCopyDeletingLastPathComponent", coreFoundation);
    bindFunc(CFURLGetFileSystemRepresentation)("CFURLGetFileSystemRepresentation", coreFoundation);
}