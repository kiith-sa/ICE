######################################################################
# Configurable Options
######################################################################
# Change this to control the generated code. It should not be used to control output paths.
DFLAGS=-release -O -inline

######################################################################
# The following are used to enable a common build interface across platforms.
# They aren't intended to be modified. Doing so can easliy break the build.
######################################################################
OF=-of
VER=-d-version=
HD=-Hd\$(IMPORT_DEST)
DFLAGS_REQ=-c -I../DerelictUtil

