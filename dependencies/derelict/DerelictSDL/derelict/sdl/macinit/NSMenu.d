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
module derelict.sdl.macinit.NSMenu;

version(OSX) version = darwin;

version (darwin):

import derelict.sdl.macinit.ID;
import derelict.sdl.macinit.NSArray;
import derelict.sdl.macinit.NSMenuItem;
import derelict.sdl.macinit.NSObject;
import derelict.sdl.macinit.NSString;
import derelict.sdl.macinit.runtime;
import derelict.sdl.macinit.selectors;
import derelict.sdl.macinit.string;

package:

class NSMenu : NSObject
{
    this ()
    {
        id_ = null;
    }

    this (id id_)
    {
        this.id_ = id_;
    }

    static NSMenu alloc ()
    {
        id result = objc_msgSend(cast(id)class_, sel_alloc);
        return result ? new NSMenu(result) : null;
    }

    static Class class_ ()
    {
        return cast(Class) objc_getClass!(this.stringof);
    }

    NSMenu init ()
    {
        id result = objc_msgSend(this.id_, sel_init);
        return result ? this : null;
    }

    NSString title ()
    {
        id result = objc_msgSend(this.id_, sel_title);
        return result ? new NSString(result) : null;
    }

    NSMenu initWithTitle (NSString aTitle)
    {
        id result = objc_msgSend(this.id_, sel_initWithTitle, aTitle ? aTitle.id_ : null);
        return result ? new NSMenu(result) : null;
    }

    void setTitle (NSString str)
    {
        objc_msgSend(this.id_, sel_setTitle, str ? str.id_ : null);
    }

    NSArray itemArray ()
    {
        id result = objc_msgSend(this.id_, sel_itemArray);
        return result ? new NSArray(result) : null;
    }

    void sizeToFit ()
    {
        objc_msgSend(this.id_, sel_sizeToFit);
    }

    NSMenuItem addItemWithTitle (NSString str, string selector, NSString keyEquiv)
    {
        id result = objc_msgSend(this.id_, sel_addItemWithTitle_action_keyEquivalent, str ? str.id_ : null, cast(SEL) selector.ptr, keyEquiv ? keyEquiv.id_ : null);
        return result ? new NSMenuItem(result) : null;
    }

    void addItem (NSMenuItem newItem)
    {
        objc_msgSend(this.id_, sel_addItem, newItem ? newItem.id_ : null);
    }
}