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
module derelict.opengl.extension.ext.gpu_shader4;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTGpuShader4
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_gpu_shader4") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glBindFragDataLocationEXT, "glBindFragDataLocationEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetFragDataLocationEXT, "glGetFragDataLocationEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetUniformuivEXT, "glGetUniformuivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribIivEXT, "glGetVertexAttribIivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVertexAttribIuivEXT, "glGetVertexAttribIuivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform1uiEXT, "glUniform1uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform1uivEXT, "glUniform1uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform2uiEXT, "glUniform2uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform2uivEXT, "glUniform2uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform3uiEXT, "glUniform3uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform3uivEXT, "glUniform3uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform4uiEXT, "glUniform4uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUniform4uivEXT, "glUniform4uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI1iEXT, "glVertexAttribI1iEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI1ivEXT, "glVertexAttribI1ivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI1uiEXT, "glVertexAttribI1uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI1uivEXT, "glVertexAttribI1uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI2iEXT, "glVertexAttribI2iEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI2ivEXT, "glVertexAttribI2ivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI2uiEXT, "glVertexAttribI2uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI2uivEXT, "glVertexAttribI2uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI3iEXT, "glVertexAttribI3iEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI3ivEXT, "glVertexAttribI3ivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI3uiEXT, "glVertexAttribI3uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI3uivEXT, "glVertexAttribI3uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4bvEXT, "glVertexAttribI4bvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4iEXT, "glVertexAttribI4iEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4ivEXT, "glVertexAttribI4ivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4svEXT, "glVertexAttribI4svEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4ubvEXT, "glVertexAttribI4ubvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4uiEXT, "glVertexAttribI4uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4uivEXT, "glVertexAttribI4uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribI4usvEXT, "glVertexAttribI4usvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribIPointerEXT, "glVertexAttribIPointerEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTGpuShader4.load);
    }
}

enum : GLenum
{
    GL_VERTEX_ATTRIB_ARRAY_INTEGER_EXT  = 0x88FD,
    GL_SAMPLER_1D_ARRAY_EXT             = 0x8DC0,
    GL_SAMPLER_2D_ARRAY_EXT             = 0x8DC1,
    GL_SAMPLER_BUFFER_EXT               = 0x8DC2,
    GL_SAMPLER_1D_ARRAY_SHADOW_EXT      = 0x8DC3,
    GL_SAMPLER_2D_ARRAY_SHADOW_EXT      = 0x8DC4,
    GL_SAMPLER_CUBE_SHADOW_EXT          = 0x8DC5,
    GL_UNSIGNED_INT_VEC2_EXT            = 0x8DC6,
    GL_UNSIGNED_INT_VEC3_EXT            = 0x8DC7,
    GL_UNSIGNED_INT_VEC4_EXT            = 0x8DC8,
    GL_INT_SAMPLER_1D_EXT               = 0x8DC9,
    GL_INT_SAMPLER_2D_EXT               = 0x8DCA,
    GL_INT_SAMPLER_3D_EXT               = 0x8DCB,
    GL_INT_SAMPLER_CUBE_EXT             = 0x8DCC,
    GL_INT_SAMPLER_2D_RECT_EXT          = 0x8DCD,
    GL_INT_SAMPLER_1D_ARRAY_EXT         = 0x8DCE,
    GL_INT_SAMPLER_2D_ARRAY_EXT         = 0x8DCF,
    GL_INT_SAMPLER_BUFFER_EXT           = 0x8DD0,
    GL_UNSIGNED_INT_SAMPLER_1D_EXT      = 0x8DD1,
    GL_UNSIGNED_INT_SAMPLER_2D_EXT      = 0x8DD2,
    GL_UNSIGNED_INT_SAMPLER_3D_EXT      = 0x8DD3,
    GL_UNSIGNED_INT_SAMPLER_CUBE_EXT    = 0x8DD4,
    GL_UNSIGNED_INT_SAMPLER_2D_RECT_EXT = 0x8DD5,
    GL_UNSIGNED_INT_SAMPLER_1D_ARRAY_EXT = 0x8DD6,
    GL_UNSIGNED_INT_SAMPLER_2D_ARRAY_EXT = 0x8DD7,
    GL_UNSIGNED_INT_SAMPLER_BUFFER_EXT  = 0x8DD8,
}

extern(System)
{
    void function(GLuint,GLuint,GLchar*) glBindFragDataLocationEXT;
    GLint function(GLuint,GLchar*) glGetFragDataLocationEXT;
    void function(GLuint,GLint,GLuint*) glGetUniformuivEXT;
    void function(GLuint,GLenum,GLint*) glGetVertexAttribIivEXT;
    void function(GLuint,GLenum,GLuint*) glGetVertexAttribIuivEXT;
    void function(GLint,GLuint) glUniform1uiEXT;
    void function(GLint,GLsizei,GLuint*) glUniform1uivEXT;
    void function(GLint,GLuint,GLuint) glUniform2uiEXT;
    void function(GLint,GLsizei,GLuint*) glUniform2uivEXT;
    void function(GLint,GLuint,GLuint,GLuint) glUniform3uiEXT;
    void function(GLint,GLsizei,GLuint*) glUniform3uivEXT;
    void function(GLint,GLuint,GLuint,GLuint,GLuint) glUniform4uiEXT;
    void function(GLint,GLsizei,GLuint*) glUniform4uivEXT;
    void function(GLuint,GLint) glVertexAttribI1iEXT;
    void function(GLuint,GLint*) glVertexAttribI1ivEXT;
    void function(GLuint,GLuint) glVertexAttribI1uiEXT;
    void function(GLuint,GLuint*) glVertexAttribI1uivEXT;
    void function(GLuint,GLint,GLint) glVertexAttribI2iEXT;
    void function(GLuint,GLint*) glVertexAttribI2ivEXT;
    void function(GLuint,GLuint,GLuint) glVertexAttribI2uiEXT;
    void function(GLuint,GLuint*) glVertexAttribI2uivEXT;
    void function(GLuint,GLint,GLint,GLint) glVertexAttribI3iEXT;
    void function(GLuint,GLint*) glVertexAttribI3ivEXT;
    void function(GLuint,GLuint,GLuint,GLuint) glVertexAttribI3uiEXT;
    void function(GLuint,GLuint*) glVertexAttribI3uivEXT;
    void function(GLuint,GLbyte*) glVertexAttribI4bvEXT;
    void function(GLuint,GLint,GLint,GLint,GLint) glVertexAttribI4iEXT;
    void function(GLuint,GLint*) glVertexAttribI4ivEXT;
    void function(GLuint,GLshort*) glVertexAttribI4svEXT;
    void function(GLuint,GLubyte*) glVertexAttribI4ubvEXT;
    void function(GLuint,GLuint,GLuint,GLuint,GLuint) glVertexAttribI4uiEXT;
    void function(GLuint,GLuint*) glVertexAttribI4uivEXT;
    void function(GLuint,GLushort*) glVertexAttribI4usvEXT;
    void function(GLuint,GLint,GLenum,GLenum,GLsizei,GLvoid*) glVertexAttribIPointerEXT;
}