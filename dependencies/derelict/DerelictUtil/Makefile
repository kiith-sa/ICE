include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/util
UTIL_LIB=$(LIB_PRE)DerelictUtil.$(LIB_EXT)

all : DerelictUtil
DerelictUtil : $(UTIL_LIB) copylib

UTIL_SRC= \
    derelict/util/compat.d \
    derelict/util/exception.d \
    derelict/util/loader.d \
    derelict/util/sharedlib.d \
    derelict/util/wintypes.d \
    derelict/util/xtypes.d

$(UTIL_LIB): $(DC)_build

dmd_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(UTIL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(UTIL_LIB)
	
ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(UTIL_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(UTIL_LIB) *.o
	$(RM) *.o
	
gdmd_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(UTIL_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(UTIL_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

