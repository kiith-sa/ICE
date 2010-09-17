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
module derelict.opengl.extension.nv.vertex_program;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVVertexProgram
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_vertex_program") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glAreProgramsResidentNV, "glAreProgramsResidentNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindProgramNV, "glBindProgramNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDeleteProgramsNV, "glDeleteProgramsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glExecuteProgramNV, "glExecuteProgramNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenProgramsNV, "glGenProgramsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramParameterdvNV, "glGetProgramParameterdvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramParameterfvNV, "glGetProgramParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramivNV, "glGetProgramivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramStringNV, "glGetProgramStringNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTrackMatrixivNV, "glGetTrackMatrixivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribdvNV, "glGetVertexAttribdvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribfvNV, "glGetVertexAttribfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribivNV, "glGetVertexAttribivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribPointervNV, "glGetVertexAttribPointervNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsProgramNV, "glIsProgramNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glLoadProgramNV, "glLoadProgramNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameter4dNV, "glProgramParameter4dNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameter4dvNV, "glProgramParameter4dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameter4fNV, "glProgramParameter4fNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameter4fvNV, "glProgramParameter4fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameters4dvNV, "glProgramParameters4dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameters4fvNV, "glProgramParameters4fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glRequestResidentProgramsNV, "glRequestResidentProgramsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTrackMatrixNV, "glTrackMatrixNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribPointerNV, "glVertexAttribPointerNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1dNV, "glVertexAttrib1dNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1dvNV, "glVertexAttrib1dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1fNV, "glVertexAttrib1fNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1fvNV, "glVertexAttrib1fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1sNV, "glVertexAttrib1sNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1svNV, "glVertexAttrib1svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2dNV, "glVertexAttrib2dNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2dvNV, "glVertexAttrib2dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2fNV, "glVertexAttrib2fNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2fvNV, "glVertexAttrib2fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2sNV, "glVertexAttrib2sNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2svNV, "glVertexAttrib2svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3dNV, "glVertexAttrib3dNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3dvNV, "glVertexAttrib3dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3fNV, "glVertexAttrib3fNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3fvNV, "glVertexAttrib3fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3sNV, "glVertexAttrib3sNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3svNV, "glVertexAttrib3svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4dNV, "glVertexAttrib4dNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4dvNV, "glVertexAttrib4dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4fNV, "glVertexAttrib4fNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4fvNV, "glVertexAttrib4fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4sNV, "glVertexAttrib4sNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4svNV, "glVertexAttrib4svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4ubNV, "glVertexAttrib4ubNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4ubvNV, "glVertexAttrib4ubvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs1dvNV, "glVertexAttribs1dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs1fvNV, "glVertexAttribs1fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs1svNV, "glVertexAttribs1svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs2dvNV, "glVertexAttribs2dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs2fvNV, "glVertexAttribs2fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs2svNV, "glVertexAttribs2svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs3dvNV, "glVertexAttribs3dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs3fvNV, "glVertexAttribs3fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs3svNV, "glVertexAttribs3svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs4dvNV, "glVertexAttribs4dvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs4fvNV, "glVertexAttribs4fvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs4svNV, "glVertexAttribs4svNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs4ubvNV, "glVertexAttribs4ubvNV"))
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
        DerelictGL.registerExtensionLoader(&NVVertexProgram.load);
    }
}

enum : GLenum
{
    GL_VERTEX_PROGRAM_NV              = 0x8620,
    GL_VERTEX_STATE_PROGRAM_NV        = 0x8621,
    GL_ATTRIB_ARRAY_SIZE_NV           = 0x8623,
    GL_ATTRIB_ARRAY_STRIDE_NV         = 0x8624,
    GL_ATTRIB_ARRAY_TYPE_NV           = 0x8625,
    GL_CURRENT_ATTRIB_NV              = 0x8626,
    GL_PROGRAM_LENGTH_NV              = 0x8627,
    GL_PROGRAM_STRING_NV              = 0x8628,
    GL_MODELVIEW_PROJECTION_NV        = 0x8629,
    GL_IDENTITY_NV                    = 0x862A,
    GL_INVERSE_NV                     = 0x862B,
    GL_TRANSPOSE_NV                   = 0x862C,
    GL_INVERSE_TRANSPOSE_NV           = 0x862D,
    GL_MAX_TRACK_MATRIX_STACK_DEPTH_NV = 0x862E,
    GL_MAX_TRACK_MATRICES_NV          = 0x862F,
    GL_MATRIX0_NV                     = 0x8630,
    GL_MATRIX1_NV                     = 0x8631,
    GL_MATRIX2_NV                     = 0x8632,
    GL_MATRIX3_NV                     = 0x8633,
    GL_MATRIX4_NV                     = 0x8634,
    GL_MATRIX5_NV                     = 0x8635,
    GL_MATRIX6_NV                     = 0x8636,
    GL_MATRIX7_NV                     = 0x8637,
    GL_CURRENT_MATRIX_STACK_DEPTH_NV  = 0x8640,
    GL_CURRENT_MATRIX_NV              = 0x8641,
    GL_VERTEX_PROGRAM_POINT_SIZE_NV   = 0x8642,
    GL_VERTEX_PROGRAM_TWO_SIDE_NV     = 0x8643,
    GL_PROGRAM_PARAMETER_NV           = 0x8644,
    GL_ATTRIB_ARRAY_POINTER_NV        = 0x8645,
    GL_PROGRAM_TARGET_NV              = 0x8646,
    GL_PROGRAM_RESIDENT_NV            = 0x8647,
    GL_TRACK_MATRIX_NV                = 0x8648,
    GL_TRACK_MATRIX_TRANSFORM_NV      = 0x8649,
    GL_VERTEX_PROGRAM_BINDING_NV      = 0x864A,
    GL_PROGRAM_ERROR_POSITION_NV      = 0x864B,
    GL_VERTEX_ATTRIB_ARRAY0_NV        = 0x8650,
    GL_VERTEX_ATTRIB_ARRAY1_NV        = 0x8651,
    GL_VERTEX_ATTRIB_ARRAY2_NV        = 0x8652,
    GL_VERTEX_ATTRIB_ARRAY3_NV        = 0x8653,
    GL_VERTEX_ATTRIB_ARRAY4_NV        = 0x8654,
    GL_VERTEX_ATTRIB_ARRAY5_NV        = 0x8655,
    GL_VERTEX_ATTRIB_ARRAY6_NV        = 0x8656,
    GL_VERTEX_ATTRIB_ARRAY7_NV        = 0x8657,
    GL_VERTEX_ATTRIB_ARRAY8_NV        = 0x8658,
    GL_VERTEX_ATTRIB_ARRAY9_NV        = 0x8659,
    GL_VERTEX_ATTRIB_ARRAY10_NV       = 0x865A,
    GL_VERTEX_ATTRIB_ARRAY11_NV       = 0x865B,
    GL_VERTEX_ATTRIB_ARRAY12_NV       = 0x865C,
    GL_VERTEX_ATTRIB_ARRAY13_NV       = 0x865D,
    GL_VERTEX_ATTRIB_ARRAY14_NV       = 0x865E,
    GL_VERTEX_ATTRIB_ARRAY15_NV       = 0x865F,
    GL_MAP1_VERTEX_ATTRIB0_4_NV       = 0x8660,
    GL_MAP1_VERTEX_ATTRIB1_4_NV       = 0x8661,
    GL_MAP1_VERTEX_ATTRIB2_4_NV       = 0x8662,
    GL_MAP1_VERTEX_ATTRIB3_4_NV       = 0x8663,
    GL_MAP1_VERTEX_ATTRIB4_4_NV       = 0x8664,
    GL_MAP1_VERTEX_ATTRIB5_4_NV       = 0x8665,
    GL_MAP1_VERTEX_ATTRIB6_4_NV       = 0x8666,
    GL_MAP1_VERTEX_ATTRIB7_4_NV       = 0x8667,
    GL_MAP1_VERTEX_ATTRIB8_4_NV       = 0x8668,
    GL_MAP1_VERTEX_ATTRIB9_4_NV       = 0x8669,
    GL_MAP1_VERTEX_ATTRIB10_4_NV      = 0x866A,
    GL_MAP1_VERTEX_ATTRIB11_4_NV      = 0x866B,
    GL_MAP1_VERTEX_ATTRIB12_4_NV      = 0x866C,
    GL_MAP1_VERTEX_ATTRIB13_4_NV      = 0x866D,
    GL_MAP1_VERTEX_ATTRIB14_4_NV      = 0x866E,
    GL_MAP1_VERTEX_ATTRIB15_4_NV      = 0x866F,
    GL_MAP2_VERTEX_ATTRIB0_4_NV       = 0x8670,
    GL_MAP2_VERTEX_ATTRIB1_4_NV       = 0x8671,
    GL_MAP2_VERTEX_ATTRIB2_4_NV       = 0x8672,
    GL_MAP2_VERTEX_ATTRIB3_4_NV       = 0x8673,
    GL_MAP2_VERTEX_ATTRIB4_4_NV       = 0x8674,
    GL_MAP2_VERTEX_ATTRIB5_4_NV       = 0x8675,
    GL_MAP2_VERTEX_ATTRIB6_4_NV       = 0x8676,
    GL_MAP2_VERTEX_ATTRIB7_4_NV       = 0x8677,
    GL_MAP2_VERTEX_ATTRIB8_4_NV       = 0x8678,
    GL_MAP2_VERTEX_ATTRIB9_4_NV       = 0x8679,
    GL_MAP2_VERTEX_ATTRIB10_4_NV      = 0x867A,
    GL_MAP2_VERTEX_ATTRIB11_4_NV      = 0x867B,
    GL_MAP2_VERTEX_ATTRIB12_4_NV      = 0x867C,
    GL_MAP2_VERTEX_ATTRIB13_4_NV      = 0x867D,
    GL_MAP2_VERTEX_ATTRIB14_4_NV      = 0x867E,
    GL_MAP2_VERTEX_ATTRIB15_4_NV      = 0x867F,
}

extern(System)
{
    GLboolean function(GLsizei,GLuint*,GLboolean*) glAreProgramsResidentNV;
    void function(GLenum,GLuint) glBindProgramNV;
    void function(GLsizei,GLuint*) glDeleteProgramsNV;
    void function(GLenum,GLuint,GLfloat*) glExecuteProgramNV;
    void function(GLsizei,GLuint*) glGenProgramsNV;
    void function(GLenum,GLuint,GLenum,GLdouble*) glGetProgramParameterdvNV;
    void function(GLenum,GLuint,GLenum,GLfloat*) glGetProgramParameterfvNV;
    void function(GLuint,GLenum,GLint*) glGetProgramivNV;
    void function(GLuint,GLenum,GLchar*) glGetProgramStringNV;
    void function(GLenum,GLuint,GLenum,GLint*) glGetTrackMatrixivNV;
    void function(GLuint,GLenum,GLdouble*) glGetVertexAttribdvNV;
    void function(GLuint,GLenum,GLfloat*) glGetVertexAttribfvNV;
    void function(GLuint,GLenum,GLint*) glGetVertexAttribivNV;
    void function(GLuint,GLenum,GLvoid*) glGetVertexAttribPointervNV;
    GLboolean function(GLuint) glIsProgramNV;
    void function(GLenum,GLuint,GLsizei,GLchar*) glLoadProgramNV;
    void function(GLenum,GLuint,GLdouble,GLdouble,GLdouble,GLdouble) glProgramParameter4dNV;
    void function(GLenum,GLuint,GLdouble*) glProgramParameter4dvNV;
    void function(GLenum,GLuint,GLfloat,GLfloat,GLfloat,GLfloat) glProgramParameter4fNV;
    void function(GLenum,GLuint,GLfloat*) glProgramParameter4fvNV;
    void function(GLenum,GLuint,GLuint,GLdouble*) glProgramParameters4dvNV;
    void function(GLenum,GLuint,GLuint,GLfloat*) glProgramParameters4fvNV;
    void function(GLsizei,GLuint*) glRequestResidentProgramsNV;
    void function(GLenum,GLuint,GLenum,GLenum) glTrackMatrixNV;
    void function(GLuint,GLint,GLenum,GLsizei,GLvoid*) glVertexAttribPointerNV;
    void function(GLuint,GLdouble) glVertexAttrib1dNV;
    void function(GLuint,GLdouble*) glVertexAttrib1dvNV;
    void function(GLuint,GLfloat) glVertexAttrib1fNV;
    void function(GLuint,GLfloat*) glVertexAttrib1fvNV;
    void function(GLuint,GLshort) glVertexAttrib1sNV;
    void function(GLuint,GLshort*) glVertexAttrib1svNV;
    void function(GLuint,GLdouble,GLdouble) glVertexAttrib2dNV;
    void function(GLuint,GLdouble*) glVertexAttrib2dvNV;
    void function(GLuint,GLfloat,GLfloat) glVertexAttrib2fNV;
    void function(GLuint,GLfloat*) glVertexAttrib2fvNV;
    void function(GLuint,GLshort,GLshort) glVertexAttrib2sNV;
    void function(GLuint,GLshort*) glVertexAttrib2svNV;
    void function(GLuint,GLdouble,GLdouble,GLdouble) glVertexAttrib3dNV;
    void function(GLuint,GLdouble*) glVertexAttrib3dvNV;
    void function(GLuint,GLfloat,GLfloat,GLfloat) glVertexAttrib3fNV;
    void function(GLuint,GLfloat*) glVertexAttrib3fvNV;
    void function(GLuint,GLshort,GLshort,GLshort) glVertexAttrib3sNV;
    void function(GLuint,GLshort*) glVertexAttrib3svNV;
    void function(GLuint,GLdouble,GLdouble,GLdouble,GLdouble) glVertexAttrib4dNV;
    void function(GLuint,GLdouble*) glVertexAttrib4dvNV;
    void function(GLuint,GLfloat,GLfloat,GLfloat,GLfloat) glVertexAttrib4fNV;
    void function(GLuint,GLfloat*) glVertexAttrib4fvNV;
    void function(GLuint,GLshort,GLshort,GLshort,GLshort) glVertexAttrib4sNV;
    void function(GLuint,GLshort*) glVertexAttrib4svNV;
    void function(GLuint,GLubyte,GLubyte,GLubyte,GLubyte) glVertexAttrib4ubNV;
    void function(GLuint,GLubyte*) glVertexAttrib4ubvNV;
    void function(GLuint,GLsizei,GLdouble*) glVertexAttribs1dvNV;
    void function(GLuint,GLsizei,GLfloat*) glVertexAttribs1fvNV;
    void function(GLuint,GLsizei,GLshort*) glVertexAttribs1svNV;
    void function(GLuint,GLsizei,GLdouble*) glVertexAttribs2dvNV;
    void function(GLuint,GLsizei,GLfloat*) glVertexAttribs2fvNV;
    void function(GLuint,GLsizei,GLshort*) glVertexAttribs2svNV;
    void function(GLuint,GLsizei,GLdouble*) glVertexAttribs3dvNV;
    void function(GLuint,GLsizei,GLfloat*) glVertexAttribs3fvNV;
    void function(GLuint,GLsizei,GLshort*) glVertexAttribs3svNV;
    void function(GLuint,GLsizei,GLdouble*) glVertexAttribs4dvNV;
    void function(GLuint,GLsizei,GLfloat*) glVertexAttribs4fvNV;
    void function(GLuint,GLsizei,GLshort*) glVertexAttribs4svNV;
    void function(GLuint,GLsizei,GLubyte*) glVertexAttribs4ubvNV;
}