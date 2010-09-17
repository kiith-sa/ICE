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
module derelict.opengl.glx;

version (freebsd)
{
	version = GLX;
}

else version (FreeBSD)
{
	version = GLX;
}

else version (linux)
{
	version = GLX;
}

version(GLX)
{

private
{
    import derelict.opengl.gltypes;
    import derelict.util.loader;
    import derelict.util.xtypes;
}

struct __GLXcontextRec {}
struct __GLXFBConfigRec {}

typedef uint GLXContentID;
typedef uint GLXPixmap;
typedef uint GLXDrawable;
typedef uint GLXPbuffer;
typedef uint GLXWindow;
typedef uint GLXFBConfigID;

typedef __GLXcontextRec *GLXContext;      // __GLXcontextRec type is opaque
typedef __GLXFBConfigRec *GLXFBConfig;    // __GLXFBConfigRec type is opaque

/*
 * GLX Events
 */

struct GLXPbufferClobberEvent
{
    int         event_type;
    int         draw_type;
    uint        serial;
    Bool        send_event;
    Display*    display;
    GLXDrawable drawable;
    uint        buffer_mask;
    uint        aux_buffer;
    int         x, y;
    int         width, height;
    int         count;
}

union GLXEvent
{
    GLXPbufferClobberEvent glxpbufferclobber;
    int pad[24];
}

// Function pointer variables

extern (C)
    {
     XVisualInfo* function(Display*,int,int*) glXChooseVisual;
     void function(Display*,GLXContext,GLXContext,uint) glXCopyContext;
     GLXContext function(Display*,XVisualInfo*,GLXContext,Bool) glXCreateContext;
     GLXPixmap function(Display*,XVisualInfo*,Pixmap) glXCreateGLXPixmap;
     void function(Display*,GLXContext) glXDestroyContext;
     void function(Display*,GLXPixmap) glXDestroyGLXPixmap;
     int  function(Display*,XVisualInfo*,int,int*) glXGetConfig;
     GLXContext function() glXGetCurrentContext;
     GLXDrawable function() glXGetCurrentDrawable;
     Bool function(Display*,GLXContext) glXIsDirect;
     Bool function(Display*,GLXDrawable,GLXContext) glXMakeCurrent;
     Bool function(Display*,int*,int*) glXQueryExtension;
     Bool function(Display*,int*,int*) glXQueryVersion;
     void function(Display*,GLXDrawable) glXSwapBuffers;
     void function(Font,int,int,int) glXUseXFont;
     void function() glXWaitGL;
     void function() glXWaitX;
     char* function(Display*,int) glXGetClientString;
     char* function(Display*,int,int) glXQueryServerString;
     char* function(Display*,int) glXQueryExtensionsString;

    /* GLX 1.3 */

     GLXFBConfig* function(Display*,int,int*) glXGetFBConfigs;
     GLXFBConfig* function(Display*,int,int*,int*) glXChooseFBConfig;
     int  function(Display*,GLXFBConfig,int,int*) glXGetFBConfigAttrib;
     XVisualInfo* function(Display*,GLXFBConfig) glXGetVisualFromFBConfig;
     GLXWindow function(Display*,GLXFBConfig,Window,int*) glXCreateWindow;
     void function(Display*,GLXWindow) glXDestroyWindow;
     GLXPixmap function(Display*,GLXFBConfig,Pixmap,int*) glXCreatePixmap;
     void function(Display*,GLXPixmap) glXDestroyPixmap;
     GLXPbuffer function(Display*,GLXFBConfig,int*) glXCreatePbuffer;
     void function(Display*,GLXPbuffer) glXDestroyPbuffer;
     void function(Display*,GLXDrawable,int,uint*) glXQueryDrawable;
     GLXContext function(Display*,GLXFBConfig,int,GLXContext,Bool) glXCreateNewContext;
     Bool function(Display*,GLXDrawable,GLXDrawable,GLXContext) glXMakeContextCurrent;
     GLXDrawable function() glXGetCurrentReadDrawable;
     Display* function() glXGetCurrentDisplay;
     int  function(Display*,GLXContext,int,int*) glXQueryContext;
     void function(Display*,GLXDrawable,uint) glXSelectEvent;
     void function(Display*,GLXDrawable,uint*) glXGetSelectedEvent;

    /* GLX 1.4+ */
     void* function(GLchar*) glXGetProcAddress;
}

/* GLX extensions -- legacy */

/*
GLXContextID            function(const GLXContext)
                            pfglXGetContextIDEXT;
GLXContext              function(Display*,GLXContextID)
                            pfglXImportContextEXT;
void                    function(Display*,GLXContext)
                            pfglXFreeContextEXT;
int                     function(Display*,GLXContext,int,int*)
                            pfglXQueryContextInfoEXT;
Display*                function()
                            pfglXGetCurrentDisplayEXT;
void function()         function(const GLubyte*)
                            pfglXGetProcAddressARB;
*/

/+

// All extensions are disabled in the current version
// until further testing is done and need is established.

void*                   function(GLsizei,GLfloat,GLfloat,GLfloat)
                            glXAllocateMemoryNV;
void                    function(GLvoid*)
                            glXFreeMemoryNV;
void*                   function(GLsizei,GLfloat,GLfloat,GLfloat)
                            PFNGLXALLOCATEMEMORYNVPROC;
void                    function(GLvoid*)
                            PFNGLXFREEMEMORYNVPROC;

/* Mesa specific? */

// work in progress

/* GLX_ARB specific? */

Bool                    function(Display*, GLXPbuffer,int)
                            glXBindTexImageARB;
Bool                    function(Display*, GLXPbuffer,int)
                            glXReleaseTexImageARB;
Bool                    function(Display*,GLXDrawable,int*)
                            glXDrawableAttribARB;

+/

package void loadPlatformGL(SharedLib lib)
{
    bindFunc(glXChooseVisual)("glXChooseVisual", lib);
    bindFunc(glXCopyContext)("glXCopyContext", lib);
    bindFunc(glXCreateContext)("glXCreateContext", lib);
    bindFunc(glXCreateGLXPixmap)("glXCreateGLXPixmap", lib);
    bindFunc(glXDestroyContext)("glXDestroyContext", lib);
    bindFunc(glXDestroyGLXPixmap)("glXDestroyGLXPixmap", lib);
    bindFunc(glXGetConfig)("glXGetConfig", lib);
    bindFunc(glXGetCurrentContext)("glXGetCurrentContext", lib);
    bindFunc(glXGetCurrentDrawable)("glXGetCurrentDrawable", lib);
    bindFunc(glXIsDirect)("glXIsDirect", lib);
    bindFunc(glXMakeCurrent)("glXMakeCurrent", lib);
    bindFunc(glXQueryExtension)("glXQueryExtension", lib);
    bindFunc(glXQueryVersion)("glXQueryVersion", lib);
    bindFunc(glXSwapBuffers)("glXSwapBuffers", lib);
    bindFunc(glXUseXFont)("glXUseXFont", lib);
    bindFunc(glXWaitGL)("glXWaitGL", lib);
    bindFunc(glXWaitX)("glXWaitX", lib);
    bindFunc(glXGetClientString)("glXGetClientString", lib);
    bindFunc(glXQueryServerString)("glXQueryServerString", lib);
    bindFunc(glXQueryExtensionsString)("glXQueryExtensionsString", lib);

    bindFunc(glXGetFBConfigs)("glXGetFBConfigs", lib);
    bindFunc(glXChooseFBConfig)("glXChooseFBConfig", lib);
    bindFunc(glXGetFBConfigAttrib)("glXGetFBConfigAttrib", lib);
    bindFunc(glXGetVisualFromFBConfig)("glXGetVisualFromFBConfig", lib);
    bindFunc(glXCreateWindow)("glXCreateWindow", lib);
    bindFunc(glXDestroyWindow)("glXDestroyWindow", lib);
    bindFunc(glXCreatePixmap)("glXCreatePixmap", lib);
    bindFunc(glXDestroyPixmap)("glXDestroyPixmap", lib);
    bindFunc(glXCreatePbuffer)("glXCreatePbuffer", lib);
    bindFunc(glXDestroyPbuffer)("glXDestroyPbuffer", lib);
    bindFunc(glXQueryDrawable)("glXQueryDrawable", lib);
    bindFunc(glXCreateNewContext)("glXCreateNewContext", lib);
    bindFunc(glXMakeContextCurrent)("glXMakeContextCurrent", lib);
    bindFunc(glXGetCurrentReadDrawable)("glXGetCurrentReadDrawable", lib);
    bindFunc(glXGetCurrentDisplay)("glXGetCurrentDisplay", lib);
    bindFunc(glXQueryContext)("glXQueryContext", lib);
    bindFunc(glXSelectEvent)("glXSelectEvent", lib);
    bindFunc(glXGetSelectedEvent)("glXGetSelectedEvent", lib);

    bindFunc(glXGetProcAddress)("glXGetProcAddressARB", lib);
}

}   // version(linux)
