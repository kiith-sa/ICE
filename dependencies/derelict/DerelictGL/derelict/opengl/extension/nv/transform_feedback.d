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
module derelict.opengl.extension.nv.transform_feedback;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVTransformFeedback
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_transform_feedback") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glBeginTransformFeedbackNV, "glBeginTransformFeedbackNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glEndTransformFeedbackNV, "glEndTransformFeedbackNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTransformFeedbackAttribsNV, "glTransformFeedbackAttribsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindBufferRangeNV, "glBindBufferRangeNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindBufferOffsetNV, "glBindBufferOffsetNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glBindBufferBaseNV, "glBindBufferBaseNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTransformFeedbackVaryingsNV, "glTransformFeedbackVaryingsNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glActiveVaryingNV, "glActiveVaryingNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetVaryingLocationNV, "glGetVaryingLocationNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetActiveVaryingNV, "glGetActiveVaryingNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTransformFeedbackVaryingNV, "glGetTransformFeedbackVaryingNV"))
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
        DerelictGL.registerExtensionLoader(&NVTransformFeedback.load);
    }
}

enum : GLenum
{
    GL_BACK_PRIMARY_COLOR_NV                            = 0x8C77,
    GL_BACK_SECONDARY_COLOR_NV                          = 0x8C78,
    GL_TEXTURE_COORD_NV                                 = 0x8C79,
    GL_CLIP_DISTANCE_NV                                 = 0x8C7A,
    GL_VERTEX_ID_NV                                     = 0x8C7B,
    GL_PRIMITIVE_ID_NV                                  = 0x8C7C,
    GL_GENERIC_ATTRIB_NV                                = 0x8C7D,
    GL_TRANSFORM_FEEDBACK_ATTRIBS_NV                    = 0x8C7E,
    GL_TRANSFORM_FEEDBACK_BUFFER_MODE_NV                = 0x8C7F,
    GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_NV    = 0x8C80,
    GL_ACTIVE_VARYINGS_NV                               = 0x8C81,
    GL_ACTIVE_VARYING_MAX_LENGTH_NV                     = 0x8C82,
    GL_TRANSFORM_FEEDBACK_VARYINGS_NV                   = 0x8C83,
    GL_TRANSFORM_FEEDBACK_BUFFER_START_NV               = 0x8C84,
    GL_TRANSFORM_FEEDBACK_BUFFER_SIZE_NV                = 0x8C85,
    GL_TRANSFORM_FEEDBACK_RECORD_NV                     = 0x8C86,
    GL_PRIMITIVES_GENERATED_NV                          = 0x8C87,
    GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_NV         = 0x8C88,
    GL_RASTERIZER_DISCARD_NV                            = 0x8C89,
    GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_ATTRIBS_NV    = 0x8C8A,
    GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_NV       = 0x8C8B,
    GL_INTERLEAVED_ATTRIBS_NV                           = 0x8C8C,
    GL_SEPARATE_ATTRIBS_NV                              = 0x8C8D,
    GL_TRANSFORM_FEEDBACK_BUFFER_NV                     = 0x8C8E,
    GL_TRANSFORM_FEEDBACK_BUFFER_BINDING_NV             = 0x8C8F,
}

extern(System)
{
    void function(GLenum) glBeginTransformFeedbackNV;
    void function() glEndTransformFeedbackNV;
    void function(GLuint,GLint*,GLenum) glTransformFeedbackAttribsNV;
    void function(GLenum,GLuint,GLuint,GLintptr,GLsizeiptr) glBindBufferRangeNV;
    void function(GLenum,GLuint,GLuint,GLintptr) glBindBufferOffsetNV;
    void function(GLenum,GLuint,GLuint) glBindBufferBaseNV;
    void function(GLuint,GLsizei,GLint*,GLenum) glTransformFeedbackVaryingsNV;
    void function(GLuint,GLchar*) glActiveVaryingNV;
    GLint function(GLuint,GLchar*) glGetVaryingLocationNV;
    void function(GLuint,GLuint,GLsizei,GLsizei*,GLsizei*,GLenum*,GLchar*) glGetActiveVaryingNV;
    void function(GLuint,GLuint,GLint*) glGetTransformFeedbackVaryingNV;
}