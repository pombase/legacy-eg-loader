#!/bin/sh

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv
mkdir -p ../data/sql/compara

echo "/pub/release-${EG_RELEASE}/${DB_DIVISION}/mysql/ensembl_compara_${DB_DIVISION}_${EG_RELEASE}_${ENSEMBL_RELEASE}"

cd ../data/sql/compara
ftp -i ftp.ensemblgenomes.org <<SCRIPT
cd /pub/release-${EG_RELEASE}/${DB_DIVISION}/mysql/ensembl_compara_${DB_DIVISION}_${EG_RELEASE}_${ENSEMBL_RELEASE}
mget *
bye
SCRIPT

gunzip ${DBCOMPARANAME}.sql.gz

# Create the database
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "drop database ${DBCOMPARANAME}"
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "create database ${DBCOMPARANAME}"
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCOMPARANAME < ${DBCOMPARANAME}.sql

gzip ${DBCOMPARANAME}.sql

ls *.txt.gz | while read f; do echo "Loading ${f}"; gunzip $f; g=$(echo $f | sed s/.gz//); mysqlimport --local $(${DBPOMBECMD} details mysql) ensembl_compara_${DB_DIVISION}_${EG_RELEASE}_${ENSEMBL_RELEASE} ${g}; gzip $g; done
