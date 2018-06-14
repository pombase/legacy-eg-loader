#!/bin/sh

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv
mkdir -p ../data/sql/pan_compara

echo "/pub/release-${EG_RELEASE}/pan_ensembl/mysql/ensembl_compara_pan_homology_${EG_RELEASE}_${ENSEMBL_RELEASE}"

cd ../data/sql/pan_compara
#ftp -i ftp.ensemblgenomes.org <<SCRIPT
#cd /pub/release-${EG_RELEASE}/pan_ensembl/mysql/ensembl_compara_pan_homology_${EG_RELEASE}_${ENSEMBL_RELEASE}
#mget *
#bye
#SCRIPT

gunzip ${DBPANNAME}.sql.gz

# Create the database
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "drop database ${DBPANNAME}"
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "create database ${DBPANNAME}"
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBPANNAME} < ${DBPANNAME}.sql

gzip ${DBPANNAME}.sql

ls *.txt.gz | while read f; do echo "Loading ${f}"; gunzip $f; g=$(echo $f | sed s/.gz//); mysqlimport --local $(${DBPOMBECMD} details mysql) ${DBPANNAME}  ${g}; gzip $g; done
