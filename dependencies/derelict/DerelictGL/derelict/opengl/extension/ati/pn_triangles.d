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
module derelict.opengl.extension.ati.pn_triangles;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ATIPnTriangles
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ATI_pn_triangles") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glPNTrianglesiATI, "glPNTrianglesiATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glPNTrianglesfATI, "glPNTrianglesfATI"))
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
        DerelictGL.registerExtensionLoader(&ATIPnTriangles.load);
    }
}

enum : GLenum
{
    GL_PN_TRIANGLES_ATI                         = 0x87F0,
    GL_MAX_PN_TRIANGLES_TESSELATION_LEVEL_ATI   = 0x87F1,
    GL_PN_TRIANGLES_POINT_MODE_ATI              = 0x87F2,
    GL_PN_TRIANGLES_NORMAL_MODE_ATI             = 0x87F3,
    GL_PN_TRIANGLES_TESSELATION_LEVEL_ATI       = 0x87F4,
    GL_PN_TRIANGLES_POINT_MODE_LINEAR_ATI       = 0x87F5,
    GL_PN_TRIANGLES_POINT_MODE_CUBIC_ATI        = 0x87F6,
    GL_PN_TRIANGLES_NORMAL_MODE_LINEAR_ATI      = 0x87F7,
    GL_PN_TRIANGLES_NORMAL_MODE_QUADRATIC_ATI   = 0x87F8,
}

extern(System)
{
    void function(GLenum, GLint) glPNTrianglesiATI;
    void function(GLenum, GLfloat) glPNTrianglesfATI;
}