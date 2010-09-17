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
module derelict.opengl.extension.ext.convolution;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTConvolution
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_convolution") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glConvolutionFilter1DEXT, "glConvolutionFilter1DEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glConvolutionFilter2DEXT, "glConvolutionFilter2DEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glConvolutionParameterfEXT, "glConvolutionParameterfEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glConvolutionParameterfvEXT, "glConvolutionParameterfvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glConvolutionParameteriEXT, "glConvolutionParameteriEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glConvolutionParameterivEXT, "glConvolutionParameterivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCopyConvolutionFilter1DEXT, "glCopyConvolutionFilter1DEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glCopyConvolutionFilter2DEXT, "glCopyConvolutionFilter2DEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetConvolutionFilterEXT, "glGetConvolutionFilterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetConvolutionParameterfvEXT, "glGetConvolutionParameterfvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetConvolutionParameterivEXT, "glGetConvolutionParameterivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetSeparableFilterEXT, "glGetSeparableFilterEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSeparableFilter2DEXT, "glSeparableFilter2DEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTConvolution.load);
    }
}

enum : GLenum
{
    GL_CONVOLUTION_1D_EXT                  = 0x8010,
    GL_CONVOLUTION_2D_EXT                  = 0x8011,
    GL_SEPARABLE_2D_EXT                    = 0x8012,
    GL_CONVOLUTION_BORDER_MODE_EXT         = 0x8013,
    GL_CONVOLUTION_FILTER_SCALE_EXT        = 0x8014,
    GL_CONVOLUTION_FILTER_BIAS_EXT         = 0x8015,
    GL_REDUCE_EXT                          = 0x8016,
    GL_CONVOLUTION_FORMAT_EXT              = 0x8017,
    GL_CONVOLUTION_WIDTH_EXT               = 0x8018,
    GL_CONVOLUTION_HEIGHT_EXT              = 0x8019,
    GL_MAX_CONVOLUTION_WIDTH_EXT           = 0x801A,
    GL_MAX_CONVOLUTION_HEIGHT_EXT          = 0x801B,
    GL_POST_CONVOLUTION_RED_SCALE_EXT      = 0x801C,
    GL_POST_CONVOLUTION_GREEN_SCALE_EXT    = 0x801D,
    GL_POST_CONVOLUTION_BLUE_SCALE_EXT     = 0x801E,
    GL_POST_CONVOLUTION_ALPHA_SCALE_EXT    = 0x801F,
    GL_POST_CONVOLUTION_RED_BIAS_EXT       = 0x8020,
    GL_POST_CONVOLUTION_GREEN_BIAS_EXT     = 0x8021,
    GL_POST_CONVOLUTION_BLUE_BIAS_EXT      = 0x8022,
    GL_POST_CONVOLUTION_ALPHA_BIAS_EXT     = 0x8023,
}

extern(System)
{
    void function(GLenum, GLenum, GLsizei, GLenum, GLenum, GLvoid*) glConvolutionFilter1DEXT;
    void function(GLenum, GLenum, GLsizei, GLsizei, GLenum, GLenum, GLvoid*) glConvolutionFilter2DEXT;
    void function(GLenum, GLenum, GLfloat) glConvolutionParameterfEXT;
    void function(GLenum, GLenum, GLfloat*) glConvolutionParameterfvEXT;
    void function(GLenum, GLenum, GLint) glConvolutionParameteriEXT;
    void function(GLenum, GLenum, GLint*) glConvolutionParameterivEXT;
    void function(GLenum, GLenum, GLint, GLint, GLsizei) glCopyConvolutionFilter1DEXT;
    void function(GLenum, GLenum, GLint, GLint, GLsizei, GLsizei) glCopyConvolutionFilter2DEXT;
    void function(GLenum, GLenum, GLenum, GLvoid*) glGetConvolutionFilterEXT;
    void function(GLenum, GLenum, GLfloat*) glGetConvolutionParameterfvEXT;
    void function(GLenum, GLenum, GLint*) glGetConvolutionParameterivEXT;
    void function(GLenum, GLenum, GLenum, GLvoid*, GLvoid*, GLvoid*) glGetSeparableFilterEXT;
    void function(GLenum, GLenum, GLsizei, GLsizei, GLenum, GLenum, GLvoid*, GLvoid*) glSeparableFilter2DEXT;
}