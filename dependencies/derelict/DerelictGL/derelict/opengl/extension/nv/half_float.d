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
module derelict.opengl.extension.nv.half_float;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVHalfFloat
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_half_float") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glVertex2hNV, "glVertex2hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertex2hvNV, "glVertex2hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertex3hNV, "glVertex3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertex3hvNV, "glVertex3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertex4hNV, "glVertex4hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertex4hvNV, "glVertex4hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormal3hNV, "glNormal3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormal3hvNV, "glNormal3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glColor3hNV, "glColor3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glColor3hvNV, "glColor3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glColor4hNV, "glColor4hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glColor4hvNV, "glColor4hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord1hNV, "glTexCoord1hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord1hvNV, "glTexCoord1hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord2hNV, "glTexCoord2hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord2hvNV, "glTexCoord2hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord3hNV, "glTexCoord3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord3hvNV, "glTexCoord3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord4hNV, "glTexCoord4hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexCoord4hvNV, "glTexCoord4hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord1hNV, "glMultiTexCoord1hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord1hNV, "glMultiTexCoord1hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord1hvNV, "glMultiTexCoord1hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord2hNV, "glMultiTexCoord2hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord2hvNV, "glMultiTexCoord2hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord3hNV, "glMultiTexCoord3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord3hvNV, "glMultiTexCoord3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord4hNV, "glMultiTexCoord4hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glMultiTexCoord4hvNV, "glMultiTexCoord4hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoordhNV, "glFogCoordhNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glFogCoordhvNV, "glFogCoordhvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3hNV, "glSecondaryColor3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glSecondaryColor3hvNV, "glSecondaryColor3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexWeighthNV, "glVertexWeighthNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexWeighthvNV, "glVertexWeighthvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1hNV, "glVertexAttrib1hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib1hvNV, "glVertexAttrib1hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2hNV, "glVertexAttrib2hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib2hvNV, "glVertexAttrib2hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3hNV, "glVertexAttrib3hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib3hvNV, "glVertexAttrib3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4hNV, "glVertexAttrib4hNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttrib4hvNV, "glVertexAttrib4hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs1hvNV, "glVertexAttribs1hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs2hvNV, "glVertexAttribs2hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs3hvNV, "glVertexAttribs3hvNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexAttribs4hvNV, "glVertexAttribs4hvNV"))
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
        DerelictGL.registerExtensionLoader(&NVHalfFloat.load);
    }
}

alias ushort GLhalfNV;

enum : GLenum
{
    GL_HALF_FLOAT_NV = 0x140B
}

extern(System)
{
    void function(GLhalfNV, GLhalfNV) glVertex2hNV;
    void function(GLhalfNV*) glVertex2hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV) glVertex3hNV;
    void function(GLhalfNV*) glVertex3hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV, GLhalfNV) glVertex4hNV;
    void function(GLhalfNV*) glVertex4hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV) glNormal3hNV;
    void function(GLhalfNV*) glNormal3hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV) glColor3hNV;
    void function(GLhalfNV*) glColor3hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV, GLhalfNV) glColor4hNV;
    void function(GLhalfNV*) glColor4hvNV;
    void function(GLhalfNV) glTexCoord1hNV;
    void function(GLhalfNV*) glTexCoord1hvNV;
    void function(GLhalfNV, GLhalfNV) glTexCoord2hNV;
    void function(GLhalfNV*) glTexCoord2hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV) glTexCoord3hNV;
    void function(GLhalfNV*) glTexCoord3hvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV, GLhalfNV) glTexCoord4hNV;
    void function(GLhalfNV*) glTexCoord4hvNV;
    void function(GLenum, GLhalfNV) glMultiTexCoord1hNV;
    void function(GLenum, GLhalfNV*) glMultiTexCoord1hvNV;
    void function(GLenum, GLhalfNV, GLhalfNV) glMultiTexCoord2hNV;
    void function(GLenum, GLhalfNV*) glMultiTexCoord2hvNV;
    void function(GLenum, GLhalfNV, GLhalfNV, GLhalfNV) glMultiTexCoord3hNV;
    void function(GLenum, GLhalfNV*) glMultiTexCoord3hvNV;
    void function(GLenum, GLhalfNV, GLhalfNV, GLhalfNV, GLhalfNV) glMultiTexCoord4hNV;
    void function(GLenum, GLhalfNV*) glMultiTexCoord4hvNV;
    void function(GLhalfNV) glFogCoordhNV;
    void function(GLhalfNV*) glFogCoordhvNV;
    void function(GLhalfNV, GLhalfNV, GLhalfNV) glSecondaryColor3hNV;
    void function(GLhalfNV*) glSecondaryColor3hvNV;
    void function(GLhalfNV) glVertexWeighthNV;
    void function(GLhalfNV*) glVertexWeighthvNV;
    void function(GLuint, GLhalfNV) glVertexAttrib1hNV;
    void function(GLuint, GLhalfNV*) glVertexAttrib1hvNV;
    void function(GLuint, GLhalfNV, GLhalfNV) glVertexAttrib2hNV;
    void function(GLuint, GLhalfNV*) glVertexAttrib2hvNV;
    void function(GLuint, GLhalfNV, GLhalfNV, GLhalfNV) glVertexAttrib3hNV;
    void function(GLuint, GLhalfNV*) glVertexAttrib3hvNV;
    void function(GLuint, GLhalfNV, GLhalfNV, GLhalfNV, GLhalfNV) glVertexAttrib4hNV;
    void function(GLuint, GLhalfNV*) glVertexAttrib4hvNV;
    void function(GLuint, GLsizei, GLhalfNV*) glVertexAttribs1hvNV;
    void function(GLuint, GLsizei, GLhalfNV*) glVertexAttribs2hvNV;
    void function(GLuint, GLsizei, GLhalfNV*) glVertexAttribs3hvNV;
    void function(GLuint, GLsizei, GLhalfNV*) glVertexAttribs4hvNV;
}