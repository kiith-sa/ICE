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
module derelict.util.wintypes;

version(Windows)
{
    alias uint DWORD;
    alias ushort WORD;
    alias uint UINT;
    alias int LONG;
    alias ubyte BYTE;
    alias float FLOAT;
    alias int BOOL;
    alias DWORD COLORREF;
    alias char* LPCSTR;
    alias void* LPCVOID;

    alias void* HANDLE;
    alias HANDLE HDC;
    alias HANDLE HGLRC;
    alias HANDLE HMODULE;
    alias HANDLE HWND;
    alias HANDLE HLOCAL;

    alias UINT WPARAM;
    alias LONG LPARAM;

    alias int(*FARPROC)();

    struct LAYERPLANEDESCRIPTOR
    {
        WORD nSize;
        WORD nVersion;
        DWORD dwFlags;
        BYTE iPixelType;
        BYTE cColorBits;
        BYTE cRedBits;
        BYTE cRedShift;
        BYTE cGreenBits;
        BYTE cGreenShift;
        BYTE cBlueBits;
        BYTE cBlueShift;
        BYTE cAlphaBits;
        BYTE cAlphaShift;
        BYTE cAccumBits;
        BYTE cAccumRedBits;
        BYTE cAccumGreenBits;
        BYTE cAccumBlueBits;
        BYTE cAccumAlphaBits;
        BYTE cDepthBits;
        BYTE cStencilBits;
        BYTE cAuxBuffers;
        BYTE iLayerPlane;
        BYTE bReserved;
        COLORREF crTransparent;
    }

    struct POINTFLOAT
    {
        FLOAT x;
        FLOAT y;
    }

    struct GLYPHMETRICSFLOAT
    {
        FLOAT gmfBlackBoxX;
        FLOAT gmfBlackBoxY;
        POINTFLOAT gmfptGlyphOrigin;
        FLOAT gmfCellIncX;
        FLOAT gmfCellIncY;
    }

    struct PIXELFORMATDESCRIPTOR
    {
        WORD  nSize;
        WORD  nVersion;
        DWORD dwFlags;
        BYTE  iPixelType;
        BYTE  cColorBits;
        BYTE  cRedBits;
        BYTE  cRedShift;
        BYTE  cGreenBits;
        BYTE  cGreenShift;
        BYTE  cBlueBits;
        BYTE  cBlueShift;
        BYTE  cAlphaBits;
        BYTE  cAlphaShift;
        BYTE  cAccumBits;
        BYTE  cAccumRedBits;
        BYTE  cAccumGreenBits;
        BYTE  cAccumBlueBits;
        BYTE  cAccumAlphaBits;
        BYTE  cDepthBits;
        BYTE  cStencilBits;
        BYTE  cAuxBuffers;
        BYTE  iLayerType;
        BYTE  bReserved;
        DWORD dwLayerMask;
        DWORD dwVisibleMask;
        DWORD dwDamageMask;
    }
    
    struct VA_LIST
    {
    }

    /* pixel types */
    enum
    {
        PFD_TYPE_RGBA                   = 0,
        PFD_TYPE_COLORINDEX             = 1
    }

    /* layer types */
    enum
    {
        PFD_MAIN_PLANE                  = 0,
        PFD_OVERLAY_PLANE               = 1,
        PFD_UNDERLAY_PLANE              = -1
    }

    enum
    {
        /* PIXELFORMATDESCRIPTOR flags */
        PFD_DOUBLEBUFFER                = 0x00000001,
        PFD_STEREO                      = 0x00000002,
        PFD_DRAW_TO_WINDOW              = 0x00000004,
        PFD_DRAW_TO_BITMAP              = 0x00000008,
        PFD_SUPPORT_GDI                 = 0x00000010,
        PFD_SUPPORT_OPENGL              = 0x00000020,
        PFD_GENERIC_FORMAT              = 0x00000040,
        PFD_NEED_PALETTE                = 0x00000080,
        PFD_NEED_SYSTEM_PALETTE         = 0x00000100,
        PFD_SWAP_EXCHANGE               = 0x00000200,
        PFD_SWAP_COPY                   = 0x00000400,
        PFD_SWAP_LAYER_BUFFERS          = 0x00000800,
        PFD_GENERIC_ACCELERATED         = 0x00001000,
        PFD_SUPPORT_DIRECTDRAW          = 0x00002000,

        /* PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only */
        PFD_DEPTH_DONTCARE              = 0x20000000,
        PFD_DOUBLBUFFER_DONTCARE        = 0x40000000,
        PFD_STEREO_DONTCARE             = 0x80000000,
    }

    enum
    {
        LANG_NEUTRAL                    = 0,
        SUBLANG_DEFAULT                 = 1,
        FORMAT_MESSAGE_ALLOCATE_BUFFER  = 256,
        FORMAT_MESSAGE_IGNORE_INSERTS   = 512,
        FORMAT_MESSAGE_FROM_SYSTEM      = 4096
    }

    extern(Windows)
    {
        int ChoosePixelFormat(HDC,PIXELFORMATDESCRIPTOR*);
        int GetPixelFormat(HDC);
        int DescribePixelFormat(HDC,int,UINT,PIXELFORMATDESCRIPTOR*);
        BOOL SwapBuffers(HDC);

        HMODULE LoadLibraryA(char* name);
        FARPROC GetProcAddress(HMODULE hm, char* name);
        void FreeLibrary(HMODULE hm);
        DWORD GetLastError();
        DWORD FormatMessageA(DWORD, LPCVOID, DWORD, DWORD, LPCSTR, DWORD, VA_LIST*);
        HLOCAL LocalFree(HLOCAL);
    }
    
    DWORD MAKELANGID(WORD p, WORD s)
    {
         return (((cast(WORD)s) << 10) | cast(WORD)p);
    }
}