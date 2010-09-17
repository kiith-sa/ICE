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
module derelict.opengl.extension.arb.vertex_blend;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBVertexBlend
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_vertex_blend") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightbvARB, "glWeightbvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightsvARB, "glWeightsvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightivARB, "glWeightivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightfvARB, "glWeightfvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightdvARB, "glWeightdvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightubvARB, "glMatrixIndexPointerARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightusvARB, "glWeightusvARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightuivARB, "glWeightuivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glWeightPointerARB, "glWeightPointerARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexBlendARB, "glVertexBlendARB"))
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
        DerelictGL.registerExtensionLoader(&ARBVertexBlend.load);
    }
}

enum : GLenum
{
    GL_MAX_VERTEX_UNITS_ARB           = 0x86A4,
    GL_ACTIVE_VERTEX_UNITS_ARB        = 0x86A5,
    GL_WEIGHT_SUM_UNITY_ARB           = 0x86A6,
    GL_VERTEX_BLEND_ARB               = 0x86A7,
    GL_CURRENT_WEIGHT_ARB             = 0x86A8,
    GL_WEIGHT_ARRAY_TYPE_ARB          = 0x86A9,
    GL_WEIGHT_ARRAY_STRIDE_ARB        = 0x86AA,
    GL_WEIGHT_ARRAY_SIZE_ARB          = 0x86AB,
    GL_WEIGHT_ARRAY_POINTER_ARB       = 0x86AC,
    GL_WEIGHT_ARRAY_ARB               = 0x86AD,
    GL_MODELVIEW0_ARB                 = 0x1700,
    GL_MODELVIEW1_ARB                 = 0x850A,
    GL_MODELVIEW2_ARB                 = 0x8722,
    GL_MODELVIEW3_ARB                 = 0x8723,
    GL_MODELVIEW4_ARB                 = 0x8724,
    GL_MODELVIEW5_ARB                 = 0x8725,
    GL_MODELVIEW6_ARB                 = 0x8726,
    GL_MODELVIEW7_ARB                 = 0x8727,
    GL_MODELVIEW8_ARB                 = 0x8728,
    GL_MODELVIEW9_ARB                 = 0x8729,
    GL_MODELVIEW10_ARB                = 0x872A,
    GL_MODELVIEW11_ARB                = 0x872B,
    GL_MODELVIEW12_ARB                = 0x872C,
    GL_MODELVIEW13_ARB                = 0x872D,
    GL_MODELVIEW14_ARB                = 0x872E,
    GL_MODELVIEW15_ARB                = 0x872F,
    GL_MODELVIEW16_ARB                = 0x8730,
    GL_MODELVIEW17_ARB                = 0x8731,
    GL_MODELVIEW18_ARB                = 0x8732,
    GL_MODELVIEW19_ARB                = 0x8733,
    GL_MODELVIEW20_ARB                = 0x8734,
    GL_MODELVIEW21_ARB                = 0x8735,
    GL_MODELVIEW22_ARB                = 0x8736,
    GL_MODELVIEW23_ARB                = 0x8737,
    GL_MODELVIEW24_ARB                = 0x8738,
    GL_MODELVIEW25_ARB                = 0x8739,
    GL_MODELVIEW26_ARB                = 0x873A,
    GL_MODELVIEW27_ARB                = 0x873B,
    GL_MODELVIEW28_ARB                = 0x873C,
    GL_MODELVIEW29_ARB                = 0x873D,
    GL_MODELVIEW30_ARB                = 0x873E,
    GL_MODELVIEW31_ARB                = 0x873F,
}

extern(System)
{
    void function(GLint, GLbyte*) glWeightbvARB;
    void function(GLint, GLshort*) glWeightsvARB;
    void function(GLint, GLint*) glWeightivARB;
    void function(GLint, GLfloat*) glWeightfvARB;
    void function(GLint, GLdouble*) glWeightdvARB;
    void function(GLint, GLubyte*) glWeightubvARB;
    void function(GLint, GLushort*) glWeightusvARB;
    void function(GLint, GLuint*) glWeightuivARB;
    void function(GLint, GLenum, GLsizei, GLvoid*) glWeightPointerARB;
    void function(GLint) glVertexBlendARB;
}