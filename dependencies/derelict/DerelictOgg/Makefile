include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/ogg
OGG_LIB=$(LIB_PRE)DerelictOGG.$(LIB_EXT)
V_LIB=$(LIB_PRE)DerelictVorbis.$(LIB_EXT)
VE_LIB=$(LIB_PRE)DerelictVorbisEnc.$(LIB_EXT)
VF_LIB=$(LIB_PRE)DerelictVorbisFile.$(LIB_EXT)

all : $(OGG_LIB) $(V_LIB) $(VE_LIB) $(VF_LIB) copylib
DerleictOGG : $(OGG_LIB) copylib
DerelictVorbis : $(V_LIB) copylib
DerelictVorbisEnc : $(VE_LIB) copylib
DerelictVorbisFile : $(VF_LIB) copylib

OGG_SRC= \
	derelict/ogg/ogg.d \
    derelict/ogg/oggfuncs.d \
    derelict/ogg/oggtypes.d
    
V_SRC= \
	derelict/ogg/vorbis.d \
	derelict/ogg/vorbisfuncs.d \
	derelict/ogg/vorbistypes.d  
	
VE_SRC= \
	derelict/ogg/vorbisenc.d \
	derelict/ogg/vorbisencfuncs.d \
	derelict/ogg/vorbisenctypes.d 
	
VF_SRC= \
	derelict/ogg/vorbisfile.d \
	derelict/ogg/vorbisfilefuncs.d \
	derelict/ogg/vorbisfiletypes.d 

$(OGG_LIB) : $(DC)_build_ogg
$(V_LIB) : $(DC)_build_v
$(VE_LIB) : $(DC)_build_ve
$(VF_LIB) : $(DC)_build_vf
    

# DMD ##############################################
dmd_build_ogg :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(OGG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(OGG_LIB)

dmd_build_v :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(V_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(V_LIB)

dmd_build_ve :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VE_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(VE_LIB)

dmd_build_vf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(VF_LIB)

# LDC ##############################################
ldc_build_ogg :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(OGG_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(OGG_LIB) *.o
	$(RM) *.o

ldc_build_v :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(V_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(V_LIB) *.o
	$(RM) *.o

ldc_build_ve :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VE_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(VE_LIB) *.o
	$(RM) *.o

ldc_build_vf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VF_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(VF_LIB) *.o
	$(RM) *.o
	
# GDMD/GDC ##############################################
gdmd_build_ogg :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(OGG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(OGG_LIB)

gdmd_build_v :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(V_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(V_LIB)

gdmd_build_ve :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VE_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(VE_LIB)

gdmd_build_vf :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(VF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(VF_LIB)

####################################################
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

