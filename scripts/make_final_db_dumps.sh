#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/final_dbs

cd data/final_dbs

${DBPOMBECMD} mysqldump ${DBCORENAME} > ${DBCORENAME}.chado_v${PB_VERSION}.sql
gzip ${DBCORENAME}.chado_v${PB_VERSION}.sql

${DBPOMBECMD} mysqldump ${DBVARIATIONNAME} > ${DBVARIATIONNAME}.chado_v${PB_VERSION}.sql
gzip ${DBVARIATIONNAME}.chado_v${PB_VERSION}.sql
