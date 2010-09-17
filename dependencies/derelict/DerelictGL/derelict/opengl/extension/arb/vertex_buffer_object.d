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
module derelict.opengl.extension.arb.vertex_buffer_object;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBVertexBufferObject
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_vertex_buffer_object") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glBindBufferARB, "glBindBufferARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDeleteBuffersARB, "glDeleteBuffersARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGenBuffersARB, "glGenBuffersARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsBufferARB, "glIsBufferARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBufferDataARB, "glBufferDataARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBufferSubDataARB, "glBufferSubDataARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetBufferSubDataARB, "glGetBufferSubDataARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMapBufferARB, "glMapBufferARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUnmapBufferARB, "glUnmapBufferARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetBufferParameterivARB, "glGetBufferParameterivARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetBufferPointervARB, "glGetBufferPointervARB"))
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
        DerelictGL.registerExtensionLoader(&ARBVertexBufferObject.load);
    }
}

alias ptrdiff_t GLintptrARB;
alias ptrdiff_t GLsizeiptrARB;

enum : GLenum
{
    GL_BUFFER_SIZE_ARB                             = 0x8764,
    GL_BUFFER_USAGE_ARB                            = 0x8765,
    GL_ARRAY_BUFFER_ARB                            = 0x8892,
    GL_ELEMENT_ARRAY_BUFFER_ARB                    = 0x8893,
    GL_ARRAY_BUFFER_BINDING_ARB                    = 0x8894,
    GL_ELEMENT_ARRAY_BUFFER_BINDING_ARB            = 0x8895,
    GL_VERTEX_ARRAY_BUFFER_BINDING_ARB             = 0x8896,
    GL_NORMAL_ARRAY_BUFFER_BINDING_ARB             = 0x8897,
    GL_COLOR_ARRAY_BUFFER_BINDING_ARB              = 0x8898,
    GL_INDEX_ARRAY_BUFFER_BINDING_ARB              = 0x8899,
    GL_TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB      = 0x889A,
    GL_EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB          = 0x889B,
    GL_SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB    = 0x889C,
    GL_FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB     = 0x889D,
    GL_WEIGHT_ARRAY_BUFFER_BINDING_ARB             = 0x889E,
    GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB      = 0x889F,
    GL_READ_ONLY_ARB                               = 0x88B8,
    GL_WRITE_ONLY_ARB                              = 0x88B9,
    GL_READ_WRITE_ARB                              = 0x88BA,
    GL_BUFFER_ACCESS_ARB                           = 0x88BB,
    GL_BUFFER_MAPPED_ARB                           = 0x88BC,
    GL_BUFFER_MAP_POINTER_ARB                      = 0x88BD,
    GL_STREAM_DRAW_ARB                             = 0x88E0,
    GL_STREAM_READ_ARB                             = 0x88E1,
    GL_STREAM_COPY_ARB                             = 0x88E2,
    GL_STATIC_DRAW_ARB                             = 0x88E4,
    GL_STATIC_READ_ARB                             = 0x88E5,
    GL_STATIC_COPY_ARB                             = 0x88E6,
    GL_DYNAMIC_DRAW_ARB                            = 0x88E8,
    GL_DYNAMIC_READ_ARB                            = 0x88E9,
    GL_DYNAMIC_COPY_ARB                            = 0x88EA,
}

extern(System)
{
    void function(GLenum, GLuint) glBindBufferARB;
    void function(GLsizei, GLuint*) glDeleteBuffersARB;
    void function(GLsizei, GLuint*) glGenBuffersARB;
    GLboolean function(GLuint) glIsBufferARB;
    void function(GLenum, GLsizeiptrARB, GLvoid*, GLenum) glBufferDataARB;
    void function(GLenum, GLintptrARB, GLsizeiptrARB, GLvoid*) glBufferSubDataARB;
    void function(GLenum, GLintptrARB, GLsizeiptrARB, GLvoid*) glGetBufferSubDataARB;
    GLvoid* function(GLenum, GLenum) glMapBufferARB;
    GLboolean function(GLenum) glUnmapBufferARB;
    void function(GLenum, GLenum, GLint*) glGetBufferParameterivARB;
    void function(GLenum, GLenum, GLvoid*) glGetBufferPointervARB;
}