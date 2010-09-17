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
module derelict.opengl.extension.nv.texture_shader;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVTextureShader
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_texture_shader") == -1)
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
        DerelictGL.registerExtensionLoader(&NVTextureShader.load);
    }
}

enum : GLenum
{
    GL_OFFSET_TEXTURE_RECTANGLE_NV             = 0x864C,
    GL_OFFSET_TEXTURE_RECTANGLE_SCALE_NV       = 0x864D,
    GL_DOT_PRODUCT_TEXTURE_RECTANGLE_NV        = 0x864E,
    GL_RGBA_UNSIGNED_DOT_PRODUCT_MAPPING_NV    = 0x86D9,
    GL_UNSIGNED_INT_S8_S8_8_8_NV               = 0x86DA,
    GL_UNSIGNED_INT_8_8_S8_S8_REV_NV           = 0x86DB,
    GL_DSDT_MAG_INTENSITY_NV                   = 0x86DC,
    GL_SHADER_CONSISTENT_NV                    = 0x86DD,
    GL_TEXTURE_SHADER_NV                       = 0x86DE,
    GL_SHADER_OPERATION_NV                     = 0x86DF,
    GL_CULL_MODES_NV                           = 0x86E0,
    GL_OFFSET_TEXTURE_MATRIX_NV                = 0x86E1,
    GL_OFFSET_TEXTURE_SCALE_NV                 = 0x86E2,
    GL_OFFSET_TEXTURE_BIAS_NV                  = 0x86E3,
    GL_OFFSET_TEXTURE_2D_MATRIX_NV             = GL_OFFSET_TEXTURE_MATRIX_NV,
    GL_OFFSET_TEXTURE_2D_SCALE_NV              = GL_OFFSET_TEXTURE_SCALE_NV,
    GL_OFFSET_TEXTURE_2D_BIAS_NV               = GL_OFFSET_TEXTURE_BIAS_NV,
    GL_PREVIOUS_TEXTURE_INPUT_NV               = 0x86E4,
    GL_CONST_EYE_NV                            = 0x86E5,
    GL_PASS_THROUGH_NV                         = 0x86E6,
    GL_CULL_FRAGMENT_NV                        = 0x86E7,
    GL_OFFSET_TEXTURE_2D_NV                    = 0x86E8,
    GL_DEPENDENT_AR_TEXTURE_2D_NV              = 0x86E9,
    GL_DEPENDENT_GB_TEXTURE_2D_NV              = 0x86EA,
    GL_DOT_PRODUCT_NV                          = 0x86EC,
    GL_DOT_PRODUCT_DEPTH_REPLACE_NV            = 0x86ED,
    GL_DOT_PRODUCT_TEXTURE_2D_NV               = 0x86EE,
    GL_DOT_PRODUCT_TEXTURE_CUBE_MAP_NV         = 0x86F0,
    GL_DOT_PRODUCT_DIFFUSE_CUBE_MAP_NV         = 0x86F1,
    GL_DOT_PRODUCT_REFLECT_CUBE_MAP_NV         = 0x86F2,
    GL_DOT_PRODUCT_CONST_EYE_REFLECT_CUBE_MAP_NV = 0x86F3,
    GL_HILO_NV                                 = 0x86F4,
    GL_DSDT_NV                                 = 0x86F5,
    GL_DSDT_MAG_NV                             = 0x86F6,
    GL_DSDT_MAG_VIB_NV                         = 0x86F7,
    GL_HILO16_NV                               = 0x86F8,
    GL_SIGNED_HILO_NV                          = 0x86F9,
    GL_SIGNED_HILO16_NV                        = 0x86FA,
    GL_SIGNED_RGBA_NV                          = 0x86FB,
    GL_SIGNED_RGBA8_NV                         = 0x86FC,
    GL_SIGNED_RGB_NV                           = 0x86FE,
    GL_SIGNED_RGB8_NV                          = 0x86FF,
    GL_SIGNED_LUMINANCE_NV                     = 0x8701,
    GL_SIGNED_LUMINANCE8_NV                    = 0x8702,
    GL_SIGNED_LUMINANCE_ALPHA_NV               = 0x8703,
    GL_SIGNED_LUMINANCE8_ALPHA8_NV             = 0x8704,
    GL_SIGNED_ALPHA_NV                         = 0x8705,
    GL_SIGNED_ALPHA8_NV                        = 0x8706,
    GL_SIGNED_INTENSITY_NV                     = 0x8707,
    GL_SIGNED_INTENSITY8_NV                    = 0x8708,
    GL_DSDT8_NV                                = 0x8709,
    GL_DSDT8_MAG8_NV                           = 0x870A,
    GL_DSDT8_MAG8_INTENSITY8_NV                = 0x870B,
    GL_SIGNED_RGB_UNSIGNED_ALPHA_NV            = 0x870C,
    GL_SIGNED_RGB8_UNSIGNED_ALPHA8_NV          = 0x870D,
    GL_HI_SCALE_NV                             = 0x870E,
    GL_LO_SCALE_NV                             = 0x870F,
    GL_DS_SCALE_NV                             = 0x8710,
    GL_DT_SCALE_NV                             = 0x8711,
    GL_MAGNITUDE_SCALE_NV                      = 0x8712,
    GL_VIBRANCE_SCALE_NV                       = 0x8713,
    GL_HI_BIAS_NV                              = 0x8714,
    GL_LO_BIAS_NV                              = 0x8715,
    GL_DS_BIAS_NV                              = 0x8716,
    GL_DT_BIAS_NV                              = 0x8717,
    GL_MAGNITUDE_BIAS_NV                       = 0x8718,
    GL_VIBRANCE_BIAS_NV                        = 0x8719,
    GL_TEXTURE_BORDER_VALUES_NV                = 0x871A,
    GL_TEXTURE_HI_SIZE_NV                      = 0x871B,
    GL_TEXTURE_LO_SIZE_NV                      = 0x871C,
    GL_TEXTURE_DS_SIZE_NV                      = 0x871D,
    GL_TEXTURE_DT_SIZE_NV                      = 0x871E,
    GL_TEXTURE_MAG_SIZE_NV                     = 0x871F,
}
