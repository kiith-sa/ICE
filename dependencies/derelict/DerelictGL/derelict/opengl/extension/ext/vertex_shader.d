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
module derelict.opengl.extension.ext.vertex_shader;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTVertexShader
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_vertex_shader") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glBeginVertexShaderEXT, "glBeginVertexShaderEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glEndVertexShaderEXT, "glEndVertexShaderEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindVertexShaderEXT, "glBindVertexShaderEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenVertexShadersEXT, "glGenVertexShadersEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDeleteVertexShaderEXT, "glDeleteVertexShaderEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glShaderOp1EXT, "glShaderOp1EXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glShaderOp2EXT, "glShaderOp2EXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glShaderOp3EXT, "glShaderOp3EXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSwizzleEXT, "glSwizzleEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWriteMaskEXT, "glWriteMaskEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glInsertComponentEXT, "glInsertComponentEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glExtractComponentEXT, "glExtractComponentEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenSymbolsEXT, "glGenSymbolsEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSetInvariantEXT, "glSetInvariantEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSetLocalConstantEXT, "glSetLocalConstantEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantbvEXT, "glVariantbvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantsvEXT, "glVariantsvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantivEXT, "glVariantivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantfvEXT, "glVariantfvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantdvEXT, "glVariantdvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantubvEXT, "glVariantubvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantusvEXT, "glVariantusvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantuivEXT, "glVariantuivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantPointerEXT, "glVariantPointerEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glEnableVariantClientStateEXT, "glEnableVariantClientStateEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDisableVariantClientStateEXT, "glDisableVariantClientStateEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindLightParameterEXT, "glBindLightParameterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindMaterialParameterEXT, "glBindMaterialParameterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindTexGenParameterEXT, "glBindTexGenParameterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindTextureUnitParameterEXT, "glBindTextureUnitParameterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindParameterEXT, "glBindParameterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsVariantEnabledEXT, "glIsVariantEnabledEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantBooleanvEXT, "glGetVariantBooleanvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantIntegervEXT, "glGetVariantIntegervEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantFloatvEXT, "glGetVariantFloatvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantPointervEXT, "glGetVariantPointervEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetInvariantBooleanvEXT, "glGetInvariantBooleanvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetInvariantIntegervEXT, "glGetInvariantIntegervEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetInvariantFloatvEXT, "glGetInvariantFloatvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetLocalConstantBooleanvEXT, "glGetLocalConstantBooleanvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetLocalConstantIntegervEXT, "glGetLocalConstantIntegervEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetLocalConstantFloatvEXT, "glGetLocalConstantFloatvEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTVertexShader.load);
    }
}

enum : GLenum
{
    GL_VERTEX_SHADER_EXT              = 0x8780,
    GL_VERTEX_SHADER_BINDING_EXT      = 0x8781,
    GL_OP_INDEX_EXT                   = 0x8782,
    GL_OP_NEGATE_EXT                  = 0x8783,
    GL_OP_DOT3_EXT                    = 0x8784,
    GL_OP_DOT4_EXT                    = 0x8785,
    GL_OP_MUL_EXT                     = 0x8786,
    GL_OP_ADD_EXT                     = 0x8787,
    GL_OP_MADD_EXT                    = 0x8788,
    GL_OP_FRAC_EXT                    = 0x8789,
    GL_OP_MAX_EXT                     = 0x878A,
    GL_OP_MIN_EXT                     = 0x878B,
    GL_OP_SET_GE_EXT                  = 0x878C,
    GL_OP_SET_LT_EXT                  = 0x878D,
    GL_OP_CLAMP_EXT                   = 0x878E,
    GL_OP_FLOOR_EXT                   = 0x878F,
    GL_OP_ROUND_EXT                   = 0x8790,
    GL_OP_EXP_BASE_2_EXT              = 0x8791,
    GL_OP_LOG_BASE_2_EXT              = 0x8792,
    GL_OP_POWER_EXT                   = 0x8793,
    GL_OP_RECIP_EXT                   = 0x8794,
    GL_OP_RECIP_SQRT_EXT              = 0x8795,
    GL_OP_SUB_EXT                     = 0x8796,
    GL_OP_CROSS_PRODUCT_EXT           = 0x8797,
    GL_OP_MULTIPLY_MATRIX_EXT         = 0x8798,
    GL_OP_MOV_EXT                     = 0x8799,
    GL_OUTPUT_VERTEX_EXT              = 0x879A,
    GL_OUTPUT_COLOR0_EXT              = 0x879B,
    GL_OUTPUT_COLOR1_EXT              = 0x879C,
    GL_OUTPUT_TEXTURE_COORD0_EXT      = 0x879D,
    GL_OUTPUT_TEXTURE_COORD1_EXT      = 0x879E,
    GL_OUTPUT_TEXTURE_COORD2_EXT      = 0x879F,
    GL_OUTPUT_TEXTURE_COORD3_EXT      = 0x87A0,
    GL_OUTPUT_TEXTURE_COORD4_EXT      = 0x87A1,
    GL_OUTPUT_TEXTURE_COORD5_EXT      = 0x87A2,
    GL_OUTPUT_TEXTURE_COORD6_EXT      = 0x87A3,
    GL_OUTPUT_TEXTURE_COORD7_EXT      = 0x87A4,
    GL_OUTPUT_TEXTURE_COORD8_EXT      = 0x87A5,
    GL_OUTPUT_TEXTURE_COORD9_EXT      = 0x87A6,
    GL_OUTPUT_TEXTURE_COORD10_EXT     = 0x87A7,
    GL_OUTPUT_TEXTURE_COORD11_EXT     = 0x87A8,
    GL_OUTPUT_TEXTURE_COORD12_EXT     = 0x87A9,
    GL_OUTPUT_TEXTURE_COORD13_EXT     = 0x87AA,
    GL_OUTPUT_TEXTURE_COORD14_EXT     = 0x87AB,
    GL_OUTPUT_TEXTURE_COORD15_EXT     = 0x87AC,
    GL_OUTPUT_TEXTURE_COORD16_EXT     = 0x87AD,
    GL_OUTPUT_TEXTURE_COORD17_EXT     = 0x87AE,
    GL_OUTPUT_TEXTURE_COORD18_EXT     = 0x87AF,
    GL_OUTPUT_TEXTURE_COORD19_EXT     = 0x87B0,
    GL_OUTPUT_TEXTURE_COORD20_EXT     = 0x87B1,
    GL_OUTPUT_TEXTURE_COORD21_EXT     = 0x87B2,
    GL_OUTPUT_TEXTURE_COORD22_EXT     = 0x87B3,
    GL_OUTPUT_TEXTURE_COORD23_EXT     = 0x87B4,
    GL_OUTPUT_TEXTURE_COORD24_EXT     = 0x87B5,
    GL_OUTPUT_TEXTURE_COORD25_EXT     = 0x87B6,
    GL_OUTPUT_TEXTURE_COORD26_EXT     = 0x87B7,
    GL_OUTPUT_TEXTURE_COORD27_EXT     = 0x87B8,
    GL_OUTPUT_TEXTURE_COORD28_EXT     = 0x87B9,
    GL_OUTPUT_TEXTURE_COORD29_EXT     = 0x87BA,
    GL_OUTPUT_TEXTURE_COORD30_EXT     = 0x87BB,
    GL_OUTPUT_TEXTURE_COORD31_EXT     = 0x87BC,
    GL_OUTPUT_FOG_EXT                 = 0x87BD,
    GL_SCALAR_EXT                     = 0x87BE,
    GL_VECTOR_EXT                     = 0x87BF,
    GL_MATRIX_EXT                     = 0x87C0,
    GL_VARIANT_EXT                    = 0x87C1,
    GL_INVARIANT_EXT                  = 0x87C2,
    GL_LOCAL_CONSTANT_EXT             = 0x87C3,
    GL_LOCAL_EXT                      = 0x87C4,
    GL_MAX_VERTEX_SHADER_INSTRUCTIONS_EXT = 0x87C5,
    GL_MAX_VERTEX_SHADER_VARIANTS_EXT = 0x87C6,
    GL_MAX_VERTEX_SHADER_INVARIANTS_EXT = 0x87C7,
    GL_MAX_VERTEX_SHADER_LOCAL_CONSTANTS_EXT = 0x87C8,
    GL_MAX_VERTEX_SHADER_LOCALS_EXT   = 0x87C9,
    GL_MAX_OPTIMIZED_VERTEX_SHADER_INSTRUCTIONS_EXT = 0x87CA,
    GL_MAX_OPTIMIZED_VERTEX_SHADER_VARIANTS_EXT = 0x87CB,
    GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCAL_CONSTANTS_EXT = 0x87CC,
    GL_MAX_OPTIMIZED_VERTEX_SHADER_INVARIANTS_EXT = 0x87CD,
    GL_MAX_OPTIMIZED_VERTEX_SHADER_LOCALS_EXT = 0x87CE,
    GL_VERTEX_SHADER_INSTRUCTIONS_EXT = 0x87CF,
    GL_VERTEX_SHADER_VARIANTS_EXT     = 0x87D0,
    GL_VERTEX_SHADER_INVARIANTS_EXT   = 0x87D1,
    GL_VERTEX_SHADER_LOCAL_CONSTANTS_EXT = 0x87D2,
    GL_VERTEX_SHADER_LOCALS_EXT       = 0x87D3,
    GL_VERTEX_SHADER_OPTIMIZED_EXT    = 0x87D4,
    GL_X_EXT                          = 0x87D5,
    GL_Y_EXT                          = 0x87D6,
    GL_Z_EXT                          = 0x87D7,
    GL_W_EXT                          = 0x87D8,
    GL_NEGATIVE_X_EXT                 = 0x87D9,
    GL_NEGATIVE_Y_EXT                 = 0x87DA,
    GL_NEGATIVE_Z_EXT                 = 0x87DB,
    GL_NEGATIVE_W_EXT                 = 0x87DC,
    GL_ZERO_EXT                       = 0x87DD,
    GL_ONE_EXT                        = 0x87DE,
    GL_NEGATIVE_ONE_EXT               = 0x87DF,
    GL_NORMALIZED_RANGE_EXT           = 0x87E0,
    GL_FULL_RANGE_EXT                 = 0x87E1,
    GL_CURRENT_VERTEX_EXT             = 0x87E2,
    GL_MVP_MATRIX_EXT                 = 0x87E3,
    GL_VARIANT_VALUE_EXT              = 0x87E4,
    GL_VARIANT_DATATYPE_EXT           = 0x87E5,
    GL_VARIANT_ARRAY_STRIDE_EXT       = 0x87E6,
    GL_VARIANT_ARRAY_TYPE_EXT         = 0x87E7,
    GL_VARIANT_ARRAY_EXT              = 0x87E8,
    GL_VARIANT_ARRAY_POINTER_EXT      = 0x87E9,
    GL_INVARIANT_VALUE_EXT            = 0x87EA,
    GL_INVARIANT_DATATYPE_EXT         = 0x87EB,
    GL_LOCAL_CONSTANT_VALUE_EXT       = 0x87EC,
    GL_LOCAL_CONSTANT_DATATYPE_EXT    = 0x87ED,
}

extern(System)
{
    void function() glBeginVertexShaderEXT;
    void function() glEndVertexShaderEXT;
    void function(GLuint) glBindVertexShaderEXT;
    GLuint function(GLuint) glGenVertexShadersEXT;
    void function(GLuint) glDeleteVertexShaderEXT;
    void function(GLenum,GLuint,GLuint) glShaderOp1EXT;
    void function(GLenum,GLuint,GLuint,GLuint) glShaderOp2EXT;
    void function(GLenum,GLuint,GLuint,GLuint,GLuint) glShaderOp3EXT;
    void function(GLuint,GLuint,GLenum,GLenum,GLenum,GLenum) glSwizzleEXT;
    void function(GLuint,GLuint,GLenum,GLenum,GLenum,GLenum) glWriteMaskEXT;
    void function(GLuint,GLuint,GLuint) glInsertComponentEXT;
    void function(GLuint,GLuint,GLuint) glExtractComponentEXT;
    GLuint function(GLenum,GLenum,GLenum,GLuint) glGenSymbolsEXT;
    void function(GLuint,GLenum,GLvoid*) glSetInvariantEXT;
    void function(GLuint,GLenum,GLvoid*) glSetLocalConstantEXT;
    void function(GLuint,GLbyte*) glVariantbvEXT;
    void function(GLuint,GLshort*) glVariantsvEXT;
    void function(GLuint,GLint*) glVariantivEXT;
    void function(GLuint,GLfloat*) glVariantfvEXT;
    void function(GLuint,GLdouble*) glVariantdvEXT;
    void function(GLuint,GLubyte*) glVariantubvEXT;
    void function(GLuint,GLushort*) glVariantusvEXT;
    void function(GLuint,GLuint*) glVariantuivEXT;
    void function(GLuint,GLenum,GLuint,GLvoid*) glVariantPointerEXT;
    void function(GLuint) glEnableVariantClientStateEXT;
    void function(GLuint) glDisableVariantClientStateEXT;
    GLuint function(GLenum,GLenum) glBindLightParameterEXT;
    GLuint function(GLenum,GLenum) glBindMaterialParameterEXT;
    GLuint function(GLenum,GLenum,GLenum) glBindTexGenParameterEXT;
    GLuint function(GLenum,GLenum) glBindTextureUnitParameterEXT;
    GLuint function(GLenum) glBindParameterEXT;
    GLboolean function(GLuint,GLenum) glIsVariantEnabledEXT;
    void function(GLuint,GLenum,GLboolean*) glGetVariantBooleanvEXT;
    void function(GLuint,GLenum,GLint*) glGetVariantIntegervEXT;
    void function(GLuint,GLenum,GLfloat*) glGetVariantFloatvEXT;
    void function(GLuint,GLenum,GLvoid*) glGetVariantPointervEXT;
    void function(GLuint,GLenum,GLboolean*) glGetInvariantBooleanvEXT;
    void function(GLuint,GLenum,GLint*) glGetInvariantIntegervEXT;
    void function(GLuint,GLenum,GLfloat*) glGetInvariantFloatvEXT;
    void function(GLuint,GLenum,GLboolean*) glGetLocalConstantBooleanvEXT;
    void function(GLuint,GLenum,GLint*) glGetLocalConstantIntegervEXT;
    void function(GLuint,GLenum,GLfloat*) glGetLocalConstantFloatvEXT;
}