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
module derelict.opengl.extension.nv.depth_buffer_float;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct NVDepthBufferFloat
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_NV_depth_buffer_float") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glDepthRangedNV, "glDepthRangedNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glClearDepthdNV, "glClearDepthdNV"))
            return false;
        if(!glBindExtFunc(cast(void**)&glDepthBoundsdNV, "glDepthBoundsdNV"))
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
        DerelictGL.registerExtensionLoader(&NVDepthBufferFloat.load);
    }
}

enum : GLenum
{
    GL_DEPTH_COMPONENT32F_NV               = 0x8DAB,
    GL_DEPTH32F_STENCIL8_NV                = 0x8DAC,
    GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV   = 0x8DAD,
    GL_DEPTH_BUFFER_FLOAT_MODE_NV          = 0x8DAF,
}

extern(System)
{
    void function(GLdouble, GLdouble) glDepthRangedNV;
    void function(GLdouble) glClearDepthdNV;
    void function(GLdouble, GLdouble) glDepthBoundsdNV;
}