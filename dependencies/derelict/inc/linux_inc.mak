######################################################################
# Configurable Options
######################################################################
# Change this if you want the libraries output to a different location.
LIB_DEST=../lib

# Change this if you want the .di files output to a different location.
IMPORT_DEST=../import

######################################################################
# The following are used to enable a common build interface across platforms.
# They aren't intended to be modified. Doing so can easliy break the build.
######################################################################
CP=cp -f
RM=rm -f
RMR=rm -rf
LIB_EXT=a
LIB_PRE=lib
DMAKE=make
