include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/allegro
AL_LIB=$(LIB_PRE)DerelictAllegro.$(LIB_EXT)
IMG_LIB=$(LIB_PRE)DerelictAllegroImage.$(LIB_EXT)
FNT_LIB=$(LIB_PRE)DerelictAllegroFont.$(LIB_EXT)
AUD_LIB=$(LIB_PRE)DerelictAllegroAudio.$(LIB_EXT)
COD_LIB=$(LIB_PRE)DerelictAllegroACodec.$(LIB_EXT)
DIA_LIB=$(LIB_PRE)DerelictAllegroDialog.$(LIB_EXT)
TTF_LIB=$(LIB_PRE)DerelictAllegroTTF.$(LIB_EXT)
PRM_LIB=$(LIB_PRE)DerelictAllegroPrimitives.$(LIB_EXT)

all : $(AL_LIB) $(IMG_LIB) $(FNT_LIB) $(AUD_LIB) $(COD_LIB) $(DIA_LIB) $(TTF_LIB) $(PRM_LIB) copylib
DerelictAllegro : $(AL_LIB) copylib
DerelictAllegroImage : $(IMG_LIB) copylib
DerelictAllegroFont : $(FNT_LIB) copylib
DerelictAllegroAudio : $(AUD_LIB) copylib
DerelictAllegroACodec : $(COD_LIB) copylib
DerelictAllegroDialog : $(DIA_LIB) copylib
DerelictAllegroTTF : $(TTF_LIB) copylib
DerelictAllegroPrimitives : $(PRM_LIB) copylib

AL_SRC= \
    derelict/allegro/allegro.d \
    derelict/allegro/allegrofuncs.d \
    derelict/allegro/allegrotypes.d   

IMG_SRC= \
	derelict/allegro/image.d    
	
FNT_SRC= \
	derelict/allegro/font.d
	
AUD_SRC= \
	derelict/allegro/audio.d
	
COD_SRC= \
	derelict/allegro/acodec.d
	
DIA_SRC=\
	derelict/allegro/dialog.d
	
TTF_SRC=\
	derelict/allegro/ttf.d
	
PRM_SRC=\
	derelict/allegro/primitives.d
    
$(AL_LIB) : $(DC)_build_al
$(IMG_LIB) : $(DC)_build_img
$(FNT_LIB) : $(DC)_build_fnt
$(AUD_LIB) : $(DC)_build_aud
$(COD_LIB) : $(DC)_build_cod
$(DIA_LIB) : $(DC)_build_dia
$(TTF_LIB) : $(DC)_build_ttf
$(PRM_LIB) : $(DC)_build_prm

# DMD ##############################################
dmd_build_al:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AL_LIB)
	
dmd_build_img:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(IMG_LIB)
	
dmd_build_fnt:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FNT_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FNT_LIB)
	
dmd_build_aud:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AUD_LIB)
	
dmd_build_cod:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(COD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(COD_LIB)
	
dmd_build_dia:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(DIA_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(DIA_LIB)
	
dmd_build_ttf:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(TTF_LIB)
	
dmd_build_prm:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PRM_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(PRM_LIB)
	
# LDC ##############################################
ldc_build_al:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(AL_LIB) *.o
	$(RM) *.o
	
ldc_build_img:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(IMG_LIB) *.o
	$(RM) *.o
	
ldc_build_fnt:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FNT_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(FNT_LIB) *.o
	$(RM) *.o
	
ldc_build_aud:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUD_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(AUD_LIB) *.o
	$(RM) *.o
	
ldc_build_cod:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(COD_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(COD_LIB) *.o
	$(RM) *.o
	
ldc_build_dia:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(DIA_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(DIA_LIB) *.o
	$(RM) *.o
	
ldc_build_ttf:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(TTF_LIB) *.o
	$(RM) *.o
	
ldc_build_prm:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PRM_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(PRM_LIB) *.o
	$(RM) *.o
	
# GDMD/GDC ##############################################
gdmd_build_al:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AL_LIB)
	
gdmd_build_img:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(IMG_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(IMG_LIB)
	
gdmd_build_fnt:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FNT_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FNT_LIB)
	
gdmd_build_aud:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(AUD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(AUD_LIB)
	
gdmd_build_cod:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(COD_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(COD_LIB)
	
gdmd_build_dia:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(DIA_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(DIA_LIB)
	
gdmd_build_ttf:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(TTF_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(TTF_LIB)
	
gdmd_build_prm:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(PRM_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(PRM_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

