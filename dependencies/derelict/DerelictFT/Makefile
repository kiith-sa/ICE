include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/freetype
FT_LIB=$(LIB_PRE)DerelictFT.$(LIB_EXT)

all : DerelictFT
DerelictFT : $(FT_LIB) copylib

FT_SRC= \
    derelict/freetype/ft.d \
    derelict/freetype/ftfuncs.d \
    derelict/freetype/fttypes.d

$(FT_LIB) : $(DC)_build

dmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FT_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FT_LIB)

ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FT_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(FT_LIB) *.o
	$(RM) *.o
	
gdmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(FT_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(FT_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

