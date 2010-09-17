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
module derelict.opengl.extension.ext.texture_sRGB;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTTextureSRGB
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_texture_sRGB") == -1)
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
        DerelictGL.registerExtensionLoader(&EXTTextureSRGB.load);
    }
}

enum : GLenum
{
    GL_SRGB_EXT                            = 0x8C40,
    GL_SRGB8_EXT                           = 0x8C41,
    GL_SRGB_ALPHA_EXT                      = 0x8C42,
    GL_SRGB8_ALPHA8_EXT                    = 0x8C43,
    GL_SLUMINANCE_ALPHA_EXT                = 0x8C44,
    GL_SLUMINANCE8_ALPHA8_EXT              = 0x8C45,
    GL_SLUMINANCE_EXT                      = 0x8C46,
    GL_SLUMINANCE8_EXT                     = 0x8C47,
    GL_COMPRESSED_SRGB_EXT                 = 0x8C48,
    GL_COMPRESSED_SRGB_ALPHA_EXT           = 0x8C49,
    GL_COMPRESSED_SLUMINANCE_EXT           = 0x8C4A,
    GL_COMPRESSED_SLUMINANCE_ALPHA_EXT     = 0x8C4B,
    GL_COMPRESSED_SRGB_S3TC_DXT1_EXT       = 0x8C4C,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT = 0x8C4D,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT = 0x8C4E,
    GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT = 0x8C4F,
}
