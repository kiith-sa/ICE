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
module derelict.sdl.macinit.string;

version(OSX) version = darwin;

version (darwin)
{

version (Tango)
    import tango.text.Util : locatePrior;

else
{
    import std.string : rfind;
    import std.utf : toUTF32;
}

package
{

    version (Tango)
    {
        /**
         * string alias
         */
        alias char[] string;

        /**
         * wstring alias
         */
        alias wchar[] wstring;

        /**
         * dstring alias
         */
        alias dchar[] dstring;
    }
}

public size_t lastIndexOf (T)(T[] str, T ch)
{
    return lastIndexOf(str, ch, str.length);
}

public size_t lastIndexOf (T)(T[] str, T ch, size_t formIndex)
{
    size_t res;

    version (Tango)
        res = str.locatePrior(ch, formIndex);

    else
        return  str.rfind(toUTF32([ch])[0]);

    version (Tango)
        if (res is str.length)
            res = -1;

    return res;
}

} // version(darwin)