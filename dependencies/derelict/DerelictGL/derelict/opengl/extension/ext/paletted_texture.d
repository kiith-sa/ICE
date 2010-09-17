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
module derelict.opengl.extension.ext.paletted_texture;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTPalettedTexture
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_paletted_texture") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glColorTableEXT, "glColorTableEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetColorTableEXT, "glGetColorTableEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetColorTableParameterivEXT, "glGetColorTableParameterivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetColorTableParameterfvEXT, "glGetColorTableParameterfvEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTPalettedTexture.load);
    }
}

enum : GLenum
{
    GL_COLOR_INDEX1_EXT               = 0x80E2,
    GL_COLOR_INDEX2_EXT               = 0x80E3,
    GL_COLOR_INDEX4_EXT               = 0x80E4,
    GL_COLOR_INDEX8_EXT               = 0x80E5,
    GL_COLOR_INDEX12_EXT              = 0x80E6,
    GL_COLOR_INDEX16_EXT              = 0x80E7,
    GL_TEXTURE_INDEX_SIZE_EXT         = 0x80ED,
}

extern(System)
{
    void function(GLenum, GLenum, GLsizei, GLenum, GLenum, GLvoid*) glColorTableEXT;
    void function(GLenum, GLenum, GLenum, GLvoid*) glGetColorTableEXT;
    void function(GLenum, GLenum, GLint*) glGetColorTableParameterivEXT;
    void function(GLenum, GLenum, GLfloat*) glGetColorTableParameterfvEXT;
}