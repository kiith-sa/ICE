include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/fmod
FMOD_LIB=$(LIB_PRE)DerelictFMODEX.$(LIB_EXT)

all : DerelictFMODEX
DerelictFMODEX : $(FMOD_LIB) copylib

FMOD_SRC= \
    derelict/fmod/fmodex.d \
    derelict/fmod/fmodexfuncs.d \
    derelict/fmod/fmodextypes.d   

$(FMOD_LIB) : $(DC)_build

dmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FMOD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FMOD_LIB)
	
ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FMOD_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(FMOD_LIB) *.o
	$(RM) *.o
	
gdmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FMOD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FMOD_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

