#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/ontology

perl misc_scripts/GenerateOBO.pl -obo $1 -file data/ontology/$1.obo -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME 
