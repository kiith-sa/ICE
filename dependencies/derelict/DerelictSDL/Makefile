include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/sdl
MACINIT_PATH=$(PACKAGE_PATH)/macinit
SDL_LIB=$(LIB_PRE)DerelictSDL.$(LIB_EXT)
IMG_LIB=$(LIB_PRE)DerelictSDLImage.$(LIB_EXT)
MIX_LIB=$(LIB_PRE)DerelictSDLMixer.$(LIB_EXT)
NET_LIB=$(LIB_PRE)DerelictSDLNet.$(LIB_EXT)
TTF_LIB=$(LIB_PRE)DerelictSDLttf.$(LIB_EXT)

all : $(SDL_LIB) $(IMG_LIB) $(MIX_LIB) $(NET_LIB) $(TTF_LIB) copylib
DerelictSDL : $(SDL_LIB) copylib
DerelictSDLImage : $(IMG_LIB) copylib
DerelictSDLMixer : $(MIX_LIB) copylib
DerelictSDLNet : $(NET_LIB) copylib
DerelictSDLttf : $(TTF_LIB) copylib

SDL_SRC= \
	derelict/sdl/sdl.d \
    derelict/sdl/sdlfuncs.d \
    derelict/sdl/sdltypes.d
    
MACINIT_SRC=\
	derelict/sdl/macinit/CoreFoundation.d \
	derelict/sdl/macinit/DerelictSDLMacLoader.d \
	derelict/sdl/macinit/ID.d \
	derelict/sdl/macinit/MacTypes.d \
	derelict/sdl/macinit/NSApplication.d \
	derelict/sdl/macinit/NSArray.d \
	derelict/sdl/macinit/NSAutoreleasePool.d \
	derelict/sdl/macinit/NSDictionary.d \
	derelict/sdl/macinit/NSEnumerator.d \
	derelict/sdl/macinit/NSEvent.d \
	derelict/sdl/macinit/NSGeometry.d \
	derelict/sdl/macinit/NSMenu.d \
	derelict/sdl/macinit/NSMenuItem.d \
	derelict/sdl/macinit/NSNotification.d \
	derelict/sdl/macinit/NSObject.d \
	derelict/sdl/macinit/NSProcessInfo.d \
	derelict/sdl/macinit/NSString.d \
	derelict/sdl/macinit/NSZone.d \
	derelict/sdl/macinit/runtime.d \
	derelict/sdl/macinit/SDLMain.d \
	derelict/sdl/macinit/selectors.d \
	derelict/sdl/macinit/string.d	
    
IMG_SRC= derelict/sdl/image.d

MIX_SRC= derelict/sdl/mixer.d

NET_SRC= derelict/sdl/net.d 

TTF_SRC= derelict/sdl/ttf.d

$(SDL_LIB) : $(PLATFORM)_build_sdl
win32_build_sdl : $(DC)_build_sdl
linux_build_sdl : $(DC)_build_sdl
mac_build_sdl : $(DC)_mac_build_sdl
$(IMG_LIB) : $(DC)_build_img
$(MIX_LIB) : $(DC)_build_mix
$(NET_LIB) : $(DC)_build_net
$(TTF_LIB) : $(DC)_build_ttf

# DMD ##############################################
dmd_build_sdl :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SDL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(SDL_LIB)
	
dmd_mac_build_sdl : 
	$(DC) $(DFLAGS) -I../DerelictUtil -c $(SDL_SRC) $(HD)/$(PACKAGE_PATH)
	$(DC) $(DFLAGS) -I../DerelictUtil -c $(MACINIT_SRC) $(HD)/$(MACINIT_PATH)
	$(DC) $(DFLAGS) -lib *.o $(OF)$(SDL_LIB)
	$(RM) *.$(OBJ_EXT)

dmd_build_img :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(IMG_LIB)

dmd_build_mix :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(MIX_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(MIX_LIB)

dmd_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(NET_LIB)

dmd_build_ttf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(TTF_LIB)

# LDC ##############################################
ldc_build_sdl :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SDL_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(SDL_LIB) *.o
	$(RM) *.o
	
ldc_build_macinit :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SDL_SRC) $(HD)/$(MACINIT_PATH)
	
ldc_mac_build_sdl : ldc_build_macinit ldc_build_sdl

ldc_build_img :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(IMG_LIB) *.o
	$(RM) *.o

ldc_build_mix :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(MIX_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(MIX_LIB) *.o
	$(RM) *.o

ldc_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(NET_LIB) *.o
	$(RM) *.o

ldc_build_ttf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(TTF_LIB) *.o
	$(RM) *.o
	
# GDMD/GDC ##############################################
gdmd_build_sdl :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SDL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(SDL_LIB)
	
gdmd_mac_build_sdl : 
	$(DC) $(DFLAGS) -I../DerelictUtil -c $(SDL_SRC) $(HD)/$(PACKAGE_PATH)
	$(DC) $(DFLAGS) -I../DerelictUtil -c $(MACINIT_SRC) $(HD)/$(MACINIT_PATH)
	$(DC) $(DFLAGS) -lib *.o $(OF)$(SDL_LIB)
	$(RM) *.$(OBJ_EXT)

gdmd_build_img :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(IMG_LIB)

gdmd_build_mix :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(MIX_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(MIX_LIB)

gdmd_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(NET_LIB)

gdmd_build_ttf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(TTF_LIB)

####################################################
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

