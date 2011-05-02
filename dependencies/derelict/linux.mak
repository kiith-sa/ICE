include inc/linux_inc.mak

all : DerelictAL_ALL DerelictFMODEX_ALL DerelictFT_ALL DerelictGL_ALL DerelictIL_ALL DerelictODE_ALL DerelictOgg_ALL DerelictPA_ALL DerelictSDL_ALL DerelictSFML_ALL DerelictUtil_ALL

# Targets for all libs in each package
DerelictAL_ALL :
	$(DMAKE) -C DerelictAL all PLATFORM=linux
	
DerelictFMODEX_ALL :
	$(DMAKE) -C DerelictFMOD all PLATFORM=linux

DerelictFT_ALL :
	$(DMAKE) -C DerelictFT all PLATFORM=linux
		
DerelictGL_ALL :
	$(DMAKE) -C DerelictGL all PLATFORM=linux
	
DerelictIL_ALL :
	$(DMAKE) -C DerelictIL all PLATFORM=linux
	
DerelictODE_ALL :
	$(DMAKE) -C DerelictODE all PLATFORM=linux
	
DerelictOgg_ALL :
	$(DMAKE) -C DerelictOgg all PLATFORM=linux
	
DerelictPA_ALL:
	$(DMAKE) -C DerelictPA all PLATFORM=linux

DerelictSDL_ALL :
	$(DMAKE) -C DerelictSDL all PLATFORM=linux

DerelictSFML_ALL :
	$(DMAKE) -C DerelictSFML all PLATFORM=linux
	
DerelictUtil_ALL :
	$(DMAKE) -C DerelictUtil all PLATFORM=linux

# In cases where an individual target does not depend on one of the *_ALL targets above *and* the target has the same name
# as the package directory (such as DerelictGL and DerelictSDL), gnu make will refuse to build, reporting that the
# target is up to date. So as not to break the existing interface by changing the target names, a new dependency 
# is added to those targets so that they build properly (DerelictGL depends on GL, DerelictSDL depends on SDL, etc...).
	
# There's only one DerelictAL target
DerelictAL : DerelictAL_ALL

# There's only one DerelictFMODEX target
DerelictFMODEX : DerelictFMODEX_ALL

# There's only one DerelictFT target
DerelictFT : DerelictFT_ALL
	
# Individual DerelictGL targets
DerelictGL : GL
GL :
	$(DMAKE) -C DerelictGL DerelictGL PLATFORM=linux
	
DerelictGLU :
	$(DMAKE) -C DerelictGL DerelictGLU PLATFORM=linux
	
# Individual DerelictIL targets
DerelictIL : IL
IL :
	$(DMAKE) -C DerelictIL DerelictIL PLATFORM=linux
	
DerelictILU :
	$(DMAKE) -C DerelictIL DerelictILU PLATFORM=linux
	
DerelictILUT :
	$(DMAKE) -C DerelictIL DerelictILUT PLATFORM=linux
	
# There's only one target for DerelictODE
DerelictODE : DerelictODE_ALL
	
# Individual DerelictOgg targets
DerelictOgg : Ogg
Ogg :
	$(DMAKE) -C DerelictOgg DerelictOgg PLATFORM=linux	

DerelictVorbis :
	$(DMAKE) -C DerelictOgg DerelictVorbis PLATFORM=linux
	
DerelictVorbisEnc :
	$(DMAKE) -C DerelictOgg DerelictVorbisEnc PLATFORM=linux
	
DerelictVorbisFile :
	$(DMAKE) -C DerelictOgg DerelictVorbisFile PLATFORM=linux	

# There's only one target for DerelictPA
DerelictPA : DerelictPA_ALL		
	
# Individual DerelictSDL targets
DerelictSDL : SDL
SDL :
	$(DMAKE) -C DerelictSDL DerelictSDL PLATFORM=linux
	
DerelictSDLImage :
	$(DMAKE) -C DerelictSDL DerelictSDLImage PLATFORM=linux

DerelictSDLMixer :
	$(DMAKE) -C DerelictSDL DerelictSDLMixer PLATFORM=linux

DerelictSDLNet :
	$(DMAKE) -C DerelictSDL DerelictSDLNet PLATFORM=linux
	
DerelictSDLttf :
	$(DMAKE) -C DerelictSDL DerelictSDLttf PLATFORM=linux
	
# Individual DerelictSFML targets
DerelictSFMLWindow :
	$(DMAKE) -C DerelictSFML DerelictSFMLWindow PLATFORM=linux
	
DerelictSFMLSystem :
	$(DMAKE) -C DerelictSFML DerelictSFMLSystem PLATFORM=linux
	
DerelictSFMLGraphics :
	$(DMAKE) -C DerelictSFML DerelictSFMLGraphics PLATFORM=linux
	
DerelictSFMLAudio :
	$(DMAKE) -C DerelictSFML DerelictSFMLAudio PLATFORM=linux
	
DerelictSFMLNetwork :
	$(DMAKE) -C DerelictSFML DerelictSFMLNetwork PLATFORM=linux
	
# There's only one DerelictUtil target
DerelictUtil : DerelictUtil_ALL
	
cleanall : cleanlib cleandi

clean : cleanlib

cleanlib:
	cd DerelictUtil && $(RM) $(LIB_DEST)/*.a
	
cleandi:
	cd DerelictUtil  && $(RMR) $(IMPORT_DEST)/derelict
	
