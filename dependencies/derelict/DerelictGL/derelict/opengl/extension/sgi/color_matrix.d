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
module derelict.opengl.extension.sgi.color_matrix;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct SGIColorMatrix
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_SGI_color_matrix") == -1)
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
        DerelictGL.registerExtensionLoader(&SGIColorMatrix.load);
    }
}

enum : GLenum
{
    GL_COLOR_MATRIX_SGI                    = 0x80B1,
    GL_COLOR_MATRIX_STACK_DEPTH_SGI        = 0x80B2,
    GL_MAX_COLOR_MATRIX_STACK_DEPTH_SGI    = 0x80B3,
    GL_POST_COLOR_MATRIX_RED_SCALE_SGI     = 0x80B4,
    GL_POST_COLOR_MATRIX_GREEN_SCALE_SGI   = 0x80B5,
    GL_POST_COLOR_MATRIX_BLUE_SCALE_SGI    = 0x80B6,
    GL_POST_COLOR_MATRIX_ALPHA_SCALE_SGI   = 0x80B7,
    GL_POST_COLOR_MATRIX_RED_BIAS_SGI      = 0x80B8,
    GL_POST_COLOR_MATRIX_GREEN_BIAS_SGI    = 0x80B9,
    GL_POST_COLOR_MATRIX_BLUE_BIAS_SGI     = 0x80BA,
    GL_POST_COLOR_MATRIX_ALPHA_BIAS_SGI    = 0x80BB,
}
