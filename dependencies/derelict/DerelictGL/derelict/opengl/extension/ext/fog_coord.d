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
module derelict.opengl.extension.ext.fog_coord;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTFogCoord
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_fog_coord") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glFogCoordfEXT, "glFogCoordfEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoordfvEXT, "glFogCoordfvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoorddEXT, "glFogCoorddEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoorddvEXT, "glFogCoorddvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoordPointerEXT, "glFogCoordPointerEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTFogCoord.load);
    }
}

enum : GLenum
{
    GL_FOG_COORDINATE_SOURCE_EXT           = 0x8450,
    GL_FOG_COORDINATE_EXT                  = 0x8451,
    GL_FRAGMENT_DEPTH_EXT                  = 0x8452,
    GL_CURRENT_FOG_COORDINATE_EXT          = 0x8453,
    GL_FOG_COORDINATE_ARRAY_TYPE_EXT       = 0x8454,
    GL_FOG_COORDINATE_ARRAY_STRIDE_EXT     = 0x8455,
    GL_FOG_COORDINATE_ARRAY_POINTER_EXT    = 0x8456,
    GL_FOG_COORDINATE_ARRAY_EXT            = 0x8457,
}

extern(System)
{
    void function(GLfloat) glFogCoordfEXT;
    void function(GLfloat*) glFogCoordfvEXT;
    void function(GLdouble) glFogCoorddEXT;
    void function(GLdouble*) glFogCoorddvEXT;
    void function(GLenum, GLsizei, GLvoid*) glFogCoordPointerEXT;
}