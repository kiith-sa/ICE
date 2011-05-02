include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/sfml
AUDIO_LIB=$(LIB_PRE)DerelictSFMLAudio.$(LIB_EXT)
GFX_LIB=$(LIB_PRE)DerelictSFMLGraphics.$(LIB_EXT)
NET_LIB=$(LIB_PRE)DerelictSFMLNetwork.$(LIB_EXT)
SYS_LIB=$(LIB_PRE)DerelictSFMLSystem.$(LIB_EXT)
WIN_LIB=$(LIB_PRE)DerelictSFMLWindow.$(LIB_EXT)

all : $(AUDIO_LIB) $(GFX_LIB) $(NET_LIB) $(SYS_LIB) $(WIN_LIB) copylib
DerelictSFMLAudio : $(AUDIO_LIB) copylib
DerelictSFMLGraphics : $(GFX_LIB) copylib
DerelictSFMLNetwork : $(NET_LIB) copylib
DerelictSFMLSystem : $(SYS_LIB) copylib
DerelictSFMLWindow : $(WIN_LIB) copylib

AUDIO_SRC= \
	derelict/sfml/atypes.d \
	derelict/sfml/afuncs.d \
	derelict/sfml/audio.d

GFX_SRC= \
	derelict/sfml/gtypes.d \
	derelict/sfml/gfuncs.d \
	derelict/sfml/graphics.d
	
NET_SRC= \
	derelict/sfml/ntypes.d \
	derelict/sfml/nfuncs.d \
	derelict/sfml/network.d

SYS_SRC= \
	derelict/sfml/config.d \
	derelict/sfml/stypes.d \
	derelict/sfml/sfuncs.d \
	derelict/sfml/system.d

WIN_SRC= \
	derelict/sfml/wtypes.d \
	derelict/sfml/wfuncs.d \
	derelict/sfml/window.d

$(AUDIO_LIB) : $(DC)_build_audio
$(GFX_LIB) : $(DC)_build_gfx
$(NET_LIB) : $(DC)_build_net
$(SYS_LIB) : $(DC)_build_sys
$(WIN_LIB) : $(DC)_build_win	

# DMD ##############################################
dmd_build_audio :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUDIO_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AUDIO_LIB)

dmd_build_gfx :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GFX_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GFX_LIB)

dmd_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(NET_LIB)

dmd_build_sys :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SYS_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(SYS_LIB)

dmd_build_win :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(WIN_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(WIN_LIB)

# LDC ##############################################
ldc_build_audio :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUDIO_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(AUDIO_LIB) *.o
	$(RM) *.o

ldc_build_gfx :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GFX_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(GFX_LIB) *.o
	$(RM) *.o

ldc_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(NET_LIB) *.o
	$(RM) *.o

ldc_build_sys :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SYS_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(SYS_LIB) *.o
	$(RM) *.o

ldc_build_win :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(WIN_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(WIN_LIB) *.o
	$(RM) *.o
	
# GDMD/GDC ##############################################
gdmd_build_audio :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUDIO_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AUDIO_LIB)

gdmd_build_gfx :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(GFX_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(GFX_LIB)

gdmd_build_net :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(NET_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(NET_LIB)

gdmd_build_sys :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(SYS_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(SYS_LIB)

gdmd_build_win :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(WIN_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(WIN_LIB)

####################################################
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

