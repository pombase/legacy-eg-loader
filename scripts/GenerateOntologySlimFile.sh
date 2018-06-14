#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

echo "Generating the OntologyClimCache.tsv file for GO slims"

c1=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -s -N -e "SHOW TABLES;"`

mkdir -p ../data/FTP
cd ../data/FTP
touch OntologySlimCache.tsv

for o in ${c1}
do
  if [[ ${o} == aux_GO_goslim_pombe_map ]]
  then
    echo "  Selecting terms from ${o}"
    mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -s -N -e "SELECT DISTINCT '${o}', term.accession FROM ${o} JOIN term on (${o}.subset_term_id=term.term_id);" >> OntologySlimCache.tsv
  fi
done
