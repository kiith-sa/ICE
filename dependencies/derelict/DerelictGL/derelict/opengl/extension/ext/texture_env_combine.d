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
module derelict.opengl.extension.ext.texture_env_combine;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTTextureEnvCombine
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_texture_env_combine") == -1)
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
        DerelictGL.registerExtensionLoader(&EXTTextureEnvCombine.load);
    }
}

enum : GLenum
{
    GL_COMBINE_EXT                    = 0x8570,
    GL_COMBINE_RGB_EXT                = 0x8571,
    GL_COMBINE_ALPHA_EXT              = 0x8572,
    GL_RGB_SCALE_EXT                  = 0x8573,
    GL_ADD_SIGNED_EXT                 = 0x8574,
    GL_INTERPOLATE_EXT                = 0x8575,
    GL_CONSTANT_EXT                   = 0x8576,
    GL_PRIMARY_COLOR_EXT              = 0x8577,
    GL_PREVIOUS_EXT                   = 0x8578,
    GL_SOURCE0_RGB_EXT                = 0x8580,
    GL_SOURCE1_RGB_EXT                = 0x8581,
    GL_SOURCE2_RGB_EXT                = 0x8582,
    GL_SOURCE0_ALPHA_EXT              = 0x8588,
    GL_SOURCE1_ALPHA_EXT              = 0x8589,
    GL_SOURCE2_ALPHA_EXT              = 0x858A,
    GL_OPERAND0_RGB_EXT               = 0x8590,
    GL_OPERAND1_RGB_EXT               = 0x8591,
    GL_OPERAND2_RGB_EXT               = 0x8592,
    GL_OPERAND0_ALPHA_EXT             = 0x8598,
    GL_OPERAND1_ALPHA_EXT             = 0x8599,
    GL_OPERAND2_ALPHA_EXT             = 0x859A,
}
