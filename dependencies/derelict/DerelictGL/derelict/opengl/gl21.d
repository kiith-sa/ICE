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
module derelict.opengl.gl21;

private
{
    import derelict.util.loader;
    import derelict.util.exception;
    import derelict.opengl.gltypes;
    version(Windows)
        import derelict.opengl.wgl;
}

package void loadGL21(SharedLib lib)
{
    version(Windows)
    {
        wglBindFunc(cast(void**)&glUniformMatrix2x3fv, "glUniformMatrix2x3fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix3x2fv, "glUniformMatrix3x2fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix2x4fv, "glUniformMatrix2x4fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix4x2fv, "glUniformMatrix4x2fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix3x4fv, "glUniformMatrix3x4fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix4x3fv, "glUniformMatrix4x3fv", lib);
    }
    else
    {
        bindFunc(glUniformMatrix2x3fv)("glUniformMatrix2x3fv", lib);
        bindFunc(glUniformMatrix3x2fv)("glUniformMatrix3x2fv", lib);
        bindFunc(glUniformMatrix2x4fv)("glUniformMatrix2x4fv", lib);
        bindFunc(glUniformMatrix4x2fv)("glUniformMatrix4x2fv", lib);
        bindFunc(glUniformMatrix3x4fv)("glUniformMatrix3x4fv", lib);
        bindFunc(glUniformMatrix4x3fv)("glUniformMatrix4x3fv", lib);
    }
}

enum : GLenum
{
    GL_CURRENT_RASTER_SECONDARY_COLOR = 0x845F,
    GL_PIXEL_PACK_BUFFER              = 0x88EB,
    GL_PIXEL_UNPACK_BUFFER            = 0x88EC,
    GL_PIXEL_PACK_BUFFER_BINDING      = 0x88ED,
    GL_PIXEL_UNPACK_BUFFER_BINDING    = 0x88EF,
    GL_FLOAT_MAT2x3                   = 0x8B65,
    GL_FLOAT_MAT2x4                   = 0x8B66,
    GL_FLOAT_MAT3x2                   = 0x8B67,
    GL_FLOAT_MAT3x4                   = 0x8B68,
    GL_FLOAT_MAT4x2                   = 0x8B69,
    GL_FLOAT_MAT4x3                   = 0x8B6A,
    GL_SRGB                           = 0x8C40,
    GL_SRGB8                          = 0x8C41,
    GL_SRGB_ALPHA                     = 0x8C42,
    GL_SRGB8_ALPHA8                   = 0x8C43,
    GL_SLUMINANCE_ALPHA               = 0x8C44,
    GL_SLUMINANCE8_ALPHA8             = 0x8C45,
    GL_SLUMINANCE                     = 0x8C46,
    GL_SLUMINANCE8                    = 0x8C47,
    GL_COMPRESSED_SRGB                = 0x8C48,
    GL_COMPRESSED_SRGB_ALPHA          = 0x8C49,
    GL_COMPRESSED_SLUMINANCE          = 0x8C4A,
    GL_COMPRESSED_SLUMINANCE_ALPHA    = 0x8C4B,
}

extern(System)
{
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix2x3fv;
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix3x2fv;
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix2x4fv;
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix4x2fv;
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix3x4fv;
    void function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix4x3fv;
}