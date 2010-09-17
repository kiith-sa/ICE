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
module derelict.opengl.extension.ext.texture_integer;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTTextureInteger
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_texture_integer") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glClearColorIiEXT, "glClearColorIiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glClearColorIuiEXT, "glClearColorIuiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTexParameterIivEXT, "glGetTexParameterIivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTexParameterIuivEXT, "glGetTexParameterIuivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexParameterIivEXT, "glTexParameterIivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexParameterIuivEXT, "glTexParameterIuivEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTTextureInteger.load);
    }
}

enum : GLenum
{
    GL_RGBA32UI_EXT             = 0x8D70,
    GL_RGB32UI_EXT              = 0x8D71,
    GL_ALPHA32UI_EXT            = 0x8D72,
    GL_INTENSITY32UI_EXT        = 0x8D73,
    GL_LUMINANCE32UI_EXT        = 0x8D74,
    GL_LUMINANCE_ALPHA32UI_EXT  = 0x8D75,
    GL_RGBA16UI_EXT             = 0x8D76,
    GL_RGB16UI_EXT              = 0x8D77,
    GL_ALPHA16UI_EXT            = 0x8D78,
    GL_INTENSITY16UI_EXT        = 0x8D79,
    GL_LUMINANCE16UI_EXT        = 0x8D7A,
    GL_LUMINANCE_ALPHA16UI_EXT  = 0x8D7B,
    GL_RGBA8UI_EXT              = 0x8D7C,
    GL_RGB8UI_EXT               = 0x8D7D,
    GL_ALPHA8UI_EXT             = 0x8D7E,
    GL_INTENSITY8UI_EXT         = 0x8D7F,
    GL_LUMINANCE8UI_EXT         = 0x8D80,
    GL_LUMINANCE_ALPHA8UI_EXT   = 0x8D81,
    GL_RGBA32I_EXT              = 0x8D82,
    GL_RGB32I_EXT               = 0x8D83,
    GL_ALPHA32I_EXT             = 0x8D84,
    GL_INTENSITY32I_EXT         = 0x8D85,
    GL_LUMINANCE32I_EXT         = 0x8D86,
    GL_LUMINANCE_ALPHA32I_EXT   = 0x8D87,
    GL_RGBA16I_EXT              = 0x8D88,
    GL_RGB16I_EXT               = 0x8D89,
    GL_ALPHA16I_EXT             = 0x8D8A,
    GL_INTENSITY16I_EXT         = 0x8D8B,
    GL_LUMINANCE16I_EXT         = 0x8D8C,
    GL_LUMINANCE_ALPHA16I_EXT   = 0x8D8D,
    GL_RGBA8I_EXT               = 0x8D8E,
    GL_RGB8I_EXT                = 0x8D8F,
    GL_ALPHA8I_EXT              = 0x8D90,
    GL_INTENSITY8I_EXT          = 0x8D91,
    GL_LUMINANCE8I_EXT          = 0x8D92,
    GL_LUMINANCE_ALPHA8I_EXT    = 0x8D93,
    GL_RED_INTEGER_EXT          = 0x8D94,
    GL_GREEN_INTEGER_EXT        = 0x8D95,
    GL_BLUE_INTEGER_EXT         = 0x8D96,
    GL_ALPHA_INTEGER_EXT        = 0x8D97,
    GL_RGB_INTEGER_EXT          = 0x8D98,
    GL_RGBA_INTEGER_EXT         = 0x8D99,
    GL_BGR_INTEGER_EXT          = 0x8D9A,
    GL_BGRA_INTEGER_EXT         = 0x8D9B,
    GL_LUMINANCE_INTEGER_EXT    = 0x8D9C,
    GL_LUMINANCE_ALPHA_INTEGER_EXT = 0x8D9D,
    GL_RGBA_INTEGER_MODE_EXT    = 0x8D9E,
}

extern(System)
{
    void function(GLint,GLint,GLint,GLint) glClearColorIiEXT;
    void function(GLuint,GLuint,GLuint,GLuint) glClearColorIuiEXT;
    void function(GLenum,GLenum,GLint*) glGetTexParameterIivEXT;
    void function(GLenum,GLenum,GLuint*) glGetTexParameterIuivEXT;
    void function(GLenum,GLenum,GLint*) glTexParameterIivEXT;
    void function(GLenum,GLenum,GLuint*) glTexParameterIuivEXT;
}