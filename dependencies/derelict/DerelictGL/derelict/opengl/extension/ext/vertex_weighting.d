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
module derelict.opengl.extension.ext.vertex_weighting;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTVertexWeighting
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_vertex_weighting") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glVertexWeightfEXT, "glVertexWeightfEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexWeightfvEXT, "glVertexWeightfvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexWeightPointerEXT, "glVertexWeightPointerEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTVertexWeighting.load);
    }
}

enum : GLenum
{
    GL_MODELVIEW0_STACK_DEPTH_EXT       = GL_MODELVIEW_STACK_DEPTH,
    GL_MODELVIEW1_STACK_DEPTH_EXT       = 0x8502,
    GL_MODELVIEW0_MATRIX_EXT            = GL_MODELVIEW_MATRIX,
    GL_MODELVIEW1_MATRIX_EXT            = 0x8506,
    GL_VERTEX_WEIGHTING_EXT             = 0x8509,
    GL_MODELVIEW0_EXT                   = GL_MODELVIEW,
    GL_MODELVIEW1_EXT                   = 0x850A,
    GL_CURRENT_VERTEX_WEIGHT_EXT        = 0x850B,
    GL_VERTEX_WEIGHT_ARRAY_EXT          = 0x850C,
    GL_VERTEX_WEIGHT_ARRAY_SIZE_EXT     = 0x850D,
    GL_VERTEX_WEIGHT_ARRAY_TYPE_EXT     = 0x850E,
    GL_VERTEX_WEIGHT_ARRAY_STRIDE_EXT   = 0x850F,
    GL_VERTEX_WEIGHT_ARRAY_POINTER_EXT  = 0x8510,
}

extern(System)
{
    void function(GLfloat) glVertexWeightfEXT;
    void function(GLfloat*) glVertexWeightfvEXT;
    void function(GLsizei,GLenum,GLsizei,GLvoid*) glVertexWeightPointerEXT;
}