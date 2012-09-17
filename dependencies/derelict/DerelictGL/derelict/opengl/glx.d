/*

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

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
    import derelict.util.compat;
    import derelict.util.loader;
    import derelict.util.xtypes;
}

struct __GLXcontextRec {}
struct __GLXFBConfigRec {}

alias uint GLXContentID;
alias uint GLXPixmap;
alias uint GLXDrawable;
alias uint GLXPbuffer;
alias uint GLXWindow;
alias uint GLXFBConfigID;

alias __GLXcontextRec *GLXContext;      // __GLXcontextRec type is opaque
alias __GLXFBConfigRec *GLXFBConfig;    // __GLXFBConfigRec type is opaque

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
    alias XVisualInfo* function(Display*,int,int*) da_glXChooseVisual;
    alias void function(Display*,GLXContext,GLXContext,uint) da_glXCopyContext;
    alias GLXContext function(Display*,XVisualInfo*,GLXContext,Bool) da_glXCreateContext;
    alias GLXPixmap function(Display*,XVisualInfo*,Pixmap) da_glXCreateGLXPixmap;
    alias void function(Display*,GLXContext) da_glXDestroyContext;
    alias void function(Display*,GLXPixmap) da_glXDestroyGLXPixmap;
    alias int  function(Display*,XVisualInfo*,int,int*) da_glXGetConfig;
    alias GLXContext function() da_glXGetCurrentContext;
    alias GLXDrawable function() da_glXGetCurrentDrawable;
    alias Bool function(Display*,GLXContext) da_glXIsDirect;
    alias Bool function(Display*,GLXDrawable,GLXContext) da_glXMakeCurrent;
    alias Bool function(Display*,int*,int*) da_glXQueryExtension;
    alias Bool function(Display*,int*,int*) da_glXQueryVersion;
    alias void function(Display*,GLXDrawable) da_glXSwapBuffers;
    alias void function(Font,int,int,int) da_glXUseXFont;
    alias void function() da_glXWaitGL;
    alias void function() da_glXWaitX;
    alias char* function(Display*,int) da_glXGetClientString;
    alias char* function(Display*,int,int) da_glXQueryServerString;
    alias char* function(Display*,int) da_glXQueryExtensionsString;

    /* GLX 1.3 */

    alias GLXFBConfig* function(Display*,int,int*) da_glXGetFBConfigs;
    alias GLXFBConfig* function(Display*,int,int*,int*) da_glXChooseFBConfig;
    alias int  function(Display*,GLXFBConfig,int,int*) da_glXGetFBConfigAttrib;
    alias XVisualInfo* function(Display*,GLXFBConfig) da_glXGetVisualFromFBConfig;
    alias GLXWindow function(Display*,GLXFBConfig,Window,int*) da_glXCreateWindow;
    alias void function(Display*,GLXWindow) da_glXDestroyWindow;
    alias GLXPixmap function(Display*,GLXFBConfig,Pixmap,int*) da_glXCreatePixmap;
    alias void function(Display*,GLXPixmap) da_glXDestroyPixmap;
    alias GLXPbuffer function(Display*,GLXFBConfig,int*) da_glXCreatePbuffer;
    alias void function(Display*,GLXPbuffer) da_glXDestroyPbuffer;
    alias void function(Display*,GLXDrawable,int,uint*) da_glXQueryDrawable;
    alias GLXContext function(Display*,GLXFBConfig,int,GLXContext,Bool) da_glXCreateNewContext;
    alias Bool function(Display*,GLXDrawable,GLXDrawable,GLXContext) da_glXMakeContextCurrent;
    alias GLXDrawable function() da_glXGetCurrentReadDrawable;
    alias Display* function() da_glXGetCurrentDisplay;
    alias int  function(Display*,GLXContext,int,int*) da_glXQueryContext;
    alias void function(Display*,GLXDrawable,uint) da_glXSelectEvent;
    alias void function(Display*,GLXDrawable,uint*) da_glXGetSelectedEvent;

    /* GLX 1.4+ */
    alias void* function(CCPTR) da_glXGetProcAddress;


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


mixin(gsharedString!() ~
"
da_glXChooseVisual glXChooseVisual;
da_glXCopyContext glXCopyContext;
da_glXCreateContext glXCreateContext;
da_glXCreateGLXPixmap glXCreateGLXPixmap;
da_glXDestroyContext glXDestroyContext;
da_glXDestroyGLXPixmap glXDestroyGLXPixmap;
da_glXGetConfig glXGetConfig;
da_glXGetCurrentContext glXGetCurrentContext;
da_glXGetCurrentDrawable glXGetCurrentDrawable;
da_glXIsDirect glXIsDirect;
da_glXMakeCurrent glXMakeCurrent;
da_glXQueryExtension glXQueryExtension;
da_glXQueryVersion glXQueryVersion;
da_glXSwapBuffers glXSwapBuffers;
da_glXUseXFont glXUseXFont;
da_glXWaitGL glXWaitGL;
da_glXWaitX glXWaitX;
da_glXGetClientString glXGetClientString;
da_glXQueryServerString glXQueryServerString;
da_glXQueryExtensionsString glXQueryExtensionsString;

/* GLX 1.3 */

da_glXGetFBConfigs glXGetFBConfigs;
da_glXChooseFBConfig glXChooseFBConfig;
da_glXGetFBConfigAttrib glXGetFBConfigAttrib;
da_glXGetVisualFromFBConfig glXGetVisualFromFBConfig;
da_glXCreateWindow glXCreateWindow;
da_glXDestroyWindow glXDestroyWindow;
da_glXCreatePixmap glXCreatePixmap;
da_glXDestroyPixmap glXDestroyPixmap;
da_glXCreatePbuffer glXCreatePbuffer;
da_glXDestroyPbuffer glXDestroyPbuffer;
da_glXQueryDrawable glXQueryDrawable;
da_glXCreateNewContext glXCreateNewContext;
da_glXMakeContextCurrent glXMakeContextCurrent;
da_glXGetCurrentReadDrawable glXGetCurrentReadDrawable;
da_glXGetCurrentDisplay glXGetCurrentDisplay;
da_glXQueryContext glXQueryContext;
da_glXSelectEvent glXSelectEvent;
da_glXGetSelectedEvent glXGetSelectedEvent;

/* GLX 1.4+ */
da_glXGetProcAddress glXGetProcAddress;

");

package
{
    //Commented out code is because delegates can no longer have default arguments.
    /*void loadPlatformGL(void delegate(void**, string, bool doThrow = true) bindFunc)*/
    void loadPlatformGL(void delegate(void**, string, bool doThrow) bindFunc)
    {
        auto bindFuncWrapper = delegate(void** a, string b) {bindFunc(a, b, true);};
        bindFuncWrapper(cast(void**)&glXChooseVisual, "glXChooseVisual");
        bindFuncWrapper(cast(void**)&glXCopyContext, "glXCopyContext");
        bindFuncWrapper(cast(void**)&glXCreateContext, "glXCreateContext");
        bindFuncWrapper(cast(void**)&glXCreateGLXPixmap, "glXCreateGLXPixmap");
        bindFuncWrapper(cast(void**)&glXDestroyContext, "glXDestroyContext");
        bindFuncWrapper(cast(void**)&glXDestroyGLXPixmap, "glXDestroyGLXPixmap");
        bindFuncWrapper(cast(void**)&glXGetConfig, "glXGetConfig");
        bindFuncWrapper(cast(void**)&glXGetCurrentContext, "glXGetCurrentContext");
        bindFuncWrapper(cast(void**)&glXGetCurrentDrawable, "glXGetCurrentDrawable");
        bindFuncWrapper(cast(void**)&glXIsDirect, "glXIsDirect");
        bindFuncWrapper(cast(void**)&glXMakeCurrent, "glXMakeCurrent");
        bindFuncWrapper(cast(void**)&glXQueryExtension, "glXQueryExtension");
        bindFuncWrapper(cast(void**)&glXQueryVersion, "glXQueryVersion");
        bindFuncWrapper(cast(void**)&glXSwapBuffers, "glXSwapBuffers");
        bindFuncWrapper(cast(void**)&glXUseXFont, "glXUseXFont");
        bindFuncWrapper(cast(void**)&glXWaitGL, "glXWaitGL");
        bindFuncWrapper(cast(void**)&glXWaitX, "glXWaitX");
        bindFuncWrapper(cast(void**)&glXGetClientString, "glXGetClientString");
        bindFuncWrapper(cast(void**)&glXQueryServerString, "glXQueryServerString");
        bindFuncWrapper(cast(void**)&glXQueryExtensionsString, "glXQueryExtensionsString");
               
        bindFuncWrapper(cast(void**)&glXGetFBConfigs, "glXGetFBConfigs");
        bindFuncWrapper(cast(void**)&glXChooseFBConfig, "glXChooseFBConfig");
        bindFuncWrapper(cast(void**)&glXGetFBConfigAttrib, "glXGetFBConfigAttrib");
        bindFuncWrapper(cast(void**)&glXGetVisualFromFBConfig, "glXGetVisualFromFBConfig");
        bindFuncWrapper(cast(void**)&glXCreateWindow, "glXCreateWindow");
        bindFuncWrapper(cast(void**)&glXDestroyWindow, "glXDestroyWindow");
        bindFuncWrapper(cast(void**)&glXCreatePixmap, "glXCreatePixmap");
        bindFuncWrapper(cast(void**)&glXDestroyPixmap, "glXDestroyPixmap");
        bindFuncWrapper(cast(void**)&glXCreatePbuffer, "glXCreatePbuffer");
        bindFuncWrapper(cast(void**)&glXDestroyPbuffer, "glXDestroyPbuffer");
        bindFuncWrapper(cast(void**)&glXQueryDrawable, "glXQueryDrawable");
        bindFuncWrapper(cast(void**)&glXCreateNewContext, "glXCreateNewContext");
        bindFuncWrapper(cast(void**)&glXMakeContextCurrent, "glXMakeContextCurrent");
        bindFuncWrapper(cast(void**)&glXGetCurrentReadDrawable, "glXGetCurrentReadDrawable");
        bindFuncWrapper(cast(void**)&glXGetCurrentDisplay, "glXGetCurrentDisplay");
        bindFuncWrapper(cast(void**)&glXQueryContext, "glXQueryContext");
        bindFuncWrapper(cast(void**)&glXSelectEvent, "glXSelectEvent");
        bindFuncWrapper(cast(void**)&glXGetSelectedEvent, "glXGetSelectedEvent");
               
        bindFuncWrapper(cast(void**)&glXGetProcAddress, "glXGetProcAddressARB");
        /*
        bindFunc(cast(void**)&glXChooseVisual, "glXChooseVisual");
        bindFunc(cast(void**)&glXCopyContext, "glXCopyContext");
        bindFunc(cast(void**)&glXCreateContext, "glXCreateContext");
        bindFunc(cast(void**)&glXCreateGLXPixmap, "glXCreateGLXPixmap");
        bindFunc(cast(void**)&glXDestroyContext, "glXDestroyContext");
        bindFunc(cast(void**)&glXDestroyGLXPixmap, "glXDestroyGLXPixmap");
        bindFunc(cast(void**)&glXGetConfig, "glXGetConfig");
        bindFunc(cast(void**)&glXGetCurrentContext, "glXGetCurrentContext");
        bindFunc(cast(void**)&glXGetCurrentDrawable, "glXGetCurrentDrawable");
        bindFunc(cast(void**)&glXIsDirect, "glXIsDirect");
        bindFunc(cast(void**)&glXMakeCurrent, "glXMakeCurrent");
        bindFunc(cast(void**)&glXQueryExtension, "glXQueryExtension");
        bindFunc(cast(void**)&glXQueryVersion, "glXQueryVersion");
        bindFunc(cast(void**)&glXSwapBuffers, "glXSwapBuffers");
        bindFunc(cast(void**)&glXUseXFont, "glXUseXFont");
        bindFunc(cast(void**)&glXWaitGL, "glXWaitGL");
        bindFunc(cast(void**)&glXWaitX, "glXWaitX");
        bindFunc(cast(void**)&glXGetClientString, "glXGetClientString");
        bindFunc(cast(void**)&glXQueryServerString, "glXQueryServerString");
        bindFunc(cast(void**)&glXQueryExtensionsString, "glXQueryExtensionsString");

        bindFunc(cast(void**)&glXGetFBConfigs, "glXGetFBConfigs");
        bindFunc(cast(void**)&glXChooseFBConfig, "glXChooseFBConfig");
        bindFunc(cast(void**)&glXGetFBConfigAttrib, "glXGetFBConfigAttrib");
        bindFunc(cast(void**)&glXGetVisualFromFBConfig, "glXGetVisualFromFBConfig");
        bindFunc(cast(void**)&glXCreateWindow, "glXCreateWindow");
        bindFunc(cast(void**)&glXDestroyWindow, "glXDestroyWindow");
        bindFunc(cast(void**)&glXCreatePixmap, "glXCreatePixmap");
        bindFunc(cast(void**)&glXDestroyPixmap, "glXDestroyPixmap");
        bindFunc(cast(void**)&glXCreatePbuffer, "glXCreatePbuffer");
        bindFunc(cast(void**)&glXDestroyPbuffer, "glXDestroyPbuffer");
        bindFunc(cast(void**)&glXQueryDrawable, "glXQueryDrawable");
        bindFunc(cast(void**)&glXCreateNewContext, "glXCreateNewContext");
        bindFunc(cast(void**)&glXMakeContextCurrent, "glXMakeContextCurrent");
        bindFunc(cast(void**)&glXGetCurrentReadDrawable, "glXGetCurrentReadDrawable");
        bindFunc(cast(void**)&glXGetCurrentDisplay, "glXGetCurrentDisplay");
        bindFunc(cast(void**)&glXQueryContext, "glXQueryContext");
        bindFunc(cast(void**)&glXSelectEvent, "glXSelectEvent");
        bindFunc(cast(void**)&glXGetSelectedEvent, "glXGetSelectedEvent");

        bindFunc(cast(void**)&glXGetProcAddress, "glXGetProcAddressARB");
        */
    }

    void* loadGLSymbol(string symName)
    {
        return glXGetProcAddress(toCString(symName));
    }
}

}   // version(linux)
