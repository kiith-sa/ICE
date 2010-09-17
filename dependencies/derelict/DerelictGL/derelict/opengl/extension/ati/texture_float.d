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
module derelict.opengl.extension.ati.texture_float;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ATITextureFloat
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ATI_texture_float") == -1)
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
        DerelictGL.registerExtensionLoader(&ATITextureFloat.load);
    }
}

enum : GLenum
{
    GL_RGBA_FLOAT32_ATI               = 0x8814,
    GL_RGB_FLOAT32_ATI                = 0x8815,
    GL_ALPHA_FLOAT32_ATI              = 0x8816,
    GL_INTENSITY_FLOAT32_ATI          = 0x8817,
    GL_LUMINANCE_FLOAT32_ATI          = 0x8818,
    GL_LUMINANCE_ALPHA_FLOAT32_ATI    = 0x8819,
    GL_RGBA_FLOAT16_ATI               = 0x881A,
    GL_RGB_FLOAT16_ATI                = 0x881B,
    GL_ALPHA_FLOAT16_ATI              = 0x881C,
    GL_INTENSITY_FLOAT16_ATI          = 0x881D,
    GL_LUMINANCE_FLOAT16_ATI          = 0x881E,
    GL_LUMINANCE_ALPHA_FLOAT16_ATI    = 0x881F,
}
