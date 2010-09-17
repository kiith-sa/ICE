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
module derelict.opengl.extension.nv.texture_shader3;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVTextureShader3
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_texture_shader3") == -1)
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
        DerelictGL.registerExtensionLoader(&NVTextureShader3.load);
    }
}

enum : GLenum
{
    GL_OFFSET_PROJECTIVE_TEXTURE_2D_NV                 = 0x8850,
    GL_OFFSET_PROJECTIVE_TEXTURE_2D_SCALE_NV           = 0x8851,
    GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_NV          = 0x8852,
    GL_OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_SCALE_NV    = 0x8853,
    GL_OFFSET_HILO_TEXTURE_2D_NV                       = 0x8854,
    GL_OFFSET_HILO_TEXTURE_RECTANGLE_NV                = 0x8855,
    GL_OFFSET_HILO_PROJECTIVE_TEXTURE_2D_NV            = 0x8856,
    GL_OFFSET_HILO_PROJECTIVE_TEXTURE_RECTANGLE_NV     = 0x8857,
    GL_DEPENDENT_HILO_TEXTURE_2D_NV                    = 0x8858,
    GL_DEPENDENT_RGB_TEXTURE_3D_NV                     = 0x8859,
    GL_DEPENDENT_RGB_TEXTURE_CUBE_MAP_NV               = 0x885A,
    GL_DOT_PRODUCT_PASS_THROUGH_NV                     = 0x885B,
    GL_DOT_PRODUCT_TEXTURE_1D_NV                       = 0x885C,
    GL_DOT_PRODUCT_AFFINE_DEPTH_REPLACE_NV             = 0x885D,
    GL_HILO8_NV                                        = 0x885E,
    GL_SIGNED_HILO8_NV                                 = 0x885F,
    GL_FORCE_BLUE_TO_ONE_NV                            = 0x8860,
}
