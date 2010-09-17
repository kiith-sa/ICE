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
module derelict.opengl.extension.arb.texture_compression;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBTextureCompression
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_texture_compression") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexImage3DARB, "glCompressedTexImage3DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexImage2DARB, "glCompressedTexImage2DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexImage1DARB, "glCompressedTexImage1DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexSubImage3DARB, "glCompressedTexSubImage3DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexSubImage2DARB, "glCompressedTexSubImage2DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCompressedTexSubImage1DARB, "glCompressedTexSubImage1DARB"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetCompressedTexImageARB, "glGetCompressedTexImageARB"))
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
        DerelictGL.registerExtensionLoader(&ARBTextureCompression.load);
    }
}

enum : GLenum
{
    GL_COMPRESSED_ALPHA_ARB                = 0x84E9,
    GL_COMPRESSED_LUMINANCE_ARB            = 0x84EA,
    GL_COMPRESSED_LUMINANCE_ALPHA_ARB      = 0x84EB,
    GL_COMPRESSED_INTENSITY_ARB            = 0x84EC,
    GL_COMPRESSED_RGB_ARB                  = 0x84ED,
    GL_COMPRESSED_RGBA_ARB                 = 0x84EE,
    GL_TEXTURE_COMPRESSION_HINT_ARB        = 0x84EF,
    GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB   = 0x86A0,
    GL_TEXTURE_COMPRESSED_ARB              = 0x86A1,
    GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB  = 0x86A2,
    GL_COMPRESSED_TEXTURE_FORMATS_ARB      = 0x86A3,
}

extern(System)
{
    void function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei, GLint, GLsizei, GLvoid*) glCompressedTexImage3DARB;
    void function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, GLvoid*) glCompressedTexImage2DARB;
    void function(GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, GLvoid*) glCompressedTexImage1DARB;
    void function(GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage3DARB;
    void function(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage2DARB;
    void function(GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage1DARB;
    void function(GLenum, GLint, GLvoid*) glGetCompressedTexImageARB;
}