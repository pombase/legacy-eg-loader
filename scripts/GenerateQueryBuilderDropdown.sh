#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/FTP

python misc_scripts/GenerateBioMartDropDowns.py --division=$DIVISION --eg_release=$EG_RELEASE --chado_release=$PB_VERSION --dbhost=$DBHOST --dbport=$DBPORT --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser=$DBPGUSER --dbchadopass=$PGPASSWORD --file=data/FTP/biomart_extension_cache.tsv

cd data/FTP
gzip biomart_extension_cache.tsv
