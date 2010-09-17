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
module derelict.opengl.extension.ati.vertex_array_object;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ATIVertexArrayObject
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ATI_vertex_array_object") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glNewObjectBufferATI, "glNewObjectBufferATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glIsObjectBufferATI, "glIsObjectBufferATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glUpdateObjectBufferATI, "glUpdateObjectBufferATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetObjectBufferfvATI, "glGetObjectBufferfvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetObjectBufferivATI, "glGetObjectBufferivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFreeObjectBufferATI, "glFreeObjectBufferATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glArrayObjectATI, "glArrayObjectATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetArrayObjectfvATI, "glGetArrayObjectfvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetArrayObjectivATI, "glGetArrayObjectivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVariantArrayObjectATI, "glVariantArrayObjectATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantArrayObjectfvATI, "glGetVariantArrayObjectfvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVariantArrayObjectivATI, "glGetVariantArrayObjectivATI"))
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
        DerelictGL.registerExtensionLoader(&ATIVertexArrayObject.load);
    }
}

enum : GLenum
{
    GL_STATIC_ATI                     = 0x8760,
    GL_DYNAMIC_ATI                    = 0x8761,
    GL_PRESERVE_ATI                   = 0x8762,
    GL_DISCARD_ATI                    = 0x8763,
    GL_OBJECT_BUFFER_SIZE_ATI         = 0x8764,
    GL_OBJECT_BUFFER_USAGE_ATI        = 0x8765,
    GL_ARRAY_OBJECT_BUFFER_ATI        = 0x8766,
    GL_ARRAY_OBJECT_OFFSET_ATI        = 0x8767,
}

extern(System)
{
    GLuint function(GLsizei, GLvoid*, GLenum) glNewObjectBufferATI;
    GLboolean function(GLuint) glIsObjectBufferATI;
    void function(GLuint, GLuint, GLsizei, GLvoid*, GLenum) glUpdateObjectBufferATI;
    void function(GLuint, GLenum, GLfloat*) glGetObjectBufferfvATI;
    void function(GLuint, GLenum, GLint*) glGetObjectBufferivATI;
    void function(GLuint) glFreeObjectBufferATI;
    void function(GLenum, GLint, GLenum, GLsizei, GLuint, GLuint) glArrayObjectATI;
    void function(GLenum, GLenum, GLfloat*) glGetArrayObjectfvATI;
    void function(GLenum, GLenum, GLint*) glGetArrayObjectivATI;
    void function(GLuint, GLenum, GLsizei, GLuint, GLuint) glVariantArrayObjectATI;
    void function(GLuint, GLenum, GLfloat*) glGetVariantArrayObjectfvATI;
    void function(GLuint, GLenum, GLint*) glGetVariantArrayObjectivATI;
}