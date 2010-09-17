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
module derelict.opengl.gl20;

private
{
    import derelict.util.loader;
    import derelict.util.exception;
    import derelict.opengl.gltypes;
    version(Windows)
        import derelict.opengl.wgl;
}

package void loadGL20(SharedLib lib)
{
    version(Windows)
    {
        wglBindFunc(cast(void**)&glBlendEquationSeparate, "glBlendEquationSeparate", lib);
        wglBindFunc(cast(void**)&glDrawBuffers, "glDrawBuffers", lib);
        wglBindFunc(cast(void**)&glStencilOpSeparate, "glStencilOpSeparate", lib);
        wglBindFunc(cast(void**)&glStencilFuncSeparate, "glStencilFuncSeparate", lib);
        wglBindFunc(cast(void**)&glStencilMaskSeparate, "glStencilMaskSeparate", lib);
        wglBindFunc(cast(void**)&glAttachShader, "glAttachShader", lib);
        wglBindFunc(cast(void**)&glBindAttribLocation, "glBindAttribLocation", lib);
        wglBindFunc(cast(void**)&glCompileShader, "glCompileShader", lib);
        wglBindFunc(cast(void**)&glCreateProgram, "glCreateProgram", lib);
        wglBindFunc(cast(void**)&glCreateShader, "glCreateShader", lib);
        wglBindFunc(cast(void**)&glDeleteProgram, "glDeleteProgram", lib);
        wglBindFunc(cast(void**)&glDeleteShader, "glDeleteShader", lib);
        wglBindFunc(cast(void**)&glDetachShader, "glDetachShader", lib);
        wglBindFunc(cast(void**)&glDisableVertexAttribArray, "glDisableVertexAttribArray", lib);
        wglBindFunc(cast(void**)&glEnableVertexAttribArray, "glEnableVertexAttribArray", lib);
        wglBindFunc(cast(void**)&glGetActiveAttrib, "glGetActiveAttrib", lib);
        wglBindFunc(cast(void**)&glGetActiveUniform, "glGetActiveUniform", lib);
        wglBindFunc(cast(void**)&glGetAttachedShaders, "glGetAttachedShaders", lib);
        wglBindFunc(cast(void**)&glGetAttribLocation, "glGetAttribLocation", lib);
        wglBindFunc(cast(void**)&glGetProgramiv, "glGetProgramiv", lib);
        wglBindFunc(cast(void**)&glGetProgramInfoLog, "glGetProgramInfoLog", lib);
        wglBindFunc(cast(void**)&glGetShaderiv, "glGetShaderiv", lib);
        wglBindFunc(cast(void**)&glGetShaderInfoLog, "glGetShaderInfoLog", lib);
        wglBindFunc(cast(void**)&glGetShaderSource, "glGetShaderSource", lib);
        wglBindFunc(cast(void**)&glGetUniformLocation, "glGetUniformLocation", lib);
        wglBindFunc(cast(void**)&glGetUniformfv, "glGetUniformfv", lib);
        wglBindFunc(cast(void**)&glGetUniformiv, "glGetUniformiv", lib);
        wglBindFunc(cast(void**)&glGetVertexAttribdv, "glGetVertexAttribdv", lib);
        wglBindFunc(cast(void**)&glGetVertexAttribfv, "glGetVertexAttribfv", lib);
        wglBindFunc(cast(void**)&glGetVertexAttribiv, "glGetVertexAttribiv", lib);
        wglBindFunc(cast(void**)&glGetVertexAttribPointerv, "glGetVertexAttribPointerv", lib);
        wglBindFunc(cast(void**)&glIsProgram, "glIsProgram", lib);
        wglBindFunc(cast(void**)&glIsShader, "glIsShader", lib);
        wglBindFunc(cast(void**)&glLinkProgram, "glLinkProgram", lib);
        wglBindFunc(cast(void**)&glShaderSource, "glShaderSource", lib);
        wglBindFunc(cast(void**)&glUseProgram, "glUseProgram", lib);
        wglBindFunc(cast(void**)&glUniform1f, "glUniform1f", lib);
        wglBindFunc(cast(void**)&glUniform2f, "glUniform2f", lib);
        wglBindFunc(cast(void**)&glUniform3f, "glUniform3f", lib);
        wglBindFunc(cast(void**)&glUniform4f, "glUniform4f", lib);
        wglBindFunc(cast(void**)&glUniform1i, "glUniform1i", lib);
        wglBindFunc(cast(void**)&glUniform2i, "glUniform2i", lib);
        wglBindFunc(cast(void**)&glUniform3i, "glUniform3i", lib);
        wglBindFunc(cast(void**)&glUniform4i, "glUniform4i", lib);
        wglBindFunc(cast(void**)&glUniform1fv, "glUniform1fv", lib);
        wglBindFunc(cast(void**)&glUniform2fv, "glUniform2fv", lib);
        wglBindFunc(cast(void**)&glUniform3fv, "glUniform3fv", lib);
        wglBindFunc(cast(void**)&glUniform4fv, "glUniform4fv", lib);
        wglBindFunc(cast(void**)&glUniform1iv, "glUniform1iv", lib);
        wglBindFunc(cast(void**)&glUniform2iv, "glUniform2iv", lib);
        wglBindFunc(cast(void**)&glUniform3iv, "glUniform3iv", lib);
        wglBindFunc(cast(void**)&glUniform4iv, "glUniform4iv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix2fv, "glUniformMatrix2fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix3fv, "glUniformMatrix3fv", lib);
        wglBindFunc(cast(void**)&glUniformMatrix4fv, "glUniformMatrix4fv", lib);
        wglBindFunc(cast(void**)&glValidateProgram, "glValidateProgram", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1d, "glVertexAttrib1d", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1dv, "glVertexAttrib1dv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1f, "glVertexAttrib1f", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1fv, "glVertexAttrib1fv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1s, "glVertexAttrib1s", lib);
        wglBindFunc(cast(void**)&glVertexAttrib1sv, "glVertexAttrib1sv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2d, "glVertexAttrib2d", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2dv, "glVertexAttrib2dv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2f, "glVertexAttrib2f", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2fv, "glVertexAttrib2fv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2s, "glVertexAttrib2s", lib);
        wglBindFunc(cast(void**)&glVertexAttrib2sv, "glVertexAttrib2sv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3d, "glVertexAttrib3d", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3dv, "glVertexAttrib3dv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3f, "glVertexAttrib3f", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3fv, "glVertexAttrib3fv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3s, "glVertexAttrib3s", lib);
        wglBindFunc(cast(void**)&glVertexAttrib3sv, "glVertexAttrib3sv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nbv, "glVertexAttrib4Nbv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Niv, "glVertexAttrib4Niv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nsv, "glVertexAttrib4Nsv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nub, "glVertexAttrib4Nub", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nubv, "glVertexAttrib4Nubv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nuiv, "glVertexAttrib4Nuiv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4Nusv, "glVertexAttrib4Nusv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4bv, "glVertexAttrib4bv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4d, "glVertexAttrib4d", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4dv, "glVertexAttrib4dv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4f, "glVertexAttrib4f", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4fv, "glVertexAttrib4fv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4iv, "glVertexAttrib4iv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4s, "glVertexAttrib4s", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4sv, "glVertexAttrib4sv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4ubv, "glVertexAttrib4ubv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4uiv, "glVertexAttrib4uiv", lib);
        wglBindFunc(cast(void**)&glVertexAttrib4usv, "glVertexAttrib4usv", lib);
        wglBindFunc(cast(void**)&glVertexAttribPointer, "glVertexAttribPointer", lib);
    }
    else
    {
        bindFunc(glBlendEquationSeparate)("glBlendEquationSeparate", lib);
        bindFunc(glDrawBuffers)("glDrawBuffers", lib);
        bindFunc(glStencilOpSeparate)("glStencilOpSeparate", lib);
        bindFunc(glStencilFuncSeparate)("glStencilFuncSeparate", lib);
        bindFunc(glStencilMaskSeparate)("glStencilMaskSeparate", lib);
        bindFunc(glAttachShader)("glAttachShader", lib);
        bindFunc(glBindAttribLocation)("glBindAttribLocation", lib);
        bindFunc(glCompileShader)("glCompileShader", lib);
        bindFunc(glCreateProgram)("glCreateProgram", lib);
        bindFunc(glCreateShader)("glCreateShader", lib);
        bindFunc(glDeleteProgram)("glDeleteProgram", lib);
        bindFunc(glDeleteShader)("glDeleteShader", lib);
        bindFunc(glDetachShader)("glDetachShader", lib);
        bindFunc(glDisableVertexAttribArray)("glDisableVertexAttribArray", lib);
        bindFunc(glEnableVertexAttribArray)("glEnableVertexAttribArray", lib);
        bindFunc(glGetActiveAttrib)("glGetActiveAttrib", lib);
        bindFunc(glGetActiveUniform)("glGetActiveUniform", lib);
        bindFunc(glGetAttachedShaders)("glGetAttachedShaders", lib);
        bindFunc(glGetAttribLocation)("glGetAttribLocation", lib);
        bindFunc(glGetProgramiv)("glGetProgramiv", lib);
        bindFunc(glGetProgramInfoLog)("glGetProgramInfoLog", lib);
        bindFunc(glGetShaderiv)("glGetShaderiv", lib);
        bindFunc(glGetShaderInfoLog)("glGetShaderInfoLog", lib);
        bindFunc(glGetShaderSource)("glGetShaderSource", lib);
        bindFunc(glGetUniformLocation)("glGetUniformLocation", lib);
        bindFunc(glGetUniformfv)("glGetUniformfv", lib);
        bindFunc(glGetUniformiv)("glGetUniformiv", lib);
        bindFunc(glGetVertexAttribdv)("glGetVertexAttribdv", lib);
        bindFunc(glGetVertexAttribfv)("glGetVertexAttribfv", lib);
        bindFunc(glGetVertexAttribiv)("glGetVertexAttribiv", lib);
        bindFunc(glGetVertexAttribPointerv)("glGetVertexAttribPointerv", lib);
        bindFunc(glIsProgram)("glIsProgram", lib);
        bindFunc(glIsShader)("glIsShader", lib);
        bindFunc(glLinkProgram)("glLinkProgram", lib);
        bindFunc(glShaderSource)("glShaderSource", lib);
        bindFunc(glUseProgram)("glUseProgram", lib);
        bindFunc(glUniform1f)("glUniform1f", lib);
        bindFunc(glUniform2f)("glUniform2f", lib);
        bindFunc(glUniform3f)("glUniform3f", lib);
        bindFunc(glUniform4f)("glUniform4f", lib);
        bindFunc(glUniform1i)("glUniform1i", lib);
        bindFunc(glUniform2i)("glUniform2i", lib);
        bindFunc(glUniform3i)("glUniform3i", lib);
        bindFunc(glUniform4i)("glUniform4i", lib);
        bindFunc(glUniform1fv)("glUniform1fv", lib);
        bindFunc(glUniform2fv)("glUniform2fv", lib);
        bindFunc(glUniform3fv)("glUniform3fv", lib);
        bindFunc(glUniform4fv)("glUniform4fv", lib);
        bindFunc(glUniform1iv)("glUniform1iv", lib);
        bindFunc(glUniform2iv)("glUniform2iv", lib);
        bindFunc(glUniform3iv)("glUniform3iv", lib);
        bindFunc(glUniform4iv)("glUniform4iv", lib);
        bindFunc(glUniformMatrix2fv)("glUniformMatrix2fv", lib);
        bindFunc(glUniformMatrix3fv)("glUniformMatrix3fv", lib);
        bindFunc(glUniformMatrix4fv)("glUniformMatrix4fv", lib);
        bindFunc(glValidateProgram)("glValidateProgram", lib);
        bindFunc(glVertexAttrib1d)("glVertexAttrib1d", lib);
        bindFunc(glVertexAttrib1dv)("glVertexAttrib1dv", lib);
        bindFunc(glVertexAttrib1f)("glVertexAttrib1f", lib);
        bindFunc(glVertexAttrib1fv)("glVertexAttrib1fv", lib);
        bindFunc(glVertexAttrib1s)("glVertexAttrib1s", lib);
        bindFunc(glVertexAttrib1sv)("glVertexAttrib1sv", lib);
        bindFunc(glVertexAttrib2d)("glVertexAttrib2d", lib);
        bindFunc(glVertexAttrib2dv)("glVertexAttrib2dv", lib);
        bindFunc(glVertexAttrib2f)("glVertexAttrib2f", lib);
        bindFunc(glVertexAttrib2fv)("glVertexAttrib2fv", lib);
        bindFunc(glVertexAttrib2s)("glVertexAttrib2s", lib);
        bindFunc(glVertexAttrib2sv)("glVertexAttrib2sv", lib);
        bindFunc(glVertexAttrib3d)("glVertexAttrib3d", lib);
        bindFunc(glVertexAttrib3dv)("glVertexAttrib3dv", lib);
        bindFunc(glVertexAttrib3f)("glVertexAttrib3f", lib);
        bindFunc(glVertexAttrib3fv)("glVertexAttrib3fv", lib);
        bindFunc(glVertexAttrib3s)("glVertexAttrib3s", lib);
        bindFunc(glVertexAttrib3sv)("glVertexAttrib3sv", lib);
        bindFunc(glVertexAttrib4Nbv)("glVertexAttrib4Nbv", lib);
        bindFunc(glVertexAttrib4Niv)("glVertexAttrib4Niv", lib);
        bindFunc(glVertexAttrib4Nsv)("glVertexAttrib4Nsv", lib);
        bindFunc(glVertexAttrib4Nub)("glVertexAttrib4Nub", lib);
        bindFunc(glVertexAttrib4Nubv)("glVertexAttrib4Nubv", lib);
        bindFunc(glVertexAttrib4Nuiv)("glVertexAttrib4Nuiv", lib);
        bindFunc(glVertexAttrib4Nusv)("glVertexAttrib4Nusv", lib);
        bindFunc(glVertexAttrib4bv)("glVertexAttrib4bv", lib);
        bindFunc(glVertexAttrib4d)("glVertexAttrib4d", lib);
        bindFunc(glVertexAttrib4dv)("glVertexAttrib4dv", lib);
        bindFunc(glVertexAttrib4f)("glVertexAttrib4f", lib);
        bindFunc(glVertexAttrib4fv)("glVertexAttrib4fv", lib);
        bindFunc(glVertexAttrib4iv)("glVertexAttrib4iv", lib);
        bindFunc(glVertexAttrib4s)("glVertexAttrib4s", lib);
        bindFunc(glVertexAttrib4sv)("glVertexAttrib4sv", lib);
        bindFunc(glVertexAttrib4ubv)("glVertexAttrib4ubv", lib);
        bindFunc(glVertexAttrib4uiv)("glVertexAttrib4uiv", lib);
        bindFunc(glVertexAttrib4usv)("glVertexAttrib4usv", lib);
        bindFunc(glVertexAttribPointer)("glVertexAttribPointer", lib);

    }
}

enum : GLenum
{
    GL_BLEND_EQUATION_RGB              = 0x8009,
    GL_VERTEX_ATTRIB_ARRAY_ENABLED     = 0x8622,
    GL_VERTEX_ATTRIB_ARRAY_SIZE        = 0x8623,
    GL_VERTEX_ATTRIB_ARRAY_STRIDE      = 0x8624,
    GL_VERTEX_ATTRIB_ARRAY_TYPE        = 0x8625,
    GL_CURRENT_VERTEX_ATTRIB           = 0x8626,
    GL_VERTEX_PROGRAM_POINT_SIZE       = 0x8642,
    GL_VERTEX_PROGRAM_TWO_SIDE         = 0x8643,
    GL_VERTEX_ATTRIB_ARRAY_POINTER     = 0x8645,
    GL_STENCIL_BACK_FUNC               = 0x8800,
    GL_STENCIL_BACK_FAIL               = 0x8801,
    GL_STENCIL_BACK_PASS_DEPTH_FAIL    = 0x8802,
    GL_STENCIL_BACK_PASS_DEPTH_PASS    = 0x8803,
    GL_MAX_DRAW_BUFFERS                = 0x8824,
    GL_DRAW_BUFFER0                    = 0x8825,
    GL_DRAW_BUFFER1                    = 0x8826,
    GL_DRAW_BUFFER2                    = 0x8827,
    GL_DRAW_BUFFER3                    = 0x8828,
    GL_DRAW_BUFFER4                    = 0x8829,
    GL_DRAW_BUFFER5                    = 0x882A,
    GL_DRAW_BUFFER6                    = 0x882B,
    GL_DRAW_BUFFER7                    = 0x882C,
    GL_DRAW_BUFFER8                    = 0x882D,
    GL_DRAW_BUFFER9                    = 0x882E,
    GL_DRAW_BUFFER10                   = 0x882F,
    GL_DRAW_BUFFER11                   = 0x8830,
    GL_DRAW_BUFFER12                   = 0x8831,
    GL_DRAW_BUFFER13                   = 0x8832,
    GL_DRAW_BUFFER14                   = 0x8833,
    GL_DRAW_BUFFER15                   = 0x8834,
    GL_BLEND_EQUATION_ALPHA            = 0x883D,
    GL_POINT_SPRITE                    = 0x8861,
    GL_COORD_REPLACE                   = 0x8862,
    GL_MAX_VERTEX_ATTRIBS              = 0x8869,
    GL_VERTEX_ATTRIB_ARRAY_NORMALIZED  = 0x886A,
    GL_MAX_TEXTURE_COORDS              = 0x8871,
    GL_MAX_TEXTURE_IMAGE_UNITS         = 0x8872,
    GL_FRAGMENT_SHADER                 = 0x8B30,
    GL_VERTEX_SHADER                   = 0x8B31,
    GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49,
    GL_MAX_VERTEX_UNIFORM_COMPONENTS   = 0x8B4A,
    GL_MAX_VARYING_FLOATS              = 0x8B4B,
    GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS  = 0x8B4C,
    GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS= 0x8B4D,
    GL_SHADER_TYPE                     = 0x8B4F,
    GL_FLOAT_VEC2                      = 0x8B50,
    GL_FLOAT_VEC3                      = 0x8B51,
    GL_FLOAT_VEC4                      = 0x8B52,
    GL_INT_VEC2                        = 0x8B53,
    GL_INT_VEC3                        = 0x8B54,
    GL_INT_VEC4                        = 0x8B55,
    GL_BOOL                            = 0x8B56,
    GL_BOOL_VEC2                       = 0x8B57,
    GL_BOOL_VEC3                       = 0x8B58,
    GL_BOOL_VEC4                       = 0x8B59,
    GL_FLOAT_MAT2                      = 0x8B5A,
    GL_FLOAT_MAT3                      = 0x8B5B,
    GL_FLOAT_MAT4                      = 0x8B5C,
    GL_SAMPLER_1D                      = 0x8B5D,
    GL_SAMPLER_2D                      = 0x8B5E,
    GL_SAMPLER_3D                      = 0x8B5F,
    GL_SAMPLER_CUBE                    = 0x8B60,
    GL_SAMPLER_1D_SHADOW               = 0x8B61,
    GL_SAMPLER_2D_SHADOW               = 0x8B62,
    GL_DELETE_STATUS                   = 0x8B80,
    GL_COMPILE_STATUS                  = 0x8B81,
    GL_LINK_STATUS                     = 0x8B82,
    GL_VALIDATE_STATUS                 = 0x8B83,
    GL_INFO_LOG_LENGTH                 = 0x8B84,
    GL_ATTACHED_SHADERS                = 0x8B85,
    GL_ACTIVE_UNIFORMS                 = 0x8B86,
    GL_ACTIVE_UNIFORM_MAX_LENGTH       = 0x8B87,
    GL_SHADER_SOURCE_LENGTH            = 0x8B88,
    GL_ACTIVE_ATTRIBUTES               = 0x8B89,
    GL_ACTIVE_ATTRIBUTE_MAX_LENGTH     = 0x8B8A,
    GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B,
    GL_SHADING_LANGUAGE_VERSION        = 0x8B8C,
    GL_CURRENT_PROGRAM                 = 0x8B8D,
    GL_POINT_SPRITE_COORD_ORIGIN       = 0x8CA0,
    GL_LOWER_LEFT                      = 0x8CA1,
    GL_UPPER_LEFT                      = 0x8CA2,
    GL_STENCIL_BACK_REF                = 0x8CA3,
    GL_STENCIL_BACK_VALUE_MASK         = 0x8CA4,
    GL_STENCIL_BACK_WRITEMASK          = 0x8CA5,
}

extern(System)
{
	GLvoid function(GLenum, GLenum) glBlendEquationSeparate;
	GLvoid function(GLsizei, GLenum*) glDrawBuffers;
	GLvoid function(GLenum, GLenum, GLenum, GLenum) glStencilOpSeparate;
	GLvoid function(GLenum, GLenum, GLint, GLuint) glStencilFuncSeparate;
	GLvoid function(GLenum, GLuint) glStencilMaskSeparate;
	GLvoid function(GLuint, GLuint) glAttachShader;
	GLvoid function(GLuint, GLuint, GLchar*) glBindAttribLocation;
	GLvoid function(GLuint) glCompileShader;
	GLuint function() glCreateProgram;
	GLuint function(GLenum) glCreateShader;
	GLvoid function(GLuint) glDeleteProgram;
	GLvoid function(GLuint) glDeleteShader;
	GLvoid function(GLuint, GLuint) glDetachShader;
	GLvoid function(GLuint) glDisableVertexAttribArray;
	GLvoid function(GLuint) glEnableVertexAttribArray;
	GLvoid function(GLuint, GLuint, GLsizei, GLsizei*, GLint*, GLenum*, GLchar*) glGetActiveAttrib;
	GLvoid function(GLuint, GLuint, GLsizei, GLsizei*, GLint*, GLenum*, GLchar*) glGetActiveUniform;
	GLvoid function(GLuint, GLsizei, GLsizei*, GLuint*) glGetAttachedShaders;
	GLint function(GLuint, GLchar*) glGetAttribLocation;
	GLvoid function(GLuint, GLenum, GLint*) glGetProgramiv;
	GLvoid function(GLuint, GLsizei, GLsizei*, GLchar*) glGetProgramInfoLog;
	GLvoid function(GLuint, GLenum, GLint *) glGetShaderiv;
	GLvoid function(GLuint, GLsizei, GLsizei*, GLchar*) glGetShaderInfoLog;
	GLvoid function(GLuint, GLsizei, GLsizei*, GLchar*) glGetShaderSource;
	GLint function(GLuint, GLchar*) glGetUniformLocation;
	GLvoid function(GLuint, GLint, GLfloat*) glGetUniformfv;
	GLvoid function(GLuint, GLint, GLint*) glGetUniformiv;
	GLvoid function(GLuint, GLenum, GLdouble*) glGetVertexAttribdv;
	GLvoid function(GLuint, GLenum, GLfloat*) glGetVertexAttribfv;
	GLvoid function(GLuint, GLenum, GLint*) glGetVertexAttribiv;
	GLvoid function(GLuint, GLenum, GLvoid**) glGetVertexAttribPointerv;
	GLboolean function(GLuint) glIsProgram;
	GLboolean function(GLuint) glIsShader;
	GLvoid function(GLuint) glLinkProgram;
	GLvoid function(GLuint, GLsizei, GLchar**, GLint*) glShaderSource;
	GLvoid function(GLuint) glUseProgram;
	GLvoid function(GLint, GLfloat) glUniform1f;
	GLvoid function(GLint, GLfloat, GLfloat) glUniform2f;
	GLvoid function(GLint, GLfloat, GLfloat, GLfloat) glUniform3f;
	GLvoid function(GLint, GLfloat, GLfloat, GLfloat, GLfloat) glUniform4f;
	GLvoid function(GLint, GLint) glUniform1i;
	GLvoid function(GLint, GLint, GLint) glUniform2i;
	GLvoid function(GLint, GLint, GLint, GLint) glUniform3i;
	GLvoid function(GLint, GLint, GLint, GLint, GLint) glUniform4i;
	GLvoid function(GLint, GLsizei, GLfloat*) glUniform1fv;
	GLvoid function(GLint, GLsizei, GLfloat*) glUniform2fv;
	GLvoid function(GLint, GLsizei, GLfloat*) glUniform3fv;
	GLvoid function(GLint, GLsizei, GLfloat*) glUniform4fv;
	GLvoid function(GLint, GLsizei, GLint*) glUniform1iv;
	GLvoid function(GLint, GLsizei, GLint*) glUniform2iv;
	GLvoid function(GLint, GLsizei, GLint*) glUniform3iv;
	GLvoid function(GLint, GLsizei, GLint*) glUniform4iv;
	GLvoid function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix2fv;
	GLvoid function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix3fv;
	GLvoid function(GLint, GLsizei, GLboolean, GLfloat*) glUniformMatrix4fv;
	GLvoid function(GLuint) glValidateProgram;
	GLvoid function(GLuint, GLdouble) glVertexAttrib1d;
	GLvoid function(GLuint, GLdouble*) glVertexAttrib1dv;
	GLvoid function(GLuint, GLfloat) glVertexAttrib1f;
	GLvoid function(GLuint, GLfloat*) glVertexAttrib1fv;
	GLvoid function(GLuint, GLshort) glVertexAttrib1s;
	GLvoid function(GLuint, GLshort*) glVertexAttrib1sv;
	GLvoid function(GLuint, GLdouble, GLdouble) glVertexAttrib2d;
	GLvoid function(GLuint, GLdouble*) glVertexAttrib2dv;
	GLvoid function(GLuint, GLfloat, GLfloat) glVertexAttrib2f;
	GLvoid function(GLuint, GLfloat*) glVertexAttrib2fv;
	GLvoid function(GLuint, GLshort, GLshort) glVertexAttrib2s;
	GLvoid function(GLuint, GLshort*) glVertexAttrib2sv;
	GLvoid function(GLuint, GLdouble, GLdouble, GLdouble) glVertexAttrib3d;
	GLvoid function(GLuint, GLdouble*) glVertexAttrib3dv;
	GLvoid function(GLuint, GLfloat, GLfloat, GLfloat) glVertexAttrib3f;
	GLvoid function(GLuint, GLfloat*) glVertexAttrib3fv;
	GLvoid function(GLuint, GLshort, GLshort, GLshort) glVertexAttrib3s;
	GLvoid function(GLuint, GLshort*) glVertexAttrib3sv;
	GLvoid function(GLuint, GLbyte*) glVertexAttrib4Nbv;
	GLvoid function(GLuint, GLint*) glVertexAttrib4Niv;
	GLvoid function(GLuint, GLshort*) glVertexAttrib4Nsv;
	GLvoid function(GLuint, GLubyte, GLubyte, GLubyte, GLubyte) glVertexAttrib4Nub;
	GLvoid function(GLuint, GLubyte*) glVertexAttrib4Nubv;
	GLvoid function(GLuint, GLuint*) glVertexAttrib4Nuiv;
	GLvoid function(GLuint, GLushort*) glVertexAttrib4Nusv;
	GLvoid function(GLuint, GLbyte*) glVertexAttrib4bv;
	GLvoid function(GLuint, GLdouble, GLdouble, GLdouble, GLdouble) glVertexAttrib4d;
	GLvoid function(GLuint, GLdouble*) glVertexAttrib4dv;
	GLvoid function(GLuint, GLfloat, GLfloat, GLfloat, GLfloat) glVertexAttrib4f;
	GLvoid function(GLuint, GLfloat*) glVertexAttrib4fv;
	GLvoid function(GLuint, GLint*) glVertexAttrib4iv;
	GLvoid function(GLuint, GLshort, GLshort, GLshort, GLshort) glVertexAttrib4s;
	GLvoid function(GLuint, GLshort*) glVertexAttrib4sv;
	GLvoid function(GLuint, GLubyte*) glVertexAttrib4ubv;
	GLvoid function(GLuint, GLuint*) glVertexAttrib4uiv;
	GLvoid function(GLuint, GLushort*) glVertexAttrib4usv;
	GLvoid function(GLuint, GLint, GLenum, GLboolean, GLsizei, GLvoid*) glVertexAttribPointer;
}