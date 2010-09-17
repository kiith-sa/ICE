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
module derelict.sdl.macinit.NSString;

version(OSX) version = darwin;

version (darwin):

version (Tango)
{
    import tango.text.convert.Utf : toString16;
    import tango.stdc.stringz : toString16z;
}

else
    import std.utf : toUTF16z;

import derelict.sdl.macinit.ID;
import derelict.sdl.macinit.NSGeometry;
import derelict.sdl.macinit.NSObject;
import derelict.sdl.macinit.NSZone;
import derelict.sdl.macinit.runtime;
import derelict.sdl.macinit.SDLMain;
import derelict.sdl.macinit.selectors;
import derelict.sdl.macinit.string;

package:

class NSString : NSObject
{
    this ()
    {
        id_ = null;
    }

    this (id id_)
    {
        this.id_ = id_;
    }

    static NSString alloc ()
    {
        id result = objc_msgSend(cast(id)class_, sel_alloc);
        return result ? new NSString(result) : null;
    }

    static Class class_ ()
    {
        return cast(Class) objc_getClass!(this.stringof);
    }

    NSString init ()
    {
        id result = objc_msgSend(this.id_, sel_init);
        return result ? this : null;
    }

    static NSString stringWith (string str)
    {
        version (Tango)
            id result = objc_msgSend(class_NSString, sel_stringWithCharacters_length, toString16z(str.toString16()), str.length);

        else
            id result = objc_msgSend(class_NSString, sel_stringWithCharacters_length, str.toUTF16z(), str.length);

        return result !is null ? new NSString(result) : null;
    }

    static NSString opAssign (string str)
    {
        return stringWith(str);
    }

    NSUInteger length ()
    {
        return cast(NSUInteger) objc_msgSend(this.id_, sel_length);
    }

    /*const*/ char* UTF8String ()
    {
        return cast(/*const*/ char*) objc_msgSend(this.id_, sel_UTF8String);
    }

    void getCharacters (wchar* buffer, NSRange range)
    {
        objc_msgSend(this.id_, sel_getCharacters_range, buffer, range);
    }

    NSString stringWithCharacters (/*const*/ wchar* chars, NSUInteger length)
    {
        id result = objc_msgSend(this.id_, sel_stringWithCharacters_length, chars, length);
        return result ? new NSString(result) : null;
    }

    NSRange rangeOfString (NSString aString)
    {
        return *cast(NSRange*) objc_msgSend(this.id_, sel_rangeOfString, aString ? aString.id_ : null);
    }

    NSString stringByAppendingString (NSString aString)
    {
        id result = objc_msgSend(this.id_, sel_stringByAppendingString, aString ? aString.id_ : null);
        return result ? new NSString(result) : null;
    }

    NSString stringByReplacingRange (NSRange aRange, NSString str)
    {
        uint bufferSize;
        uint selfLen = this.length;
        uint aStringLen = str.length;
        wchar* buffer;
        NSRange localRange;
        NSString result;

        bufferSize = selfLen + aStringLen - aRange.length;
        buffer = cast(wchar*) NSAllocateMemoryPages(bufferSize * wchar.sizeof);

        /* Get first part into buffer */
        localRange.location = 0;
        localRange.length = aRange.location;
        this.getCharacters(buffer, localRange);

        /* Get middle part into buffer */
        localRange.location = 0;
        localRange.length = aStringLen;
        str.getCharacters(buffer + aRange.location, localRange);

        /* Get last part into buffer */
        localRange.location = aRange.location + aRange.length;
        localRange.length = selfLen - localRange.location;
        this.getCharacters(buffer + aRange.location + aStringLen, localRange);

        /* Build output string */
        result = NSString.stringWithCharacters(buffer, bufferSize);

        NSDeallocateMemoryPages(buffer, bufferSize);

        return result;
    }
}