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
module derelict.opengl.extension.ext.geometry_shader4;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTGeometryShader4
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_geometry_shader4") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glFramebufferTextureEXT, "glFramebufferTextureEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFramebufferTextureFaceEXT, "glFramebufferTextureFaceEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFramebufferTextureLayerEXT, "glFramebufferTextureLayerEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramParameteriEXT, "glProgramParameteriEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTGeometryShader4.load);
    }
}

enum : GLenum
{
    GL_LINES_ADJACENCY_EXT                      = 0xA,
    GL_LINE_STRIP_ADJACENCY_EXT                 = 0xB,
    GL_TRIANGLES_ADJACENCY_EXT                  = 0xC,
    GL_TRIANGLE_STRIP_ADJACENCY_EXT             = 0xD,
    GL_PROGRAM_POINT_SIZE_EXT                   = 0x8642,
    GL_MAX_VARYING_COMPONENTS_EXT               = 0x8B4B,
    GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_EXT     = 0x8C29,
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT = 0x8CD4,
    GL_FRAMEBUFFER_ATTACHMENT_LAYERED_EXT       = 0x8DA7,
    GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_EXT = 0x8DA8,
    GL_FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_EXT   = 0x8DA9,
    GL_GEOMETRY_SHADER_EXT                      = 0x8DD9,
    GL_GEOMETRY_VERTICES_OUT_EXT                = 0x8DDA,
    GL_GEOMETRY_INPUT_TYPE_EXT                  = 0x8DDB,
    GL_GEOMETRY_OUTPUT_TYPE_EXT                 = 0x8DDC,
    GL_MAX_GEOMETRY_VARYING_COMPONENTS_EXT      = 0x8DDD,
    GL_MAX_VERTEX_VARYING_COMPONENTS_EXT        = 0x8DDE,
    GL_MAX_GEOMETRY_UNIFORM_COMPONENTS_EXT      = 0x8DDF,
    GL_MAX_GEOMETRY_OUTPUT_VERTICES_EXT         = 0x8DE0,
    GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_EXT = 0x8DE1,
}

extern(System)
{
    void function(GLenum,GLenum,GLuint,GLint) glFramebufferTextureEXT;
    void function(GLenum,GLenum,GLuint,GLint,GLenum) glFramebufferTextureFaceEXT;
    void function(GLenum,GLenum,GLuint,GLint,GLint) glFramebufferTextureLayerEXT;
    void function(GLuint,GLenum,GLint) glProgramParameteriEXT;
}