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
module derelict.opengl.extension.ati.vertex_streams;

private
{
    import derelict.opengl.gltypes;
    import derelict.opengl.gl;
    import derelict.opengl.extension.loader;
    import derelict.util.wrapper;
}

private bool enabled = false;

struct ATIVertexStreams
{
    static bool load(char[] extString)
    {
        if(extString.findStr("GL_ATI_vertex_streams") == -1)
            return false;

        if(!glBindExtFunc(cast(void**)&glVertexStream1sATI, "glVertexStream1sATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1svATI, "glVertexStream1svATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1iATI, "glVertexStream1iATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1ivATI, "glVertexStream1ivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1fATI, "glVertexStream1fATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1fvATI, "glVertexStream1fvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1dATI, "glVertexStream1dATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream1dvATI, "glVertexStream1dvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2sATI, "glVertexStream2sATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2svATI, "glVertexStream2svATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2iATI, "glVertexStream2iATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2ivATI, "glVertexStream2ivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2fATI, "glVertexStream2fATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2fvATI, "glVertexStream2fvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2dATI, "glVertexStream2dATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream2dvATI, "glVertexStream2dvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3sATI, "glVertexStream3sATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3svATI, "glVertexStream3svATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3iATI, "glVertexStream3iATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3ivATI, "glVertexStream3ivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3fATI, "glVertexStream3fATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3fvATI, "glVertexStream3fvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3dATI, "glVertexStream3dATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream3dvATI, "glVertexStream3dvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4sATI, "glVertexStream4sATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4svATI, "glVertexStream4svATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4iATI, "glVertexStream4iATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4ivATI, "glVertexStream4ivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4fATI, "glVertexStream4fATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4fvATI, "glVertexStream4fvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4dATI, "glVertexStream4dATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexStream4dvATI, "glVertexStream4dvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3bATI, "glNormalStream3bATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3bvATI, "glNormalStream3bvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3sATI, "glNormalStream3sATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3svATI, "glNormalStream3svATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3iATI, "glNormalStream3iATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3ivATI, "glNormalStream3ivATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3fATI, "glNormalStream3fATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3fvATI, "glNormalStream3fvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3dATI, "glNormalStream3dATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glNormalStream3dvATI, "glNormalStream3dvATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glClientActiveVertexStreamATI, "glClientActiveVertexStreamATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexBlendEnviATI, "glVertexBlendEnviATI"))
            return false;
        if(!glBindExtFunc(cast(void**)&glVertexBlendEnvfATI, "glVertexBlendEnvfATI"))
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
        DerelictGL.registerExtensionLoader(&ATIVertexStreams.load);
    }
}

enum : GLenum
{
    GL_MAX_VERTEX_STREAMS_ATI         = 0x876B,
    GL_VERTEX_STREAM0_ATI             = 0x876C,
    GL_VERTEX_STREAM1_ATI             = 0x876D,
    GL_VERTEX_STREAM2_ATI             = 0x876E,
    GL_VERTEX_STREAM3_ATI             = 0x876F,
    GL_VERTEX_STREAM4_ATI             = 0x8770,
    GL_VERTEX_STREAM5_ATI             = 0x8771,
    GL_VERTEX_STREAM6_ATI             = 0x8772,
    GL_VERTEX_STREAM7_ATI             = 0x8773,
    GL_VERTEX_SOURCE_ATI              = 0x8774,
}

extern(System)
{
    void function(GLenum, GLshort) glVertexStream1sATI;
    void function(GLenum, GLshort*) glVertexStream1svATI;
    void function(GLenum, GLint) glVertexStream1iATI;
    void function(GLenum, GLint*) glVertexStream1ivATI;
    void function(GLenum, GLfloat) glVertexStream1fATI;
    void function(GLenum, GLfloat*) glVertexStream1fvATI;
    void function(GLenum, GLdouble) glVertexStream1dATI;
    void function(GLenum, GLdouble*) glVertexStream1dvATI;
    void function(GLenum, GLshort, GLshort) glVertexStream2sATI;
    void function(GLenum, GLshort*) glVertexStream2svATI;
    void function(GLenum, GLint, GLint) glVertexStream2iATI;
    void function(GLenum, GLint*) glVertexStream2ivATI;
    void function(GLenum, GLfloat, GLfloat) glVertexStream2fATI;
    void function(GLenum, GLfloat*) glVertexStream2fvATI;
    void function(GLenum, GLdouble, GLdouble) glVertexStream2dATI;
    void function(GLenum, GLdouble*) glVertexStream2dvATI;
    void function(GLenum, GLshort, GLshort, GLshort) glVertexStream3sATI;
    void function(GLenum, GLshort*) glVertexStream3svATI;
    void function(GLenum, GLint, GLint, GLint) glVertexStream3iATI;
    void function(GLenum, GLint*) glVertexStream3ivATI;
    void function(GLenum, GLfloat, GLfloat, GLfloat) glVertexStream3fATI;
    void function(GLenum, GLfloat*) glVertexStream3fvATI;
    void function(GLenum, GLdouble, GLdouble, GLdouble) glVertexStream3dATI;
    void function(GLenum, GLdouble*) glVertexStream3dvATI;
    void function(GLenum, GLshort, GLshort, GLshort, GLshort) glVertexStream4sATI;
    void function(GLenum, GLshort*) glVertexStream4svATI;
    void function(GLenum, GLint, GLint, GLint, GLint) glVertexStream4iATI;
    void function(GLenum, GLint*) glVertexStream4ivATI;
    void function(GLenum, GLfloat, GLfloat, GLfloat, GLfloat) glVertexStream4fATI;
    void function(GLenum, GLfloat*) glVertexStream4fvATI;
    void function(GLenum, GLdouble, GLdouble, GLdouble, GLdouble) glVertexStream4dATI;
    void function(GLenum, GLdouble*) glVertexStream4dvATI;
    void function(GLenum, GLbyte, GLbyte, GLbyte) glNormalStream3bATI;
    void function(GLenum, GLbyte*) glNormalStream3bvATI;
    void function(GLenum, GLshort, GLshort, GLshort) glNormalStream3sATI;
    void function(GLenum, GLshort*) glNormalStream3svATI;
    void function(GLenum, GLint, GLint, GLint) glNormalStream3iATI;
    void function(GLenum, GLint*) glNormalStream3ivATI;
    void function(GLenum, GLfloat, GLfloat, GLfloat) glNormalStream3fATI;
    void function(GLenum, GLfloat*) glNormalStream3fvATI;
    void function(GLenum, GLdouble, GLdouble, GLdouble) glNormalStream3dATI;
    void function(GLenum, GLdouble*) glNormalStream3dvATI;
    void function(GLenum) glClientActiveVertexStreamATI;
    void function(GLenum, GLint) glVertexBlendEnviATI;
    void function(GLenum, GLfloat) glVertexBlendEnvfATI;
}