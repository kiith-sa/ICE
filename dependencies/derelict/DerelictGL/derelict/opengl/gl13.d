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
module derelict.opengl.gl13;

private
{
    import derelict.util.loader;
    import derelict.util.exception;
    import derelict.opengl.gltypes;
    version(Windows)
        import derelict.opengl.wgl;
}

package void loadGL13(SharedLib lib)
{
    version(Windows)
    {
        wglBindFunc(cast(void**)&glActiveTexture, "glActiveTexture", lib);
        wglBindFunc(cast(void**)&glClientActiveTexture, "glClientActiveTexture", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1d, "glMultiTexCoord1d", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1dv, "glMultiTexCoord1dv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1f, "glMultiTexCoord1f", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1fv, "glMultiTexCoord1fv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1i, "glMultiTexCoord1i", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1iv, "glMultiTexCoord1iv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1s, "glMultiTexCoord1s", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord1sv, "glMultiTexCoord1sv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2d, "glMultiTexCoord2d", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2dv, "glMultiTexCoord2dv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2f, "glMultiTexCoord2f", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2fv, "glMultiTexCoord2fv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2i, "glMultiTexCoord2i", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2iv, "glMultiTexCoord2iv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2s, "glMultiTexCoord2s", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord2sv, "glMultiTexCoord2sv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3d, "glMultiTexCoord3d", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3dv, "glMultiTexCoord3d", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3f, "glMultiTexCoord3f", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3fv, "glMultiTexCoord3fv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3i, "glMultiTexCoord3i", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3iv, "glMultiTexCoord3iv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3s, "glMultiTexCoord3s", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord3sv, "glMultiTexCoord3sv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4d, "glMultiTexCoord4d", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4dv, "glMultiTexCoord4dv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4f, "glMultiTexCoord4f", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4fv, "glMultiTexCoord4fv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4i, "glMultiTexCoord4i", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4iv, "glMultiTexCoord4iv", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4s, "glMultiTexCoord4s", lib);
        wglBindFunc(cast(void**)&glMultiTexCoord4sv, "glMultiTexCoord4sv", lib);
        wglBindFunc(cast(void**)&glLoadTransposeMatrixd, "glLoadTransposeMatrixd", lib);
        wglBindFunc(cast(void**)&glLoadTransposeMatrixf, "glLoadTransposeMatrixf", lib);
        wglBindFunc(cast(void**)&glMultTransposeMatrixd, "glMultTransposeMatrixd", lib);
        wglBindFunc(cast(void**)&glMultTransposeMatrixf, "glMultTransposeMatrixf", lib);
        wglBindFunc(cast(void**)&glSampleCoverage, "glSampleCoverage", lib);
        wglBindFunc(cast(void**)&glCompressedTexImage1D, "glCompressedTexImage1D", lib);
        wglBindFunc(cast(void**)&glCompressedTexImage2D, "glCompressedTexImage2D", lib);
        wglBindFunc(cast(void**)&glCompressedTexImage3D, "glCompressedTexImage3D", lib);
        wglBindFunc(cast(void**)&glCompressedTexSubImage1D, "glCompressedTexSubImage1D", lib);
        wglBindFunc(cast(void**)&glCompressedTexSubImage2D, "glCompressedTexSubImage2D", lib);
        wglBindFunc(cast(void**)&glCompressedTexSubImage3D, "glCompressedTexSubImage3D", lib);
        wglBindFunc(cast(void**)&glGetCompressedTexImage, "glGetCompressedTexImage", lib);
    }
    else
    {
        bindFunc(glActiveTexture)("glActiveTexture", lib);
        bindFunc(glClientActiveTexture)("glClientActiveTexture", lib);
        bindFunc(glMultiTexCoord1d)("glMultiTexCoord1d", lib);
        bindFunc(glMultiTexCoord1dv)("glMultiTexCoord1dv", lib);
        bindFunc(glMultiTexCoord1f)("glMultiTexCoord1f", lib);
        bindFunc(glMultiTexCoord1fv)("glMultiTexCoord1fv", lib);
        bindFunc(glMultiTexCoord1i)("glMultiTexCoord1i", lib);
        bindFunc(glMultiTexCoord1iv)("glMultiTexCoord1iv", lib);
        bindFunc(glMultiTexCoord1s)("glMultiTexCoord1s", lib);
        bindFunc(glMultiTexCoord1sv)("glMultiTexCoord1sv", lib);
        bindFunc(glMultiTexCoord2d)("glMultiTexCoord2d", lib);
        bindFunc(glMultiTexCoord2dv)("glMultiTexCoord2dv", lib);
        bindFunc(glMultiTexCoord2f)("glMultiTexCoord2f", lib);
        bindFunc(glMultiTexCoord2fv)("glMultiTexCoord2fv", lib);
        bindFunc(glMultiTexCoord2i)("glMultiTexCoord2i", lib);
        bindFunc(glMultiTexCoord2iv)("glMultiTexCoord2iv", lib);
        bindFunc(glMultiTexCoord2s)("glMultiTexCoord2s", lib);
        bindFunc(glMultiTexCoord2sv)("glMultiTexCoord2s", lib);
        bindFunc(glMultiTexCoord3d)("glMultiTexCoord3d", lib);
        bindFunc(glMultiTexCoord3dv)("glMultiTexCoord3d", lib);
        bindFunc(glMultiTexCoord3f)("glMultiTexCoord3f", lib);
        bindFunc(glMultiTexCoord3fv)("glMultiTexCoord3fv", lib);
        bindFunc(glMultiTexCoord3i)("glMultiTexCoord3i", lib);
        bindFunc(glMultiTexCoord3iv)("glMultiTexCoord3iv", lib);
        bindFunc(glMultiTexCoord3s)("glMultiTexCoord3s", lib);
        bindFunc(glMultiTexCoord3sv)("glMultiTexCoord3sv", lib);
        bindFunc(glMultiTexCoord4d)("glMultiTexCoord4d", lib);
        bindFunc(glMultiTexCoord4dv)("glMultiTexCoord4dv", lib);
        bindFunc(glMultiTexCoord4f)("glMultiTexCoord4f", lib);
        bindFunc(glMultiTexCoord4fv)("glMultiTexCoord4fv", lib);
        bindFunc(glMultiTexCoord4i)("glMultiTexCoord4i", lib);
        bindFunc(glMultiTexCoord4iv)("glMultiTexCoord4iv", lib);
        bindFunc(glMultiTexCoord4s)("glMultiTexCoord4s", lib);
        bindFunc(glMultiTexCoord4sv)("glMultiTexCoord4sv", lib);
        bindFunc(glLoadTransposeMatrixd)("glLoadTransposeMatrixd", lib);
        bindFunc(glLoadTransposeMatrixf)("glLoadTransposeMatrixf", lib);
        bindFunc(glMultTransposeMatrixd)("glMultTransposeMatrixd", lib);
        bindFunc(glMultTransposeMatrixf)("glMultTransposeMatrixf", lib);
        bindFunc(glSampleCoverage)("glSampleCoverage", lib);
        bindFunc(glCompressedTexImage1D)("glCompressedTexImage1D", lib);
        bindFunc(glCompressedTexImage2D)("glCompressedTexImage2D", lib);
        bindFunc(glCompressedTexImage3D)("glCompressedTexImage3D", lib);
        bindFunc(glCompressedTexSubImage1D)("glCompressedTexSubImage1D", lib);
        bindFunc(glCompressedTexSubImage2D)("glCompressedTexSubImage2D", lib);
        bindFunc(glCompressedTexSubImage3D)("glCompressedTexSubImage3D", lib);
        bindFunc(glGetCompressedTexImage)("glGetCompressedTexImage", lib);
    }
}

enum : GLenum
{
    GL_TEXTURE0                    = 0x84C0,
    GL_TEXTURE1                    = 0x84C1,
    GL_TEXTURE2                    = 0x84C2,
    GL_TEXTURE3                    = 0x84C3,
    GL_TEXTURE4                    = 0x84C4,
    GL_TEXTURE5                    = 0x84C5,
    GL_TEXTURE6                    = 0x84C6,
    GL_TEXTURE7                    = 0x84C7,
    GL_TEXTURE8                    = 0x84C8,
    GL_TEXTURE9                    = 0x84C9,
    GL_TEXTURE10                   = 0x84CA,
    GL_TEXTURE11                   = 0x84CB,
    GL_TEXTURE12                   = 0x84CC,
    GL_TEXTURE13                   = 0x84CD,
    GL_TEXTURE14                   = 0x84CE,
    GL_TEXTURE15                   = 0x84CF,
    GL_TEXTURE16                   = 0x84D0,
    GL_TEXTURE17                   = 0x84D1,
    GL_TEXTURE18                   = 0x84D2,
    GL_TEXTURE19                   = 0x84D3,
    GL_TEXTURE20                   = 0x84D4,
    GL_TEXTURE21                   = 0x84D5,
    GL_TEXTURE22                   = 0x84D6,
    GL_TEXTURE23                   = 0x84D7,
    GL_TEXTURE24                   = 0x84D8,
    GL_TEXTURE25                   = 0x84D9,
    GL_TEXTURE26                   = 0x84DA,
    GL_TEXTURE27                   = 0x84DB,
    GL_TEXTURE28                   = 0x84DC,
    GL_TEXTURE29                   = 0x84DD,
    GL_TEXTURE30                   = 0x84DE,
    GL_TEXTURE31                   = 0x84DF,
    GL_ACTIVE_TEXTURE              = 0x84E0,
    GL_CLIENT_ACTIVE_TEXTURE       = 0x84E1,
    GL_MAX_TEXTURE_UNITS           = 0x84E2,
    GL_NORMAL_MAP                  = 0x8511,
    GL_REFLECTION_MAP              = 0x8512,
    GL_TEXTURE_CUBE_MAP            = 0x8513,
    GL_TEXTURE_BINDING_CUBE_MAP    = 0x8514,
    GL_TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A,
    GL_PROXY_TEXTURE_CUBE_MAP      = 0x851B,
    GL_MAX_CUBE_MAP_TEXTURE_SIZE   = 0x851C,
    GL_COMPRESSED_ALPHA            = 0x84E9,
    GL_COMPRESSED_LUMINANCE        = 0x84EA,
    GL_COMPRESSED_LUMINANCE_ALPHA  = 0x84EB,
    GL_COMPRESSED_INTENSITY        = 0x84EC,
    GL_COMPRESSED_RGB              = 0x84ED,
    GL_COMPRESSED_RGBA             = 0x84EE,
    GL_TEXTURE_COMPRESSION_HINT    = 0x84EF,
    GL_TEXTURE_COMPRESSED_IMAGE_SIZE   = 0x86A0,
    GL_TEXTURE_COMPRESSED      = 0x86A1,
    GL_NUM_COMPRESSED_TEXTURE_FORMATS  = 0x86A2,
    GL_COMPRESSED_TEXTURE_FORMATS  = 0x86A3,
    GL_MULTISAMPLE                 = 0x809D,
    GL_SAMPLE_ALPHA_TO_COVERAGE    = 0x809E,
    GL_SAMPLE_ALPHA_TO_ONE         = 0x809F,
    GL_SAMPLE_COVERAGE             = 0x80A0,
    GL_SAMPLE_BUFFERS              = 0x80A8,
    GL_SAMPLES                     = 0x80A9,
    GL_SAMPLE_COVERAGE_VALUE       = 0x80AA,
    GL_SAMPLE_COVERAGE_INVERT      = 0x80AB,
    GL_MULTISAMPLE_BIT             = 0x20000000,
    GL_TRANSPOSE_MODELVIEW_MATRIX  = 0x84E3,
    GL_TRANSPOSE_PROJECTION_MATRIX = 0x84E4,
    GL_TRANSPOSE_TEXTURE_MATRIX    = 0x84E5,
    GL_TRANSPOSE_COLOR_MATRIX      = 0x84E6,
    GL_COMBINE                     = 0x8570,
    GL_COMBINE_RGB                 = 0x8571,
    GL_COMBINE_ALPHA               = 0x8572,
    GL_SOURCE0_RGB                 = 0x8580,
    GL_SOURCE1_RGB                 = 0x8581,
    GL_SOURCE2_RGB                 = 0x8582,
    GL_SOURCE0_ALPHA               = 0x8588,
    GL_SOURCE1_ALPHA               = 0x8589,
    GL_SOURCE2_ALPHA               = 0x858A,
    GL_OPERAND0_RGB                = 0x8590,
    GL_OPERAND1_RGB                = 0x8591,
    GL_OPERAND2_RGB                = 0x8592,
    GL_OPERAND0_ALPHA              = 0x8598,
    GL_OPERAND1_ALPHA              = 0x8599,
    GL_OPERAND2_ALPHA              = 0x859A,
    GL_RGB_SCALE                   = 0x8573,
    GL_ADD_SIGNED                  = 0x8574,
    GL_INTERPOLATE                 = 0x8575,
    GL_SUBTRACT                    = 0x84E7,
    GL_CONSTANT                    = 0x8576,
    GL_PRIMARY_COLOR               = 0x8577,
    GL_PREVIOUS                    = 0x8578,
    GL_DOT3_RGB                    = 0x86AE,
    GL_DOT3_RGBA                   = 0x86AF,
    GL_CLAMP_TO_BORDER             = 0x812D,
}

extern(System)
{
    GLvoid function(GLenum) glActiveTexture;
    GLvoid function(GLenum) glClientActiveTexture;
    GLvoid function(GLenum, GLdouble) glMultiTexCoord1d;
    GLvoid function(GLenum, GLdouble*) glMultiTexCoord1dv;
    GLvoid function(GLenum, GLfloat) glMultiTexCoord1f;
    GLvoid function(GLenum, GLfloat*) glMultiTexCoord1fv;
    GLvoid function(GLenum, GLint) glMultiTexCoord1i;
    GLvoid function(GLenum, GLint*) glMultiTexCoord1iv;
    GLvoid function(GLenum, GLshort) glMultiTexCoord1s;
    GLvoid function(GLenum, GLshort*) glMultiTexCoord1sv;
    GLvoid function(GLenum, GLdouble, GLdouble) glMultiTexCoord2d;
    GLvoid function(GLenum, GLdouble*) glMultiTexCoord2dv;
    GLvoid function(GLenum, GLfloat, GLfloat) glMultiTexCoord2f;
    GLvoid function(GLenum, GLfloat*) glMultiTexCoord2fv;
    GLvoid function(GLenum, GLint, GLint) glMultiTexCoord2i;
    GLvoid function(GLenum, GLint*) glMultiTexCoord2iv;
    GLvoid function(GLenum, GLshort, GLshort) glMultiTexCoord2s;
    GLvoid function(GLenum, GLshort*) glMultiTexCoord2sv;
    GLvoid function(GLenum, GLdouble, GLdouble, GLdouble) glMultiTexCoord3d;
    GLvoid function(GLenum, GLdouble*) glMultiTexCoord3dv;
    GLvoid function(GLenum, GLfloat, GLfloat, GLfloat) glMultiTexCoord3f;
    GLvoid function(GLenum, GLfloat*) glMultiTexCoord3fv;
    GLvoid function(GLenum, GLint, GLint, GLint) glMultiTexCoord3i;
    GLvoid function(GLenum, GLint*) glMultiTexCoord3iv;
    GLvoid function(GLenum, GLshort, GLshort, GLshort) glMultiTexCoord3s;
    GLvoid function(GLenum, GLshort*) glMultiTexCoord3sv;
    GLvoid function(GLenum, GLdouble, GLdouble, GLdouble, GLdouble) glMultiTexCoord4d;
    GLvoid function(GLenum, GLdouble*) glMultiTexCoord4dv;
    GLvoid function(GLenum, GLfloat, GLfloat, GLfloat, GLfloat) glMultiTexCoord4f;
    GLvoid function(GLenum, GLfloat*) glMultiTexCoord4fv;
    GLvoid function(GLenum, GLint, GLint, GLint, GLint) glMultiTexCoord4i;
    GLvoid function(GLenum, GLint*) glMultiTexCoord4iv;
    GLvoid function(GLenum, GLshort, GLshort, GLshort, GLshort) glMultiTexCoord4s;
    GLvoid function(GLenum, GLshort*) glMultiTexCoord4sv;
    GLvoid function(GLdouble*) glLoadTransposeMatrixd;
    GLvoid function(GLfloat*) glLoadTransposeMatrixf;
    GLvoid function(GLdouble*) glMultTransposeMatrixd;
    GLvoid function(GLfloat*) glMultTransposeMatrixf;
    GLvoid function(GLclampf, GLboolean) glSampleCoverage;
    GLvoid function(GLenum, GLint, GLenum, GLsizei, GLint, GLsizei, GLvoid*) glCompressedTexImage1D;
    GLvoid function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLint, GLsizei, GLvoid*) glCompressedTexImage2D;
    GLvoid function(GLenum, GLint, GLenum, GLsizei, GLsizei, GLsizei depth, GLint, GLsizei, GLvoid*) glCompressedTexImage3D;
    GLvoid function(GLenum, GLint, GLint, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage1D;
    GLvoid function(GLenum, GLint, GLint, GLint, GLsizei, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage2D;
    GLvoid function(GLenum, GLint, GLint, GLint, GLint, GLsizei, GLsizei, GLsizei, GLenum, GLsizei, GLvoid*) glCompressedTexSubImage3D;
    GLvoid function(GLenum, GLint, GLvoid*) glGetCompressedTexImage;
}