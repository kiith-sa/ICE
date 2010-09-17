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
module derelict.opengl.extension.arb.vertex_shader;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
    import derelict.opengl.extension.arb.shader_objects;
}

private bool enabled = false;

struct ARBVertexShader
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_vertex_shader") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glBindAttribLocationARB, "glBindAttribLocationARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetActiveAttribARB, "glGetActiveAttribARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetAttribLocationARB, "glGetAttribLocationARB"))
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
        DerelictGL.registerExtensionLoader(&ARBVertexShader.load);
    }
}

enum : GLenum
{
    GL_VERTEX_SHADER_ARB                       = 0x8B31,
    GL_MAX_VERTEX_UNIFORM_COMPONENTS_ARB       = 0x8B4A,
    GL_MAX_VARYING_FLOATS_ARB                  = 0x8B4B,
    GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB      = 0x8B4C,
    GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB    = 0x8B4D,
    GL_OBJECT_ACTIVE_ATTRIBUTES_ARB            = 0x8B89,
    GL_OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB  = 0x8B8A,
}

extern(System)
{
    void function (GLhandleARB, GLuint, GLcharARB*) glBindAttribLocationARB;
    void function (GLhandleARB, GLuint, GLsizei, GLsizei*, GLint*, GLenum*, GLcharARB*) glGetActiveAttribARB;
    GLint function (GLhandleARB, GLcharARB* name) glGetAttribLocationARB;
}