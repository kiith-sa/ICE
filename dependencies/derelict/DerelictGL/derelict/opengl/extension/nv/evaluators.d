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
module derelict.opengl.extension.nv.evaluators;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVEvaluators
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_evaluators") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glMapControlPointsNV, "glMapControlPointsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMapParameterivNV, "glMapParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMapParameterfvNV, "glMapParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetMapControlPointsNV, "glGetMapControlPointsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetMapParameterivNV, "glGetMapParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetMapParameterfvNV, "glGetMapParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetMapAttribParameterivNV, "glGetMapAttribParameterivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetMapAttribParameterfvNV, "glGetMapAttribParameterfvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glEvalMapsNV, "glEvalMapsNV"))
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
        DerelictGL.registerExtensionLoader(&NVEvaluators.load);
    }
}

enum : GLenum
{
    GL_EVAL_2D_NV                      = 0x86C0,
    GL_EVAL_TRIANGULAR_2D_NV           = 0x86C1,
    GL_MAP_TESSELLATION_NV             = 0x86C2,
    GL_MAP_ATTRIB_U_ORDER_NV           = 0x86C3,
    GL_MAP_ATTRIB_V_ORDER_NV           = 0x86C4,
    GL_EVAL_FRACTIONAL_TESSELLATION_NV = 0x86C5,
    GL_EVAL_VERTEX_ATTRIB0_NV          = 0x86C6,
    GL_EVAL_VERTEX_ATTRIB1_NV          = 0x86C7,
    GL_EVAL_VERTEX_ATTRIB2_NV          = 0x86C8,
    GL_EVAL_VERTEX_ATTRIB3_NV          = 0x86C9,
    GL_EVAL_VERTEX_ATTRIB4_NV          = 0x86CA,
    GL_EVAL_VERTEX_ATTRIB5_NV          = 0x86CB,
    GL_EVAL_VERTEX_ATTRIB6_NV          = 0x86CC,
    GL_EVAL_VERTEX_ATTRIB7_NV          = 0x86CD,
    GL_EVAL_VERTEX_ATTRIB8_NV          = 0x86CE,
    GL_EVAL_VERTEX_ATTRIB9_NV          = 0x86CF,
    GL_EVAL_VERTEX_ATTRIB10_NV         = 0x86D0,
    GL_EVAL_VERTEX_ATTRIB11_NV         = 0x86D1,
    GL_EVAL_VERTEX_ATTRIB12_NV         = 0x86D2,
    GL_EVAL_VERTEX_ATTRIB13_NV         = 0x86D3,
    GL_EVAL_VERTEX_ATTRIB14_NV         = 0x86D4,
    GL_EVAL_VERTEX_ATTRIB15_NV         = 0x86D5,
    GL_MAX_MAP_TESSELLATION_NV         = 0x86D6,
    GL_MAX_RATIONAL_EVAL_ORDER_NV      = 0x86D7,
}

extern(System)
{
    void function(GLenum, GLuint, GLenum, GLsizei, GLsizei, GLint, GLint, GLboolean, GLvoid*) glMapControlPointsNV;
    void function(GLenum, GLenum, GLint*) glMapParameterivNV;
    void function(GLenum, GLenum, GLfloat*) glMapParameterfvNV;
    void function(GLenum, GLuint, GLenum, GLsizei, GLsizei, GLboolean, GLvoid*) glGetMapControlPointsNV;
    void function(GLenum, GLenum, GLint*) glGetMapParameterivNV;
    void function(GLenum, GLenum, GLfloat*) glGetMapParameterfvNV;
    void function(GLenum, GLuint, GLenum, GLint*) glGetMapAttribParameterivNV;
    void function(GLenum, GLuint, GLenum, GLfloat*) glGetMapAttribParameterfvNV;
    void function(GLenum, GLenum) glEvalMapsNV;
}