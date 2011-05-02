include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/openal
AL_LIB=$(LIB_PRE)DerelictAL.$(LIB_EXT)

all : DerelictAL
DerelictAL : $(AL_LIB) copylib

AL_SRC= \
    derelict/openal/al.d \
    derelict/openal/alfuncs.d \
    derelict/openal/altypes.d   

$(AL_LIB) : $(DC)_build

dmd_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AL_LIB)
	
ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(AL_LIB) *.o
	$(RM) *.o
	
gdmd_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AL_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

