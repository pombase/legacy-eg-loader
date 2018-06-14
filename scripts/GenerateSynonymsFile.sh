#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT gene.stable_id, external_synonym.synonym FROM gene, external_synonym WHERE gene.display_xref_id=external_synonym.xref_id;" > ensembl_synonym_cache.tsv

gzip ensembl_synonym_cache.tsv
