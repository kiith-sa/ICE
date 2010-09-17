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
module derelict.opengl.extension.ext.secondary_color;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct EXTSecondaryColor
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_EXT_secondary_color") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glSecondaryColor3bEXT, "glSecondaryColor3bEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3bvEXT, "glSecondaryColor3bvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3dEXT, "glSecondaryColor3dEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3dvEXT, "glSecondaryColor3dvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3fEXT, "glSecondaryColor3fEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3fvEXT, "glSecondaryColor3fvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3iEXT, "glSecondaryColor3iEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3ivEXT, "glSecondaryColor3ivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3sEXT, "glSecondaryColor3sEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3svEXT, "glSecondaryColor3svEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3ubEXT, "glSecondaryColor3ubEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3ubvEXT, "glSecondaryColor3ubvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3uiEXT, "glSecondaryColor3uiEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3uivEXT, "glSecondaryColor3uivEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3usEXT, "glSecondaryColor3usEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3usvEXT, "glSecondaryColor3usvEXT"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColorPointerEXT, "glSecondaryColorPointerEXT"))
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
        DerelictGL.registerExtensionLoader(&EXTSecondaryColor.load);
    }
}

enum : GLenum
{
    GL_COLOR_SUM_EXT                       = 0x8458,
    GL_CURRENT_SECONDARY_COLOR_EXT         = 0x8459,
    GL_SECONDARY_COLOR_ARRAY_SIZE_EXT      = 0x845A,
    GL_SECONDARY_COLOR_ARRAY_TYPE_EXT      = 0x845B,
    GL_SECONDARY_COLOR_ARRAY_STRIDE_EXT    = 0x845C,
    GL_SECONDARY_COLOR_ARRAY_POINTER_EXT   = 0x845D,
    GL_SECONDARY_COLOR_ARRAY_EXT           = 0x845E,
}

extern(System)
{
    void function(GLbyte, GLbyte, GLbyte) glSecondaryColor3bEXT;
    void function(GLbyte*) glSecondaryColor3bvEXT;
    void function(GLdouble, GLdouble, GLdouble) glSecondaryColor3dEXT;
    void function(GLdouble*) glSecondaryColor3dvEXT;
    void function(GLfloat, GLfloat, GLfloat) glSecondaryColor3fEXT;
    void function(GLfloat*) glSecondaryColor3fvEXT;
    void function(GLint, GLint, GLint) glSecondaryColor3iEXT;
    void function(GLint*) glSecondaryColor3ivEXT;
    void function(GLshort, GLshort, GLshort) glSecondaryColor3sEXT;
    void function(GLshort*) glSecondaryColor3svEXT;
    void function(GLubyte, GLubyte, GLubyte) glSecondaryColor3ubEXT;
    void function(GLubyte*) glSecondaryColor3ubvEXT;
    void function(GLuint, GLuint, GLuint) glSecondaryColor3uiEXT;
    void function(GLuint*) glSecondaryColor3uivEXT;
    void function(GLushort, GLushort, GLushort) glSecondaryColor3usEXT;
    void function(GLushort*) glSecondaryColor3usvEXT;
    void function(GLint, GLenum, GLsizei, GLvoid*) glSecondaryColorPointerEXT;
}