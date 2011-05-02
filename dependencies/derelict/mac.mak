include inc/linux_inc.mak

all : DerelictAL_ALL DerelictFMODEX_ALL DerelictFT_ALL DerelictGL_ALL DerelictIL_ALL DerelictODE_ALL DerelictOgg_ALL DerelictPA_ALL DerelictSDL_ALL DerelictSFML_ALL DerelictUtil_ALL

# Targets for all libs in each package
DerelictAL_ALL :
	$(DMAKE) -C DerelictAL all PLATFORM=mac
	
DerelictFMODEX_ALL :
	$(DMAKE) -C DerelictFMOD all PLATFORM=mac	

DerelictFT_ALL :
	$(DMAKE) -C DerelictFT all PLATFORM=mac
		
DerelictGL_ALL :
	$(DMAKE) -C DerelictGL all PLATFORM=mac
	
DerelictIL_ALL :
	$(DMAKE) -C DerelictIL all PLATFORM=mac
	
DerelictODE_ALL :
	$(DMAKE) -C DerelictODE all PLATFORM=mac
	
DerelictOgg_ALL :
	$(DMAKE) -C DerelictOgg all PLATFORM=mac
	
DerelictPA_ALL:
	$(DMAKE) -C DerelictPA all PLATFORM=mac

DerelictSDL_ALL :
	$(DMAKE) -C DerelictSDL all PLATFORM=mac

DerelictSFML_ALL :
	$(DMAKE) -C DerelictSFML all PLATFORM=mac
	
DerelictUtil_ALL :
	$(DMAKE) -C DerelictUtil all PLATFORM=mac
	
# There's only one DerelictAL target
DerelictAL : DerelictAL_ALL

# There's only one DerelictFMODEX target
DerelictFMODEX : DerelictFMODEX_ALL

# There's only one DerelictFT target
DerelictFT : DerelictFT_ALL
	
# Individual DerelictGL targets
DerelictGL :
	$(DMAKE) -C DerelictGL DerelictGL PLATFORM=mac
	
DerelictGLU :
	$(DMAKE) -C DerelictGL DerelictGLU PLATFORM=mac
	
# Individual DerelictIL targets
DerelictIL :
	$(DMAKE) -C DerelictIL DerelictIL PLATFORM=mac
	
DerelictILU :
	$(DMAKE) -C DerelictIL DerelictILU PLATFORM=mac
	
DerelictILUT :
	$(DMAKE) -C DerelictIL DerelictILUT PLATFORM=mac
	
# There's only one target for DerelictODE
DerelictODE : DerelictODE_ALL
	
# Individual DerelictOgg targets
DerelictOgg :
	$(DMAKE) -C DerelictOgg DerelictOgg PLATFORM=mac
	
# There's only one target for DerelictPA
DerelictPA : DerelictPA_ALL	
	
DerelictVorbis :
	$(DMAKE) -C DerelictOgg DerelictVorbis PLATFORM=mac
	
DerelictVorbisEnc :
	$(DMAKE) -C DerelictOgg DerelictVorbisEnc PLATFORM=mac
	
DerelictVorbisFile :
	$(DMAKE) -C DerelictOgg DerelictVorbisFile PLATFORM=mac	
	
# Individual DerelictSDL targets
DerelictSDL :
	$(DMAKE) -C DerelictSDL DerelictSDL PLATFORM=mac
	
DerelictSDLImage :
	$(DMAKE) -C DerelictSDL DerelictSDLImage PLATFORM=mac

DerelictSDLMixer :
	$(DMAKE) -C DerelictSDL DerelictSDLMixer PLATFORM=mac

DerelictSDLNet :
	$(DMAKE) -C DerelictSDL DerelictSDLNet PLATFORM=mac
	
DerelictSDLttf :
	$(DMAKE) -C DerelictSDL DerelictSDLttf PLATFORM=mac
	
# Individual DerelictSFML targets
DerelictSFMLWindow :
	$(DMAKE) -C DerelictSFML DerelictSFMLWindow PLATFORM=mac
	
DerelictSFMLSystem :
	$(DMAKE) -C DerelictSFML DerelictSFMLSystem PLATFORM=mac
	
DerelictSFMLGraphics :
	$(DMAKE) -C DerelictSFML DerelictSFMLGraphics PLATFORM=mac
	
DerelictSFMLAudio :
	$(DMAKE) -C DerelictSFML DerelictSFMLAudio PLATFORM=mac
	
DerelictSFMLNetwork :
	$(DMAKE) -C DerelictSFML DerelictSFMLNetwork PLATFORM=mac
	
# There's only one DerelictUtil target
DerelictUtil : DerelictUtil_All
	
cleanall : cleanlib cleandi

clean : cleanlib

cleanlib:
	cd DerelictUtil && $(RM) $(LIB_DEST)/*.a
	
cleandi:
	cd DerelictUtil  && $(RMR) $(IMPORT_DEST)/derelict
	