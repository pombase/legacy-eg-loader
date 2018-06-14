#!/bin/bash --

if [ "$HOSTNAME" != "gunpowder.ebi.ac.uk" ]
then
  echo "WARNING: You need to be on gunpowder"
  exit 10
fi

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

. /nfs/public/rw/ensembl/perlbrew/setup_gunpowder_perl.sh

alias perl=''
unalias perl
 
export JAVA_HOME=/sw/arch/pkg/jdk1.6
export PATH=/usr/local/bin:$JAVA_HOME/bin:$PATH
 
cd ..
mkdir -p data/search

SEARCH_DIR=$(cd $(dirname "$0"); pwd)/data/search

cd $EG_DIR/eg-web-common/utils

perl search_dump_pombase.pl -release $EG_RELEASE -index Gene -nogzip -host $DBPOMBEHOST -user ensro -port $DBPOMBEPORT -species $SPECIES2 -dir $SEARCH_DIR -noortholog 1

cd $SEARCH_DIR
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/nfs/ensembl/xerces-c-3.1.1/lib
find . -name '*xml' | xargs -I{} /nfs/ensembl/xerces-c-3.1.1/bin/SAX2Count -v=never {}

gzip Gene_Schizosaccharomyces_pombe_core.xml

echo "Generating release_note.txt file ..."
eg_search_entries=$(zgrep '<entry id=' Gene_* | wc -l)

rm release_note.txt
echo "release=$EG_RELEASE" > release_note.txt
echo "release_date=$SEACHDUMP_RELEASE" >> release_note.txt
echo "entries=$eg_search_entries" >> release_note.txt

