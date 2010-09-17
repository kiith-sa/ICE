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
module derelict.opengl.extension.arb.fragment_program;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBFragmentProgram
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_fragment_program") != -1)
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
        DerelictGL.registerExtensionLoader(&ARBFragmentProgram.load);
    }
}

enum : GLenum
{
    GL_FRAGMENT_PROGRAM_ARB                        = 0x8804,
    GL_PROGRAM_ALU_INSTRUCTIONS_ARB                = 0x8805,
    GL_PROGRAM_TEX_INSTRUCTIONS_ARB                = 0x8806,
    GL_PROGRAM_TEX_INDIRECTIONS_ARB                = 0x8807,
    GL_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB         = 0x8808,
    GL_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB         = 0x8809,
    GL_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB         = 0x880A,
    GL_MAX_PROGRAM_ALU_INSTRUCTIONS_ARB            = 0x880B,
    GL_MAX_PROGRAM_TEX_INSTRUCTIONS_ARB            = 0x880C,
    GL_MAX_PROGRAM_TEX_INDIRECTIONS_ARB            = 0x880D,
    GL_MAX_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB     = 0x880E,
    GL_MAX_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB     = 0x880F,
    GL_MAX_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB     = 0x8810,
    GL_MAX_TEXTURE_COORDS_ARB                      = 0x8871,
    GL_MAX_TEXTURE_IMAGE_UNITS_ARB                 = 0x8872,
}
