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
module derelict.opengl.gl14;

private
{
    import derelict.util.loader;
    import derelict.util.exception;
    import derelict.opengl.gltypes;
    version(Windows)
        import derelict.opengl.wgl;
}

package void loadGL14(SharedLib lib)
{
    version(Windows)
    {
        wglBindFunc(cast(void**)&glBlendFuncSeparate, "glBlendFuncSeparate", lib);
        wglBindFunc(cast(void**)&glFogCoordf, "glFogCoordf", lib);
        wglBindFunc(cast(void**)&glFogCoordfv, "glFogCoordfv", lib);
        wglBindFunc(cast(void**)&glFogCoordd, "glFogCoordd", lib);
        wglBindFunc(cast(void**)&glFogCoorddv, "glFogCoorddv", lib);
        wglBindFunc(cast(void**)&glFogCoordPointer, "glFogCoordPointer", lib);
        wglBindFunc(cast(void**)&glMultiDrawArrays, "glMultiDrawArrays", lib);
        wglBindFunc(cast(void**)&glMultiDrawElements, "glMultiDrawElements", lib);
        wglBindFunc(cast(void**)&glPointParameterf, "glPointParameterf", lib);
        wglBindFunc(cast(void**)&glPointParameterfv, "glPointParameterfv", lib);
        wglBindFunc(cast(void**)&glPointParameteri, "glPointParameteri", lib);
        wglBindFunc(cast(void**)&glPointParameteriv, "glPointParameteriv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3b, "glSecondaryColor3b", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3bv, "glSecondaryColor3bv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3d, "glSecondaryColor3d", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3dv, "glSecondaryColor3dv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3f, "glSecondaryColor3f", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3fv, "glSecondaryColor3fv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3i, "glSecondaryColor3i", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3iv, "glSecondaryColor3iv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3s, "glSecondaryColor3s", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3sv, "glSecondaryColor3sv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3ub, "glSecondaryColor3ub", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3ubv, "glSecondaryColor3ubv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3ui, "glSecondaryColor3ui", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3uiv, "glSecondaryColor3uiv", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3us, "glSecondaryColor3us", lib);
        wglBindFunc(cast(void**)&glSecondaryColor3usv, "glSecondaryColor3usv", lib);
        wglBindFunc(cast(void**)&glSecondaryColorPointer, "glSecondaryColorPointer", lib);
        wglBindFunc(cast(void**)&glWindowPos2d, "glWindowPos2d", lib);
        wglBindFunc(cast(void**)&glWindowPos2dv, "glWindowPos2dv", lib);
        wglBindFunc(cast(void**)&glWindowPos2f, "glWindowPos2f", lib);
        wglBindFunc(cast(void**)&glWindowPos2fv, "glWindowPos2fv", lib);
        wglBindFunc(cast(void**)&glWindowPos2i, "glWindowPos2i", lib);
        wglBindFunc(cast(void**)&glWindowPos2iv, "glWindowPos2iv", lib);
        wglBindFunc(cast(void**)&glWindowPos2s, "glWindowPos2s", lib);
        wglBindFunc(cast(void**)&glWindowPos2sv, "glWindowPos2sv", lib);
        wglBindFunc(cast(void**)&glWindowPos3d, "glWindowPos3d", lib);
        wglBindFunc(cast(void**)&glWindowPos3dv, "glWindowPos3dv", lib);
        wglBindFunc(cast(void**)&glWindowPos3f, "glWindowPos3f", lib);
        wglBindFunc(cast(void**)&glWindowPos3fv, "glWindowPos3fv", lib);
        wglBindFunc(cast(void**)&glWindowPos3i, "glWindowPos3i", lib);
        wglBindFunc(cast(void**)&glWindowPos3iv, "glWindowPos3iv", lib);
        wglBindFunc(cast(void**)&glWindowPos3s, "glWindowPos3s", lib);
        wglBindFunc(cast(void**)&glWindowPos3sv, "glWindowPos3sv", lib);
        wglBindFunc(cast(void**)&glBlendEquation, "glBlendEquation", lib);
        wglBindFunc(cast(void**)&glBlendColor, "glBlendColor", lib);
    }
    else
    {
        bindFunc(glBlendFuncSeparate)("glBlendFuncSeparate", lib);
        bindFunc(glFogCoordf)("glFogCoordf", lib);
        bindFunc(glFogCoordfv)("glFogCoordfv", lib);
        bindFunc(glFogCoordd)("glFogCoordd", lib);
        bindFunc(glFogCoorddv)("glFogCoorddv", lib);
        bindFunc(glFogCoordPointer)("glFogCoordPointer", lib);
        bindFunc(glMultiDrawArrays)("glMultiDrawArrays", lib);
        bindFunc(glMultiDrawElements)("glMultiDrawElements", lib);
        bindFunc(glPointParameterf)("glPointParameterf", lib);
        bindFunc(glPointParameterfv)("glPointParameterfv", lib);
        bindFunc(glPointParameteri)("glPointParameteri", lib);
        bindFunc(glPointParameteriv)("glPointParameteriv", lib);
        bindFunc(glSecondaryColor3b)("glSecondaryColor3b", lib);
        bindFunc(glSecondaryColor3bv)("glSecondaryColor3bv", lib);
        bindFunc(glSecondaryColor3d)("glSecondaryColor3d", lib);
        bindFunc(glSecondaryColor3dv)("glSecondaryColor3dv", lib);
        bindFunc(glSecondaryColor3f)("glSecondaryColor3f", lib);
        bindFunc(glSecondaryColor3fv)("glSecondaryColor3fv", lib);
        bindFunc(glSecondaryColor3i)("glSecondaryColor3i", lib);
        bindFunc(glSecondaryColor3iv)("glSecondaryColor3iv", lib);
        bindFunc(glSecondaryColor3s)("glSecondaryColor3s", lib);
        bindFunc(glSecondaryColor3sv)("glSecondaryColor3sv", lib);
        bindFunc(glSecondaryColor3ub)("glSecondaryColor3ub", lib);
        bindFunc(glSecondaryColor3ubv)("glSecondaryColor3ubv", lib);
        bindFunc(glSecondaryColor3ui)("glSecondaryColor3ui", lib);
        bindFunc(glSecondaryColor3uiv)("glSecondaryColor3uiv", lib);
        bindFunc(glSecondaryColor3us)("glSecondaryColor3us", lib);
        bindFunc(glSecondaryColor3usv)("glSecondaryColor3usv", lib);
        bindFunc(glSecondaryColorPointer)("glSecondaryColorPointer", lib);
        bindFunc(glWindowPos2d)("glWindowPos2d", lib);
        bindFunc(glWindowPos2dv)("glWindowPos2dv", lib);
        bindFunc(glWindowPos2f)("glWindowPos2f", lib);
        bindFunc(glWindowPos2fv)("glWindowPos2fv", lib);
        bindFunc(glWindowPos2i)("glWindowPos2i", lib);
        bindFunc(glWindowPos2iv)("glWindowPos2iv", lib);
        bindFunc(glWindowPos2s)("glWindowPos2s", lib);
        bindFunc(glWindowPos2sv)("glWindowPos2sv", lib);
        bindFunc(glWindowPos3d)("glWindowPos3d", lib);
        bindFunc(glWindowPos3dv)("glWindowPos3dv", lib);
        bindFunc(glWindowPos3f)("glWindowPos3f", lib);
        bindFunc(glWindowPos3fv)("glWindowPos3fv", lib);
        bindFunc(glWindowPos3i)("glWindowPos3i", lib);
        bindFunc(glWindowPos3iv)("glWindowPos3iv", lib);
        bindFunc(glWindowPos3s)("glWindowPos3s", lib);
        bindFunc(glWindowPos3sv)("glWindowPos3sv", lib);
        bindFunc(glBlendEquation)("glBlendEquation", lib);
        bindFunc(glBlendColor)("glBlendColor", lib);
    }
}

enum : GLenum
{
    GL_BLEND_DST_RGB                   = 0x80C8,
    GL_BLEND_SRC_RGB                   = 0x80C9,
    GL_BLEND_DST_ALPHA                 = 0x80CA,
    GL_BLEND_SRC_ALPHA                 = 0x80CB,
    GL_POINT_SIZE_MIN                  = 0x8126,
    GL_POINT_SIZE_MAX                  = 0x8127,
    GL_POINT_FADE_THRESHOLD_SIZE       = 0x8128,
    GL_POINT_DISTANCE_ATTENUATION      = 0x8129,
    GL_GENERATE_MIPMAP                 = 0x8191,
    GL_GENERATE_MIPMAP_HINT            = 0x8192,
    GL_DEPTH_COMPONENT16               = 0x81A5,
    GL_DEPTH_COMPONENT24               = 0x81A6,
    GL_DEPTH_COMPONENT32               = 0x81A7,
    GL_MIRRORED_REPEAT                 = 0x8370,
    GL_FOG_COORDINATE_SOURCE           = 0x8450,
    GL_FOG_COORDINATE                  = 0x8451,
    GL_FRAGMENT_DEPTH                  = 0x8452,
    GL_CURRENT_FOG_COORDINATE          = 0x8453,
    GL_FOG_COORDINATE_ARRAY_TYPE       = 0x8454,
    GL_FOG_COORDINATE_ARRAY_STRIDE     = 0x8455,
    GL_FOG_COORDINATE_ARRAY_POINTER    = 0x8456,
    GL_FOG_COORDINATE_ARRAY            = 0x8457,
    GL_COLOR_SUM                       = 0x8458,
    GL_CURRENT_SECONDARY_COLOR         = 0x8459,
    GL_SECONDARY_COLOR_ARRAY_SIZE      = 0x845A,
    GL_SECONDARY_COLOR_ARRAY_TYPE      = 0x845B,
    GL_SECONDARY_COLOR_ARRAY_STRIDE    = 0x845C,
    GL_SECONDARY_COLOR_ARRAY_POINTER   = 0x845D,
    GL_SECONDARY_COLOR_ARRAY           = 0x845E,
    GL_MAX_TEXTURE_LOD_BIAS            = 0x84FD,
    GL_TEXTURE_FILTER_CONTROL          = 0x8500,
    GL_TEXTURE_LOD_BIAS                = 0x8501,
    GL_INCR_WRAP                       = 0x8507,
    GL_DECR_WRAP                       = 0x8508,
    GL_TEXTURE_DEPTH_SIZE              = 0x884A,
    GL_DEPTH_TEXTURE_MODE              = 0x884B,
    GL_TEXTURE_COMPARE_MODE            = 0x884C,
    GL_TEXTURE_COMPARE_FUNC            = 0x884D,
    GL_COMPARE_R_TO_TEXTURE            = 0x884E,
    GL_CONSTANT_COLOR                  = 0x8001,
    GL_ONE_MINUS_CONSTANT_COLOR        = 0x8002,
    GL_CONSTANT_ALPHA                  = 0x8003,
    GL_ONE_MINUS_CONSTANT_ALPHA        = 0x8004,
    GL_BLEND_COLOR                     = 0x8005,
    GL_FUNC_ADD                        = 0x8006,
    GL_MIN                             = 0x8007,
    GL_MAX                             = 0x8008,
    GL_BLEND_EQUATION                  = 0x8009,
    GL_FUNC_SUBTRACT                   = 0x800A,
    GL_FUNC_REVERSE_SUBTRACT           = 0x800B,
}

extern(System)
{
    GLvoid function(GLenum, GLenum, GLenum, GLenum) glBlendFuncSeparate;
    GLvoid function(GLfloat) glFogCoordf;
    GLvoid function(GLfloat*) glFogCoordfv;
    GLvoid function(GLdouble) glFogCoordd;
    GLvoid function(GLdouble*) glFogCoorddv;
    GLvoid function(GLenum, GLsizei,GLvoid*) glFogCoordPointer;
    GLvoid function(GLenum, GLint*, GLsizei*, GLsizei) glMultiDrawArrays;
    GLvoid function(GLenum, GLsizei*, GLenum, GLvoid**, GLsizei) glMultiDrawElements;
    GLvoid function(GLenum, GLfloat) glPointParameterf;
    GLvoid function(GLenum, GLfloat*) glPointParameterfv;
    GLvoid function(GLenum, GLint) glPointParameteri;
    GLvoid function(GLenum, GLint*) glPointParameteriv;
    GLvoid function(GLbyte, GLbyte, GLbyte) glSecondaryColor3b;
    GLvoid function(GLbyte*) glSecondaryColor3bv;
    GLvoid function(GLdouble, GLdouble, GLdouble) glSecondaryColor3d;
    GLvoid function(GLdouble*) glSecondaryColor3dv;
    GLvoid function(GLfloat, GLfloat, GLfloat) glSecondaryColor3f;
    GLvoid function(GLfloat*) glSecondaryColor3fv;
    GLvoid function(GLint, GLint, GLint) glSecondaryColor3i;
    GLvoid function(GLint*) glSecondaryColor3iv;
    GLvoid function(GLshort, GLshort, GLshort) glSecondaryColor3s;
    GLvoid function(GLshort*) glSecondaryColor3sv;
    GLvoid function(GLubyte, GLubyte, GLubyte) glSecondaryColor3ub;
    GLvoid function(GLubyte*) glSecondaryColor3ubv;
    GLvoid function(GLuint, GLuint, GLuint) glSecondaryColor3ui;
    GLvoid function(GLuint*) glSecondaryColor3uiv;
    GLvoid function(GLushort, GLushort, GLushort) glSecondaryColor3us;
    GLvoid function(GLushort*) glSecondaryColor3usv;
    GLvoid function(GLint, GLenum, GLsizei, GLvoid*) glSecondaryColorPointer;
    GLvoid function(GLdouble, GLdouble) glWindowPos2d;
    GLvoid function(GLdouble*) glWindowPos2dv;
    GLvoid function(GLfloat, GLfloat) glWindowPos2f;
    GLvoid function(GLfloat*) glWindowPos2fv;
    GLvoid function(GLint, GLint) glWindowPos2i;
    GLvoid function(GLint*) glWindowPos2iv;
    GLvoid function(GLshort, GLshort) glWindowPos2s;
    GLvoid function(GLshort*) glWindowPos2sv;
    GLvoid function(GLdouble, GLdouble, GLdouble) glWindowPos3d;
    GLvoid function(GLdouble*) glWindowPos3dv;
    GLvoid function(GLfloat, GLfloat, GLfloat) glWindowPos3f;
    GLvoid function(GLfloat*) glWindowPos3fv;
    GLvoid function(GLint, GLint, GLint) glWindowPos3i;
    GLvoid function(GLint*) glWindowPos3iv;
    GLvoid function(GLshort, GLshort, GLshort) glWindowPos3s;
    GLvoid function(GLshort*) glWindowPos3sv;
    GLvoid function(GLclampf, GLclampf, GLclampf, GLclampf) glBlendColor;
    GLvoid function(GLenum) glBlendEquation;
}