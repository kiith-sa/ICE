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
module derelict.sdl.macinit.MacTypes;

version(OSX) version = darwin;

version (darwin):
package:

/********************************************************************************

 Base integer types for all target OS's and CPU's

 UInt8            8-bit unsigned integer
 SInt8            8-bit signed integer
 UInt16          16-bit uinteger
 SInt16          16-bit signed integer
 UInt32          32-bit uinteger
 SInt32          32-bit signed integer
 UInt64          64-bit uinteger
 SInt64          64-bit integer

 *********************************************************************************/
alias ubyte UInt8;
alias byte SInt8;
alias ushort UInt16;
alias short SInt16;
alias uint UInt32;
alias int SInt32;
alias ulong UInt64;
alias long SInt64;

alias byte uint8_t;

/********************************************************************************

 Higher level basic types

 OSErr                   16-bit result error code
 OSStatus                32-bit result error code
 LogicalAddress          Address in the clients virtual address space
 ConstLogicalAddress     Address in the clients virtual address space that will only be read
 PhysicalAddress         Real address as used on the hardware bus
 BytePtr                 Pointer to an array of bytes
 ByteCount               The size of an array of bytes
 ByteOffset              An offset into an array of bytes
 ItemCount               32-bit iteration count
 OptionBits              Standard 32-bit set of bit flags
 PBVersion               ?
 Duration                32-bit millisecond timer for drivers
 AbsoluteTime            64-bit clock
 ScriptCode              A particular set of written characters (e.g. Roman vs Cyrillic) and their encoding
 LangCode                A particular language (e.g. English), as represented using a particular ScriptCode
 RegionCode              Designates a language as used in a particular region (e.g. British vs American
 English) together with other region-dependent characteristics (e.g. date format)
 FourCharCode            A 32-bit value made by packing four 1 byte characters together
 OSType                  A FourCharCode used in the OS and file system (e.g. creator)
 ResType                 A FourCharCode used to tag resources (e.g. 'DLOG')

 *********************************************************************************/
alias SInt16 OSErr;
alias SInt32 OSStatus;
alias void* LogicalAddress;
alias /*const*/void* ConstLogicalAddress;
alias void* PhysicalAddress;
alias UInt8* BytePtr;
alias uint ByteCount;
alias uint ByteOffset;
alias SInt32 Duration;
alias UnsignedWide AbsoluteTime;
alias UInt32 OptionBits;
alias uint ItemCount;
alias UInt32 PBVersion;
alias SInt16 ScriptCode;
alias SInt16 LangCode;
alias SInt16 RegionCode;
alias UInt32 FourCharCode;
alias FourCharCode OSType;
alias FourCharCode ResType;
alias OSType* OSTypePtr;
alias ResType* ResTypePtr;

struct UnsignedWide
{
    uint hi;
    uint lo;
}

struct ProcessSerialNumber
{
    uint highLongOfPSN;
    uint lowLongOfPSN;
}

alias ProcessSerialNumber * ProcessSerialNumberPtr;