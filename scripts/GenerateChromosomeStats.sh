#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/FTP

perl misc_scripts/ChromosomeStats.pl -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -date $CHADODATE -eg_version $EG_RELEASE -e_version $ENSEMBL_RELEASE
