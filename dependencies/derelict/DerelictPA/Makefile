include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/portaudio
PA_LIB=$(LIB_PRE)DerelictPA.$(LIB_EXT)

all : DerelictPA
DerelictPA : $(PA_LIB) copylib

PA_SRC= \
    derelict/portaudio/pa.d \
    derelict/portaudio/pafuncs.d \
    derelict/portaudio/patypes.d     

$(PA_LIB) : $(DC)_build

dmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PA_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(PA_LIB)

ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PA_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(PA_LIB) *.o
	$(RM) *.o
	
gdmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PA_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(PA_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

