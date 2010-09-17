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
module derelict.opengl.extension.nv.register_combiners;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVRegisterCombiners
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_register_combiners") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glCombinerParameterfvNV, "glCombinerParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCombinerParameterfNV, "glCombinerParameterfNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCombinerParameterivNV, "glCombinerParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCombinerParameteriNV, "glCombinerParameteriNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCombinerInputNV, "glCombinerInputNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCombinerOutputNV, "glCombinerOutputNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFinalCombinerInputNV, "glFinalCombinerInputNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetCombinerInputParameterfvNV, "glGetCombinerInputParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetCombinerInputParameterivNV, "glGetCombinerInputParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetCombinerOutputParameterfvNV, "glGetCombinerOutputParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetCombinerOutputParameterivNV, "glGetCombinerOutputParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetFinalCombinerInputParameterfvNV, "glGetFinalCombinerInputParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetFinalCombinerInputParameterivNV, "glGetFinalCombinerInputParameterivNV"))
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
        DerelictGL.registerExtensionLoader(&NVRegisterCombiners.load);
    }
}

enum : GLenum
{
    GL_REGISTER_COMBINERS_NV          = 0x8522,
    GL_VARIABLE_A_NV                  = 0x8523,
    GL_VARIABLE_B_NV                  = 0x8524,
    GL_VARIABLE_C_NV                  = 0x8525,
    GL_VARIABLE_D_NV                  = 0x8526,
    GL_VARIABLE_E_NV                  = 0x8527,
    GL_VARIABLE_F_NV                  = 0x8528,
    GL_VARIABLE_G_NV                  = 0x8529,
    GL_CONSTANT_COLOR0_NV             = 0x852A,
    GL_CONSTANT_COLOR1_NV             = 0x852B,
    GL_PRIMARY_COLOR_NV               = 0x852C,
    GL_SECONDARY_COLOR_NV             = 0x852D,
    GL_SPARE0_NV                      = 0x852E,
    GL_SPARE1_NV                      = 0x852F,
    GL_DISCARD_NV                     = 0x8530,
    GL_E_TIMES_F_NV                   = 0x8531,
    GL_SPARE0_PLUS_SECONDARY_COLOR_NV = 0x8532,
    GL_UNSIGNED_IDENTITY_NV           = 0x8536,
    GL_UNSIGNED_INVERT_NV             = 0x8537,
    GL_EXPAND_NORMAL_NV               = 0x8538,
    GL_EXPAND_NEGATE_NV               = 0x8539,
    GL_HALF_BIAS_NORMAL_NV            = 0x853A,
    GL_HALF_BIAS_NEGATE_NV            = 0x853B,
    GL_SIGNED_IDENTITY_NV             = 0x853C,
    GL_SIGNED_NEGATE_NV               = 0x853D,
    GL_SCALE_BY_TWO_NV                = 0x853E,
    GL_SCALE_BY_FOUR_NV               = 0x853F,
    GL_SCALE_BY_ONE_HALF_NV           = 0x8540,
    GL_BIAS_BY_NEGATIVE_ONE_HALF_NV   = 0x8541,
    GL_COMBINER_INPUT_NV              = 0x8542,
    GL_COMBINER_MAPPING_NV            = 0x8543,
    GL_COMBINER_COMPONENT_USAGE_NV    = 0x8544,
    GL_COMBINER_AB_DOT_PRODUCT_NV     = 0x8545,
    GL_COMBINER_CD_DOT_PRODUCT_NV     = 0x8546,
    GL_COMBINER_MUX_SUM_NV            = 0x8547,
    GL_COMBINER_SCALE_NV              = 0x8548,
    GL_COMBINER_BIAS_NV               = 0x8549,
    GL_COMBINER_AB_OUTPUT_NV          = 0x854A,
    GL_COMBINER_CD_OUTPUT_NV          = 0x854B,
    GL_COMBINER_SUM_OUTPUT_NV         = 0x854C,
    GL_MAX_GENERAL_COMBINERS_NV       = 0x854D,
    GL_NUM_GENERAL_COMBINERS_NV       = 0x854E,
    GL_COLOR_SUM_CLAMP_NV             = 0x854F,
    GL_COMBINER0_NV                   = 0x8550,
    GL_COMBINER1_NV                   = 0x8551,
    GL_COMBINER2_NV                   = 0x8552,
    GL_COMBINER3_NV                   = 0x8553,
    GL_COMBINER4_NV                   = 0x8554,
    GL_COMBINER5_NV                   = 0x8555,
    GL_COMBINER6_NV                   = 0x8556,
    GL_COMBINER7_NV                   = 0x8557,
}

extern(System)
{
    void function(GLenum, GLfloat*) glCombinerParameterfvNV;
    void function(GLenum, GLfloat) glCombinerParameterfNV;
    void function(GLenum, GLint*) glCombinerParameterivNV;
    void function(GLenum, GLint) glCombinerParameteriNV;
    void function(GLenum, GLenum, GLenum, GLenum, GLenum, GLenum) glCombinerInputNV;
    void function(GLenum, GLenum, GLenum, GLenum, GLenum, GLenum, GLenum, GLboolean, GLboolean, GLboolean) glCombinerOutputNV;
    void function(GLenum, GLenum, GLenum, GLenum) glFinalCombinerInputNV;
    void function(GLenum, GLenum, GLenum, GLenum, GLfloat*) glGetCombinerInputParameterfvNV;
    void function(GLenum, GLenum, GLenum, GLenum, GLint*) glGetCombinerInputParameterivNV;
    void function(GLenum, GLenum, GLenum, GLfloat*) glGetCombinerOutputParameterfvNV;
    void function(GLenum, GLenum, GLenum, GLint*) glGetCombinerOutputParameterivNV;
    void function(GLenum, GLenum, GLfloat*) glGetFinalCombinerInputParameterfvNV;
    void function(GLenum, GLenum, GLint*) glGetFinalCombinerInputParameterivNV;
}