include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/opengl
GL_LIB=$(LIB_PRE)DerelictGL.$(LIB_EXT)
GLU_LIB=$(LIB_PRE)DerelictGLU.$(LIB_EXT)

all : $(GL_LIB) $(GLU_LIB) copylib
DerelictGL : $(GL_LIB) copylib
DerelictGLU : $(GLU_LIB) copylib

#GL_VERSIONS=$(VER)DerelictGL_ALL
#GL_VERSIONS=$(VER)DerelictGL_ARB $(VER)DerelictGL_EXT $(VER)DerelictGL_NV $(VER)DerelictGL_ATI $(VER)DerelictGL_AMD
GL_VERSIONS=

GL_SRC= \
	derelict/opengl/cgl.d \
    derelict/opengl/extfuncs.d \
    derelict/opengl/extloader.d \
    derelict/opengl/exttypes.d \
    derelict/opengl/gl.d \
    derelict/opengl/glext.d \
    derelict/opengl/glfuncs.d \
    derelict/opengl/gltypes.d \
    derelict/opengl/glx.d \
    derelict/opengl/wgl.d \
    
GLU_SRC= \
    derelict/opengl/glu.d \
    derelict/opengl/glufuncs.d \
    derelict/opengl/glutypes.d     

$(GL_LIB) : $(DC)_build_gl

$(GLU_LIB) : $(DC)_build_glu

# DMD ##############################################
dmd_build_gl:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GL_VERSIONS) $(GL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GL_LIB)
	
dmd_build_glu:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GLU_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GLU_LIB)
	
# LDC ##############################################
ldc_build_gl:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GL_VERSIONS) $(GL_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(GL_LIB) *.o
	$(RM) *.o

ldc_build_glu:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GLU_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(GLU_LIB) *.o
	$(RM) *.o
	
# GDMD/GDC ##############################################
gdmd_build_gl:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GL_VERSIONS) $(GL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GL_LIB)
	
gdmd_build_glu:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GLU_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GLU_LIB)
	
####################################################
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

