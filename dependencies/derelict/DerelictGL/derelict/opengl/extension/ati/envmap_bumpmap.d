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
module derelict.opengl.extension.ati.envmap_bumpmap;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ATIEnvmapBumpmap
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ATI_envmap_bumpmap") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glTexBumpParameterivATI, "glTexBumpParameterivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glTexBumpParameterfvATI, "glTexBumpParameterfvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTexBumpParameterivATI, "glGetTexBumpParameterivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glGetTexBumpParameterfvATI, "glGetTexBumpParameterfvATI"))
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
        DerelictGL.registerExtensionLoader(&ATIEnvmapBumpmap.load);
    }
}

enum : GLenum
{
    GL_BUMP_ROT_MATRIX_ATI            = 0x8775,
    GL_BUMP_ROT_MATRIX_SIZE_ATI       = 0x8776,
    GL_BUMP_NUM_TEX_UNITS_ATI         = 0x8777,
    GL_BUMP_TEX_UNITS_ATI             = 0x8778,
    GL_DUDV_ATI                       = 0x8779,
    GL_DU8DV8_ATI                     = 0x877A,
    GL_BUMP_ENVMAP_ATI                = 0x877B,
    GL_BUMP_TARGET_ATI                = 0x877C,
}

extern(System)
{
void function(GLenum, GLint*) glTexBumpParameterivATI;
void function(GLenum, GLfloat*) glTexBumpParameterfvATI;
void function(GLenum, GLint*) glGetTexBumpParameterivATI;
void function(GLenum, GLfloat*) glGetTexBumpParameterfvATI;
}