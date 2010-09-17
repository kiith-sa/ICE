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
module derelict.opengl.extension.arb.vertex_program;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBVertexProgram
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_vertex_program") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1dARB, "glVertexAttrib1dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1dvARB, "glVertexAttrib1dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1fARB, "glVertexAttrib1fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1fvARB, "glVertexAttrib1fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1sARB, "glVertexAttrib1sARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1svARB, "glVertexAttrib1svARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2dARB, "glVertexAttrib2dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2dvARB, "glVertexAttrib2dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2fARB, "glVertexAttrib2fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2fvARB, "glVertexAttrib2fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2sARB, "glVertexAttrib2sARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2svARB, "glVertexAttrib2svARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3dARB, "glVertexAttrib3dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3dvARB, "glVertexAttrib3dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3fARB, "glVertexAttrib3fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3fvARB, "glVertexAttrib3fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3sARB, "glVertexAttrib3sARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3svARB, "glVertexAttrib3svARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NbvARB, "glVertexAttrib4NbvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NivARB, "glVertexAttrib4NivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NsvARB, "glVertexAttrib4NsvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NubARB, "glVertexAttrib4NubARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NubvARB, "glVertexAttrib4NubvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NuivARB, "glVertexAttrib4NuivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4NusvARB, "glVertexAttrib4NusvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4bvARB, "glVertexAttrib4bvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4dARB, "glVertexAttrib4dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4dvARB, "glVertexAttrib4dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4fARB, "glVertexAttrib4fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4fvARB, "glVertexAttrib4fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4ivARB, "glVertexAttrib4ivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4sARB, "glVertexAttrib4sARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4svARB, "glVertexAttrib4svARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4ubvARB, "glVertexAttrib4ubvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4uivARB, "glVertexAttrib4uivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4usvARB, "glVertexAttrib4usvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribPointerARB, "glVertexAttribPointerARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glEnableVertexAttribArrayARB, "glEnableVertexAttribArrayARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDisableVertexAttribArrayARB, "glDisableVertexAttribArrayARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramStringARB, "glProgramStringARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindProgramARB, "glBindProgramARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDeleteProgramsARB, "glDeleteProgramsARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenProgramsARB, "glGenProgramsARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameter4dARB, "glProgramEnvParameter4dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameter4dvARB, "glProgramEnvParameter4dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameter4fARB, "glProgramEnvParameter4fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameter4fvARB, "glProgramEnvParameter4fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameter4dARB, "glProgramLocalParameter4dARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameter4dvARB, "glProgramLocalParameter4dvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameter4fARB, "glProgramLocalParameter4fARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameter4fvARB, "glProgramLocalParameter4fvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramEnvParameterdvARB, "glGetProgramEnvParameterdvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramEnvParameterfvARB, "glGetProgramEnvParameterfvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramLocalParameterdvARB, "glGetProgramLocalParameterdvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramLocalParameterfvARB, "glGetProgramLocalParameterfvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramivARB, "glGetProgramivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramStringARB, "glGetProgramStringARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribdvARB, "glGetVertexAttribdvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribfvARB, "glGetVertexAttribfvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribivARB, "glGetVertexAttribivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribPointervARB, "glGetVertexAttribPointervARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsProgramARB, "glIsProgramARB"))
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
        DerelictGL.registerExtensionLoader(&ARBVertexProgram.load);
    }
}

enum : GLenum
{
    GL_COLOR_SUM_ARB                           = 0x8458,
    GL_VERTEX_PROGRAM_ARB                      = 0x8620,
    GL_VERTEX_ATTRIB_ARRAY_ENABLED_ARB         = 0x8622,
    GL_VERTEX_ATTRIB_ARRAY_SIZE_ARB            = 0x8623,
    GL_VERTEX_ATTRIB_ARRAY_STRIDE_ARB          = 0x8624,
    GL_VERTEX_ATTRIB_ARRAY_TYPE_ARB            = 0x8625,
    GL_CURRENT_VERTEX_ATTRIB_ARB               = 0x8626,
    GL_PROGRAM_LENGTH_ARB                      = 0x8627,
    GL_PROGRAM_STRING_ARB                      = 0x8628,
    GL_MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB      = 0x862E,
    GL_MAX_PROGRAM_MATRICES_ARB                = 0x862F,
    GL_CURRENT_MATRIX_STACK_DEPTH_ARB          = 0x8640,
    GL_CURRENT_MATRIX_ARB                      = 0x8641,
    GL_VERTEX_PROGRAM_POINT_SIZE_ARB           = 0x8642,
    GL_VERTEX_PROGRAM_TWO_SIDE_ARB             = 0x8643,
    GL_VERTEX_ATTRIB_ARRAY_POINTER_ARB         = 0x8645,
    GL_PROGRAM_ERROR_POSITION_ARB              = 0x864B,
    GL_PROGRAM_BINDING_ARB                     = 0x8677,
    GL_MAX_VERTEX_ATTRIBS_ARB                  = 0x8869,
    GL_VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB      = 0x886A,
    GL_PROGRAM_ERROR_STRING_ARB                = 0x8874,
    GL_PROGRAM_FORMAT_ASCII_ARB                = 0x8875,
    GL_PROGRAM_FORMAT_ARB                      = 0x8876,
    GL_PROGRAM_INSTRUCTIONS_ARB                = 0x88A0,
    GL_MAX_PROGRAM_INSTRUCTIONS_ARB            = 0x88A1,
    GL_PROGRAM_NATIVE_INSTRUCTIONS_ARB         = 0x88A2,
    GL_MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB     = 0x88A3,
    GL_PROGRAM_TEMPORARIES_ARB                 = 0x88A4,
    GL_MAX_PROGRAM_TEMPORARIES_ARB             = 0x88A5,
    GL_PROGRAM_NATIVE_TEMPORARIES_ARB          = 0x88A6,
    GL_MAX_PROGRAM_NATIVE_TEMPORARIES_ARB      = 0x88A7,
    GL_PROGRAM_PARAMETERS_ARB                  = 0x88A8,
    GL_MAX_PROGRAM_PARAMETERS_ARB              = 0x88A9,
    GL_PROGRAM_NATIVE_PARAMETERS_ARB           = 0x88AA,
    GL_MAX_PROGRAM_NATIVE_PARAMETERS_ARB       = 0x88AB,
    GL_PROGRAM_ATTRIBS_ARB                     = 0x88AC,
    GL_MAX_PROGRAM_ATTRIBS_ARB                 = 0x88AD,
    GL_PROGRAM_NATIVE_ATTRIBS_ARB              = 0x88AE,
    GL_MAX_PROGRAM_NATIVE_ATTRIBS_ARB          = 0x88AF,
    GL_PROGRAM_ADDRESS_REGISTERS_ARB           = 0x88B0,
    GL_MAX_PROGRAM_ADDRESS_REGISTERS_ARB       = 0x88B1,
    GL_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB    = 0x88B2,
    GL_MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB = 0x88B3,
    GL_MAX_PROGRAM_LOCAL_PARAMETERS_ARB        = 0x88B4,
    GL_MAX_PROGRAM_ENV_PARAMETERS_ARB          = 0x88B5,
    GL_PROGRAM_UNDER_NATIVE_LIMITS_ARB         = 0x88B6,
    GL_TRANSPOSE_CURRENT_MATRIX_ARB            = 0x88B7,
    GL_MATRIX0_ARB                             = 0x88C0,
    GL_MATRIX1_ARB                             = 0x88C1,
    GL_MATRIX2_ARB                             = 0x88C2,
    GL_MATRIX3_ARB                             = 0x88C3,
    GL_MATRIX4_ARB                             = 0x88C4,
    GL_MATRIX5_ARB                             = 0x88C5,
    GL_MATRIX6_ARB                             = 0x88C6,
    GL_MATRIX7_ARB                             = 0x88C7,
    GL_MATRIX8_ARB                             = 0x88C8,
    GL_MATRIX9_ARB                             = 0x88C9,
    GL_MATRIX10_ARB                            = 0x88CA,
    GL_MATRIX11_ARB                            = 0x88CB,
    GL_MATRIX12_ARB                            = 0x88CC,
    GL_MATRIX13_ARB                            = 0x88CD,
    GL_MATRIX14_ARB                            = 0x88CE,
    GL_MATRIX15_ARB                            = 0x88CF,
    GL_MATRIX16_ARB                            = 0x88D0,
    GL_MATRIX17_ARB                            = 0x88D1,
    GL_MATRIX18_ARB                            = 0x88D2,
    GL_MATRIX19_ARB                            = 0x88D3,
    GL_MATRIX20_ARB                            = 0x88D4,
    GL_MATRIX21_ARB                            = 0x88D5,
    GL_MATRIX22_ARB                            = 0x88D6,
    GL_MATRIX23_ARB                            = 0x88D7,
    GL_MATRIX24_ARB                            = 0x88D8,
    GL_MATRIX25_ARB                            = 0x88D9,
    GL_MATRIX26_ARB                            = 0x88DA,
    GL_MATRIX27_ARB                            = 0x88DB,
    GL_MATRIX28_ARB                            = 0x88DC,
    GL_MATRIX29_ARB                            = 0x88DD,
    GL_MATRIX30_ARB                            = 0x88DE,
    GL_MATRIX31_ARB                            = 0x88DF,
}

extern(System)
{
    void function(GLuint, GLdouble) glVertexAttrib1dARB;
    void function(GLuint, GLdouble*) glVertexAttrib1dvARB;
    void function(GLuint, GLfloat) glVertexAttrib1fARB;
    void function(GLuint, GLfloat*) glVertexAttrib1fvARB;
    void function(GLuint, GLshort) glVertexAttrib1sARB;
    void function(GLuint, GLshort*) glVertexAttrib1svARB;
    void function(GLuint, GLdouble, GLdouble) glVertexAttrib2dARB;
    void function(GLuint, GLdouble*) glVertexAttrib2dvARB;
    void function(GLuint, GLfloat, GLfloat) glVertexAttrib2fARB;
    void function(GLuint, GLfloat*) glVertexAttrib2fvARB;
    void function(GLuint, GLshort, GLshort) glVertexAttrib2sARB;
    void function(GLuint, GLshort*) glVertexAttrib2svARB;
    void function(GLuint, GLdouble, GLdouble, GLdouble) glVertexAttrib3dARB;
    void function(GLuint, GLdouble*) glVertexAttrib3dvARB;
    void function(GLuint, GLfloat, GLfloat, GLfloat) glVertexAttrib3fARB;
    void function(GLuint, GLfloat*) glVertexAttrib3fvARB;
    void function(GLuint, GLshort, GLshort, GLshort) glVertexAttrib3sARB;
    void function(GLuint, GLshort*) glVertexAttrib3svARB;
    void function(GLuint, GLbyte*) glVertexAttrib4NbvARB;
    void function(GLuint, GLint*) glVertexAttrib4NivARB;
    void function(GLuint, GLshort*) glVertexAttrib4NsvARB;
    void function(GLuint, GLubyte, GLubyte, GLubyte, GLubyte) glVertexAttrib4NubARB;
    void function(GLuint, GLubyte*) glVertexAttrib4NubvARB;
    void function(GLuint, GLuint*) glVertexAttrib4NuivARB;
    void function(GLuint, GLushort*) glVertexAttrib4NusvARB;
    void function(GLuint, GLbyte*) glVertexAttrib4bvARB;
    void function(GLuint, GLdouble, GLdouble, GLdouble, GLdouble) glVertexAttrib4dARB;
    void function(GLuint, GLdouble*) glVertexAttrib4dvARB;
    void function(GLuint, GLfloat, GLfloat, GLfloat, GLfloat) glVertexAttrib4fARB;
    void function(GLuint, GLfloat*) glVertexAttrib4fvARB;
    void function(GLuint, GLint*) glVertexAttrib4ivARB;
    void function(GLuint, GLshort, GLshort, GLshort, GLshort) glVertexAttrib4sARB;
    void function(GLuint, GLshort*) glVertexAttrib4svARB;
    void function(GLuint, GLubyte*) glVertexAttrib4ubvARB;
    void function(GLuint, GLuint*) glVertexAttrib4uivARB;
    void function(GLuint, GLushort*) glVertexAttrib4usvARB;
    void function(GLuint, GLint, GLenum, GLboolean, GLsizei, GLvoid*) glVertexAttribPointerARB;
    void function(GLuint) glEnableVertexAttribArrayARB;
    void function(GLuint) glDisableVertexAttribArrayARB;
    void function(GLenum, GLenum, GLsizei, GLvoid*) glProgramStringARB;
    void function(GLenum, GLuint) glBindProgramARB;
    void function(GLsizei, GLuint*) glDeleteProgramsARB;
    void function(GLsizei, GLuint*) glGenProgramsARB;
    void function(GLenum, GLuint, GLdouble, GLdouble, GLdouble, GLdouble) glProgramEnvParameter4dARB;
    void function(GLenum, GLuint, GLdouble*) glProgramEnvParameter4dvARB;
    void function(GLenum, GLuint, GLfloat, GLfloat, GLfloat, GLfloat) glProgramEnvParameter4fARB;
    void function(GLenum, GLuint, GLfloat*) glProgramEnvParameter4fvARB;
    void function(GLenum, GLuint, GLdouble, GLdouble, GLdouble, GLdouble) glProgramLocalParameter4dARB;
    void function(GLenum, GLuint, GLdouble*) glProgramLocalParameter4dvARB;
    void function(GLenum, GLuint, GLfloat, GLfloat, GLfloat, GLfloat) glProgramLocalParameter4fARB;
    void function(GLenum, GLuint, GLfloat*) glProgramLocalParameter4fvARB;
    void function(GLenum, GLuint, GLdouble*) glGetProgramEnvParameterdvARB;
    void function(GLenum, GLuint, GLfloat*) glGetProgramEnvParameterfvARB;
    void function(GLenum, GLuint, GLdouble*) glGetProgramLocalParameterdvARB;
    void function(GLenum, GLuint, GLfloat*) glGetProgramLocalParameterfvARB;
    void function(GLenum, GLenum, GLint*) glGetProgramivARB;
    void function(GLenum, GLenum, GLvoid*) glGetProgramStringARB;
    void function(GLuint, GLenum, GLdouble*) glGetVertexAttribdvARB;
    void function(GLuint, GLenum, GLfloat*) glGetVertexAttribfvARB;
    void function(GLuint, GLenum, GLint*) glGetVertexAttribivARB;
    void function(GLuint, GLenum, GLvoid*) glGetVertexAttribPointervARB;
    GLboolean function(GLuint) glIsProgramARB;
}