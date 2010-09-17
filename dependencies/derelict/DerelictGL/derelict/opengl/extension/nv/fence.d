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
module derelict.opengl.extension.nv.fence;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVFence
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_fence") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glDeleteFencesNV, "glDeleteFencesNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenFencesNV, "glGenFencesNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsFenceNV, "glIsFenceNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTestFenceNV, "glTestFenceNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetFenceivNV, "glGetFenceivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFinishFenceNV, "glFinishFenceNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSetFenceNV, "glSetFenceNV"))
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
        DerelictGL.registerExtensionLoader(&NVFence.load);
    }
}

enum : GLenum
{
    GL_ALL_COMPLETED_NV               = 0x84F2,
    GL_FENCE_STATUS_NV                = 0x84F3,
    GL_FENCE_CONDITION_NV             = 0x84F4,
}

extern(System)
{
    void function(GLsizei, GLuint*) glDeleteFencesNV;
    void function(GLsizei, GLuint*) glGenFencesNV;
    GLboolean function(GLuint) glIsFenceNV;
    GLboolean function(GLuint) glTestFenceNV;
    void function(GLuint, GLenum, GLint*) glGetFenceivNV;
    void function(GLuint) glFinishFenceNV;
    void function(GLuint, GLenum) glSetFenceNV;
}