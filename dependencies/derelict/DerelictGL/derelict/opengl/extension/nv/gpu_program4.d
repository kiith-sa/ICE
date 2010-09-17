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
module derelict.opengl.extension.nv.gpu_program4;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVGpuProgram4
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_gpu_program4") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glProgramLocalParameterI4iNV, "glProgramLocalParameterI4iNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameterI4ivNV, "glProgramLocalParameterI4ivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParametersI4ivNV, "glProgramLocalParametersI4ivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameterI4uiNV, "glProgramLocalParameterI4uiNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParameterI4uivNV, "glProgramLocalParameterI4uivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramLocalParametersI4uivNV, "glProgramLocalParametersI4uivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameterI4iNV, "glProgramEnvParameterI4iNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameterI4ivNV, "glProgramEnvParameterI4ivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParametersI4ivNV, "glProgramEnvParametersI4ivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameterI4uiNV, "glProgramEnvParameterI4uiNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParameterI4uivNV, "glProgramEnvParameterI4uivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glProgramEnvParametersI4uivNV, "glProgramEnvParametersI4uivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramLocalParameterIivNV, "glGetProgramLocalParameterIivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramLocalParameterIuivNV, "glGetProgramLocalParameterIuivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramEnvParameterIivNV, "glGetProgramEnvParameterIivNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetProgramEnvParameterIuivNV, "glGetProgramEnvParameterIuivNV"))
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
        DerelictGL.registerExtensionLoader(&NVGpuProgram4.load);
    }
}

enum : GLenum
{
    GL_MIN_PROGRAM_TEXEL_OFFSET_NV         = 0x8904,
    GL_MAX_PROGRAM_TEXEL_OFFSET_NV         = 0x8905,
    GL_PROGRAM_ATTRIB_COMPONENTS_NV        = 0x8906,
    GL_PROGRAM_RESULT_COMPONENTS_NV        = 0x8907,
    GL_MAX_PROGRAM_ATTRIB_COMPONENTS_NV    = 0x8908,
    GL_MAX_PROGRAM_RESULT_COMPONENTS_NV    = 0x8909,
    GL_MAX_PROGRAM_GENERIC_ATTRIBS_NV      = 0x8DA5,
    GL_MAX_PROGRAM_GENERIC_RESULTS_NV      = 0x8DA6,
}

extern(System)
{
    void function(GLenum, GLuint, GLint, GLint, GLint, GLint) glProgramLocalParameterI4iNV;
    void function(GLenum, GLuint, GLint*) glProgramLocalParameterI4ivNV;
    void function(GLenum, GLuint, GLsizei, GLint*) glProgramLocalParametersI4ivNV;
    void function(GLenum, GLuint, GLuint, GLuint, GLuint, GLuint) glProgramLocalParameterI4uiNV;
    void function(GLenum, GLuint, GLuint*) glProgramLocalParameterI4uivNV;
    void function(GLenum, GLuint, GLsizei, GLuint*) glProgramLocalParametersI4uivNV;
    void function(GLenum, GLuint,. GLint, GLint, GLint, GLint) glProgramEnvParameterI4iNV;
    void function(GLenum, GLuint, GLint*) glProgramEnvParameterI4ivNV;
    void function(GLenum, GLuint, GLsizei, GLint*) glProgramEnvParametersI4ivNV;
    void function(GLenum, GLuint,. GLuint, GLuint, GLuint, GLuint) glProgramEnvParameterI4uiNV;
    void function(GLenum, GLuint, GLuint*) glProgramEnvParameterI4uivNV;
    void function(GLenum, GLuint, GLsizei, GLuint*) glProgramEnvParametersI4uivNV;
    void function(GLenum, GLuint, GLint*) glGetProgramLocalParameterIivNV;
    void function(GLenum, GLuint, GLuint*) glGetProgramLocalParameterIuivNV;
    void function(GLenum, GLuint, GLint*) glGetProgramEnvParameterIivNV;
    void function(GLenum, GLuint, GLuint*) glGetProgramEnvParameterIuivNV;
}