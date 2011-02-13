#! /bin/bash
mkdir -p doc/ddoc/

FILES=`find . \( -name 'dependencies*' -prune \) -o -name '*.d' `

dil ddoc doc/ddoc $FILES -v --kandil -hl -i
