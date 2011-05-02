include ../inc/$(PLATFORM)_inc.mak
include ../inc/$(DC)_inc.mak

PACKAGE_PATH=derelict/ode
ODE_LIB=$(LIB_PRE)DerelictODE.$(LIB_EXT)

all : DerelictODE
DerelictODE : $(ODE_LIB) copylib

ODE_SRC= \
    derelict/ode/ode.d \
    derelict/ode/odefuncs.d \
    derelict/ode/odetypes.d   

$(ODE_LIB) : $(DC)_build
    
dmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(ODE_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(ODE_LIB)

ldc_build:
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(ODE_SRC) $(HD)/$(PACKAGE_PATH)
	ar rcs $(ODE_LIB) *.o
	$(RM) *.o
	
gdmd_build :
	$(DC) $(DFLAGS) $(DFLAGS_REQ) $(ODE_SRC) $(HD)/$(PACKAGE_PATH) $(OF)$(ODE_LIB)
	
copylib:		
	$(CP) *.$(LIB_EXT) $(LIB_DEST)
	$(RM) *.$(LIB_EXT)

