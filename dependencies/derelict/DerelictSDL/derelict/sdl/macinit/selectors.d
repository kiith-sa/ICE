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
module derelict.sdl.macinit.selectors;

version(OSX) version = darwin;

version (darwin):

import derelict.sdl.macinit.runtime;
import derelict.sdl.macinit.string;

package:
version = SDL_USE_NIB_FILE;
// Classes
const id class_NSApplication;
const id class_NSAutoreleasePool;
const id class_NSDictionary;
const id class_NSEnumerator;
const id class_NSGeometry;
const id class_NSMenu;
const id class_NSMenuItem;
const id class_NSNotification;
const id class_NSObject;
const id class_NSProcessInfo;
const id class_NSString;
id class_SDLApplication;

// Selectors
const string sel_stringWithCharacters_length;
const string sel_addItem;
const string sel_addItemWithTitle_action_keyEquivalent;
const string sel_alloc;
const string sel_class;
const string sel_getCharacters_range;
const string sel_hasSubmenu;
const string sel_init;
const string sel_initWithTitle;
const string sel_itemArray;
const string sel_length;
const string sel_mainMenu;
const string sel_nextObject;
const string sel_objectEnumerator;
const string sel_objectForKey;
const string sel_poseAsClass;
const string sel_processInfo;
const string sel_processName;
const string sel_rangeOfString;
const string sel_release;
const string sel_run;
const string sel_setAppleMenu;
const string sel_setDelegate;
const string sel_setKeyEquivalentModifierMask;
const string sel_setMainMenu;
const string sel_setSubmenu;
const string sel_setTitle;
const string sel_setWindowsMenu;
const string sel_sharedApplication;
const string sel_sizeToFit;
const string sel_stringByAppendingString;
const string sel_submenu;
const string sel_title;
const string sel_UTF8String;
const string sel_separatorItem;
const string sel_stop;
const string sel_terminate;
const string sel_setupWorkingDirectory;
version (SDL_USE_NIB_FILE) const string sel_fixMenu;
const string sel_application;
const string sel_applicationDidFinishLaunching;
const string sel_initWithTitle_action_keyEquivalent;

static this ()
{
    class_NSApplication = objc_getClass!("NSApplication");
    class_NSAutoreleasePool = objc_getClass!("NSAutoreleasePool");
    class_NSDictionary = objc_getClass!("NSDictionary");
    class_NSEnumerator = objc_getClass!("NSEnumerator");
    class_NSGeometry = objc_getClass!("NSGeometry");
    class_NSMenu = objc_getClass!("NSMenu");
    class_NSMenuItem = objc_getClass!("NSMenuItem");
    class_NSNotification = objc_getClass!("NSNotification");
    class_NSObject = objc_getClass!("NSObject");
    class_NSProcessInfo = objc_getClass!("NSProcessInfo");
    class_NSString = objc_getClass!("NSString");

    sel_stringWithCharacters_length = sel_registerName!("stringWithCharacters:length:");
    sel_addItem = sel_registerName!("addItem:");
    sel_addItemWithTitle_action_keyEquivalent = sel_registerName!("addItemWithTitle:action:keyEquivalent:");
    sel_alloc = sel_registerName!("alloc");
    sel_class = sel_registerName!("class");
    sel_getCharacters_range = sel_registerName!("getCharacters:range:");
    sel_hasSubmenu = sel_registerName!("hasSubmenu");
    sel_init = sel_registerName!("init");
    sel_initWithTitle = sel_registerName!("initWithTitle:");
    sel_itemArray = sel_registerName!("itemArray");
    sel_length = sel_registerName!("length");
    sel_mainMenu = sel_registerName!("mainMenu");
    sel_nextObject = sel_registerName!("nextObject");
    sel_objectEnumerator = sel_registerName!("objectEnumerator");
    sel_objectForKey = sel_registerName!("objectForKey:");
    sel_poseAsClass = sel_registerName!("poseAsClass:");
    sel_processInfo = sel_registerName!("processInfo");
    sel_processName = sel_registerName!("processName");
    sel_rangeOfString = sel_registerName!("rangeOfString");
    sel_release = sel_registerName!("release");
    sel_run = sel_registerName!("run");
    sel_setAppleMenu = sel_registerName!("setAppleMenu:");
    sel_setDelegate = sel_registerName!("setDelegate:");
    sel_setKeyEquivalentModifierMask = sel_registerName!("setKeyEquivalentModifierMask:");
    sel_setMainMenu = sel_registerName!("setMainMenu:");
    sel_setSubmenu = sel_registerName!("setSubmenu:");
    sel_setTitle = sel_registerName!("setTitle:");
    sel_setWindowsMenu = sel_registerName!("setWindowsMenu:");
    sel_sharedApplication = sel_registerName!("sharedApplication");
    sel_sizeToFit = sel_registerName!("sizeToFit");
    sel_stringByAppendingString = sel_registerName!("stringByAppendingString:");
    sel_submenu = sel_registerName!("submenu");
    sel_title = sel_registerName!("title");
    sel_UTF8String = sel_registerName!("UTF8String");
    sel_separatorItem = sel_registerName!("separatorItem");
    sel_stop = sel_registerName!("stop:");
    sel_terminate = sel_registerName!("terminate:");
    sel_setupWorkingDirectory = sel_registerName!("setupWorkingDirectory");
    version (SDL_USE_NIB_FILE) sel_fixMenu = sel_registerName!("fixMenu");
    sel_application = sel_registerName!("application:openFile:");
    sel_applicationDidFinishLaunching = sel_registerName!("applicationDidFinishLaunching:");
    sel_initWithTitle_action_keyEquivalent = sel_registerName!("initWithTitle:action:keyEquivalent:");
}