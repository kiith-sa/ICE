#! /bin/bash
rm -r doc/ddoc/

mkdir -p doc/ddoc/

FILES=`find . \( -name 'dependencies*' -prune \) -o -name '*.d'`

#any arguments are passed to dil - this way we can e.g. generate
#docs for private symbols using ./gen_docs.sh --inc-private
dil ddoc doc/ddoc $FILES -v --kandil -hl -i $@

cp doc/ddoc.css doc/ddoc/css/style.css
