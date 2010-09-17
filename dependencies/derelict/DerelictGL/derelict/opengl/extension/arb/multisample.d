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
module derelict.opengl.extension.arb.multisample;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ARBMultisample
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ARB_multisample") == -1)
            return false;
        if(!glBindExtFunc(cast(void**)&glSampleCoverageARB, "glSampleCoverageARB"))
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
        DerelictGL.registerExtensionLoader(&ARBMultisample.load);
    }
}

enum : GLenum
{
    GL_MULTISAMPLE_ARB                = 0x809D,
    GL_SAMPLE_ALPHA_TO_COVERAGE_ARB   = 0x809E,
    GL_SAMPLE_ALPHA_TO_ONE_ARB        = 0x809F,
    GL_SAMPLE_COVERAGE_ARB            = 0x80A0,
    GL_SAMPLE_BUFFERS_ARB             = 0x80A8,
    GL_SAMPLES_ARB                    = 0x80A9,
    GL_SAMPLE_COVERAGE_VALUE_ARB      = 0x80AA,
    GL_SAMPLE_COVERAGE_INVERT_ARB     = 0x80AB,
    GL_MULTISAMPLE_BIT_ARB            = 0x20000000,
}

extern(System)
{
    void function(GLclampf, GLboolean) glSampleCoverageARB;
}