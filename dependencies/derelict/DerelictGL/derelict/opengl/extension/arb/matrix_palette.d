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
 * * Neither the names 'Derelict', 'DerelictGL', nor the names of its contributors
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
module derelict.opengl.extension.arb.matrix_palette;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBMatrixPalette
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_matrix_palette") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glCurrentPaletteMatrixARB, "glCurrentPaletteMatrixARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMatrixIndexubvARB, "glMatrixIndexubvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMatrixIndexusvARB, "glMatrixIndexusvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMatrixIndexuivARB, "glMatrixIndexuivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMatrixIndexPointerARB, "glMatrixIndexPointerARB"))
            return false;

        enabled = true;
        return true;
    }

    static bool isEnabled()
    {
        return enabled;
    }
}

version(DerelictGL_NoExtensionLoaders)
{
}
else
{
    static this()
    {
        DerelictGL.registerExtensionLoader(&ARBMatrixPalette.load);
    }
}

enum : GLenum
{
    GL_MATRIX_PALETTE_ARB                   = 0x8840,
    GL_MAX_MATRIX_PALETTE_STACK_DEPTH_ARB   = 0x8841,
    GL_MAX_PALETTE_MATRICES_ARB             = 0x8842,
    GL_CURRENT_PALETTE_MATRIX_ARB           = 0x8843,
    GL_MATRIX_INDEX_ARRAY_ARB               = 0x8844,
    GL_CURRENT_MATRIX_INDEX_ARB             = 0x8845,
    GL_MATRIX_INDEX_ARRAY_SIZE_ARB          = 0x8846,
    GL_MATRIX_INDEX_ARRAY_TYPE_ARB          = 0x8847,
    GL_MATRIX_INDEX_ARRAY_STRIDE_ARB        = 0x8848,
    GL_MATRIX_INDEX_ARRAY_POINTER_ARB       = 0x8849,
}

extern(System)
{
    void function(GLint) glCurrentPaletteMatrixARB;
    void function(GLint, GLubyte*) glMatrixIndexubvARB;
    void function(GLint, GLushort*) glMatrixIndexusvARB;
    void function(GLint, GLuint*) glMatrixIndexuivARB;
    void function(GLint, GLenum, GLsizei, GLvoid*) glMatrixIndexPointerARB;
}