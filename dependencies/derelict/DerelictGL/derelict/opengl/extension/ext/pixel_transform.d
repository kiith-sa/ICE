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
module derelict.opengl.extension.ext.pixel_transform;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTPixelTransform
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_pixel_transform") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glPixelTransformParameteriEXT, "glPixelTransformParameteriEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glPixelTransformParameterfEXT, "glPixelTransformParameterfEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glPixelTransformParameterivEXT, "glPixelTransformParameterivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glPixelTransformParameterfvEXT, "glPixelTransformParameterfvEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTPixelTransform.load);
    }
}

enum : GLenum
{
    GL_PIXEL_TRANSFORM_2D_EXT                  = 0x8330,
    GL_PIXEL_MAG_FILTER_EXT                    = 0x8331,
    GL_PIXEL_MIN_FILTER_EXT                    = 0x8332,
    GL_PIXEL_CUBIC_WEIGHT_EXT                  = 0x8333,
    GL_CUBIC_EXT                               = 0x8334,
    GL_AVERAGE_EXT                             = 0x8335,
    GL_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT      = 0x8336,
    GL_MAX_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT  = 0x8337,
    GL_PIXEL_TRANSFORM_2D_MATRIX_EXT           = 0x8338,
}

extern(System)
{
    void function(GLenum, GLenum, GLint) glPixelTransformParameteriEXT;
    void function(GLenum, GLenum, GLfloat) glPixelTransformParameterfEXT;
    void function(GLenum, GLenum, GLint*) glPixelTransformParameterivEXT;
    void function(GLenum, GLenum, GLfloat*) glPixelTransformParameterfvEXT;
}