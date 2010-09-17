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
module derelict.opengl.extension.arb.texture_cube_map;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBTextureCubeMap
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_texture_cube_map") != -1)
        {
            enabled = true;
            return true;
        }
        return false;
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
        DerelictGL.registerExtensionLoader(&ARBTextureCubeMap.load);
    }
}

enum : GLenum
{
    GL_NORMAL_MAP_ARB                  = 0x8511,
    GL_REFLECTION_MAP_ARB              = 0x8512,
    GL_TEXTURE_CUBE_MAP_ARB            = 0x8513,
    GL_TEXTURE_BINDING_CUBE_MAP_ARB    = 0x8514,
    GL_TEXTURE_CUBE_MAP_POSITIVE_X_ARB = 0x8515,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_X_ARB = 0x8516,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Y_ARB = 0x8517,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB = 0x8518,
    GL_TEXTURE_CUBE_MAP_POSITIVE_Z_ARB = 0x8519,
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB = 0x851A,
    GL_PROXY_TEXTURE_CUBE_MAP_ARB      = 0x851B,
    GL_MAX_CUBE_MAP_TEXTURE_SIZE_ARB   = 0x851C,
}
