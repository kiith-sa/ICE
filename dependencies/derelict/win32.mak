include inc\win32_inc.mak

all : DerelictAL_ALL DerelictFMODEX_ALL DerelictFT_ALL DerelictGL_ALL DerelictIL_ALL DerelictODE_ALL DerelictOgg_ALL DerelictPA_ALL DerelictSDL_ALL DerelictSFML_ALL DerelictUtil_ALL

# Targets for all libs in each package
DerelictAL_ALL :
	cd DerelictAL
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictFMODEX_ALL:
	cd DerelictFMOD
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
		
DerelictFT_ALL :
	cd DerelictFT
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
		
DerelictGL_ALL :
	cd DerelictGL
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictIL_ALL :
	cd DerelictIL
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..	
	
DerelictODE_ALL :
	cd DerelictODE
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictOgg_ALL:
	cd DerelictOgg
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..

DerelictPA_ALL:
	cd DerelictPA
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSDL_ALL :
	cd DerelictSDL
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..

DerelictSFML_ALL :
	cd DerelictSFML
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictUtil_ALL :
	cd DerelictUtil
	$(DMAKE) all PLATFORM=win32 DC=$(DC)
	cd ..
	
# There's only one DerelictAL target
DerelictAL : DerelictAL_ALL

# There's only one DerelictFMODEX target
DerelictFMODEX : DerelictFMODEX_ALL

# There's only one DerelictFT target
DerelictFT : DerelictFT_ALL
	
# Individual DerelictGL targets
DerelictGL :
	cd DerelictGL
	$(DMAKE) DerelictGL PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictGLU :
	cd DerelictGL
	$(DMAKE) DerelictGLU PLATFORM=win32 DC=$(DC)
	cd ..	
	
# Individual DerelictIL targets
DerelictIL :
	cd DerelictIL
	$(DMAKE) DerelictIL PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictILU :
	cd DerelictIL
	$(DMAKE) DerelictILU PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictILUT :
	cd DerelictIL
	$(DMAKE) DerelictILUT PLATFORM=win32 DC=$(DC)
	cd ..	
	
# There's only one DerelictODE target
DerelictODE : DerelictODE_ALL
	
# Individual DerelictOgg targets
DerelictOgg :
	cd DerelictOgg
	$(DMAKE) DerelictOgg PLATFORM=win32 DC=$(DC)
	cd ..
	
# There's only one DerelictPA target
DerelictPA : DerelictPA_ALL
	
DerelictVorbis :
	cd DerelictOgg
	$(DMAKE) DerelictVorbis PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictVorbisEnc :
	cd DerelictOgg
	$(DMAKE) DerelictVorbisEnc PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictVorbisFile :
	cd DerelictOgg
	$(DMAKE) DerelictVorbisFile PLATFORM=win32 DC=$(DC)
	cd ..
	
# Individual DerelictSDL targets
DerelictSDL :
	cd DerelictSDL
	$(DMAKE) DerelictSDL PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSDLImage :
	cd DerelictSDL
	$(DMAKE) DerelictSDLImage PLATFORM=win32 DC=$(DC)
	cd ..

DerelictSDLMixer :
	cd DerelictSDL
	$(DMAKE) DerelictSDLMixer PLATFORM=win32 DC=$(DC)
	cd ..

DerelictSDLNet :
	cd DerelictSDL
	$(DMAKE) DerelictSDLNet PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSDLttf :
	cd DerelictSDL
	$(DMAKE) DerelictSDLttf PLATFORM=win32 DC=$(DC)
	cd ..
	
# Individual DerelictSFML targets
DerelictSFMLWindow :
	cd DerelictSFML
	$(DMAKE) DerelictSFMLWindow PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSFMLSystem :
	cd DerelictSFML
	$(DMAKE) DerelictSFMLSystem PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSFMLGraphics :
	cd DerelictSFML
	$(DMAKE) DerelictSFMLGraphics PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSFMLAudio :
	cd DerelictSFML
	$(DMAKE) DerelictSFMLAudio PLATFORM=win32 DC=$(DC)
	cd ..
	
DerelictSFMLNetwork :
	cd DerelictSFML
	$(DMAKE) DerelictSFMLNetwork PLATFORM=win32 DC=$(DC)
	cd ..
	
# There's only one DerelictUtil target
DerelictUtil : DerelictUtil_All
	
cleanall : cleanlib cleandi

clean : cleanlib

cleanlib :
	cd DerelictUtil
	$(RM) $(LIB_DEST)\*.lib
	cd ..
	
cleandi:
	cd DerelictUtil
	$(RMR) $(IMPORT_DEST)\*.di
	cd ..
	