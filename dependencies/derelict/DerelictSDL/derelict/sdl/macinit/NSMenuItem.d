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
module derelict.sdl.macinit.NSMenuItem;

version(OSX) version = darwin;

version (darwin):

import derelict.sdl.macinit.ID;
import derelict.sdl.macinit.NSGeometry;
import derelict.sdl.macinit.NSMenu;
import derelict.sdl.macinit.NSObject;
import derelict.sdl.macinit.NSString;
import derelict.sdl.macinit.runtime;
import derelict.sdl.macinit.selectors;
import derelict.sdl.macinit.string;

package:

class NSMenuItem : NSObject
{
    this ()
    {
        id_ = null;
    }

    this (id id_)
    {
        this.id_ = id_;
    }

    static NSMenuItem alloc ()
    {
        id result = objc_msgSend(cast(id)class_, sel_alloc);
        return result ? new NSMenuItem(result) : null;
    }

    static Class class_ ()
    {
        return cast(Class) objc_getClass!(this.stringof);
    }

    NSMenuItem init ()
    {
        id result = objc_msgSend(this.id_, sel_init);
        return result ? this : null;
    }

    static NSMenuItem separatorItem ()
    {
        id result = objc_msgSend(class_NSMenuItem, sel_separatorItem);
        return result ? new NSMenuItem(result) : null;
    }

    NSMenuItem initWithTitle (NSString itemName, string anAction, NSString charCode)
    {
        id result = objc_msgSend(this.id_, sel_initWithTitle_action_keyEquivalent, itemName ? itemName.id_ : null, sel_registerName!(anAction).ptr, charCode ? charCode.id_ : null);
        return result ? new NSMenuItem(result) : null;
    }

    NSString title ()
    {
        id result = objc_msgSend(this.id_, sel_title);
        return result ? new NSString(result) : null;
    }

    void setTitle (NSString str)
    {
        objc_msgSend(this.id_, sel_setTitle, str ? str.id_ : null);
    }

    bool hasSubmenu ()
    {
        return objc_msgSend(this.id_, sel_hasSubmenu) !is null;
    }

    NSMenu submenu ()
    {
        id result = objc_msgSend(this.id_, sel_submenu);
        return result ? new NSMenu(result) : null;
    }

    void setKeyEquivalentModifierMask (NSUInteger mask)
    {
        objc_msgSend(this.id_, sel_setKeyEquivalentModifierMask, mask);
    }

    void setSubmenu (NSMenu submenu)
    {
        objc_msgSend(this.id_, sel_setSubmenu, submenu ? submenu.id_ : null);
    }
}