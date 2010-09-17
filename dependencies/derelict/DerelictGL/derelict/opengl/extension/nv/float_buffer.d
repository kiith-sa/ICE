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
module derelict.opengl.extension.nv.float_buffer;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVFloatBuffer
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_float_buffer") == -1)
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
        DerelictGL.registerExtensionLoader(&NVFloatBuffer.load);
    }
}

enum : GLenum
{
    GL_FLOAT_R_NV                     = 0x8880,
    GL_FLOAT_RG_NV                    = 0x8881,
    GL_FLOAT_RGB_NV                   = 0x8882,
    GL_FLOAT_RGBA_NV                  = 0x8883,
    GL_FLOAT_R16_NV                   = 0x8884,
    GL_FLOAT_R32_NV                   = 0x8885,
    GL_FLOAT_RG16_NV                  = 0x8886,
    GL_FLOAT_RG32_NV                  = 0x8887,
    GL_FLOAT_RGB16_NV                 = 0x8888,
    GL_FLOAT_RGB32_NV                 = 0x8889,
    GL_FLOAT_RGBA16_NV                = 0x888A,
    GL_FLOAT_RGBA32_NV                = 0x888B,
    GL_TEXTURE_FLOAT_COMPONENTS_NV    = 0x888C,
    GL_FLOAT_CLEAR_COLOR_VALUE_NV     = 0x888D,
    GL_FLOAT_RGBA_MODE_NV             = 0x888E,
}
