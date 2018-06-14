#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/tmp/pop_prod_tab
tmpfolder="`pwd`/data/tmp/pop_prod_tab"

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "DROP DATABASE IF EXISTS $DBCORENAME;"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "CREATE DATABASE $DBCORENAME;"

cd ${EG_DIR}
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME < "ensembl/sql/table.sql"

perl ensembl-production/scripts/production_database/populate_production_db_tables.pl -h $DBHOST -P $DBPORT -u $DBUSER -p $DBPASS -mh $DBPRODHOST -mP $DBPRODPORT -mu $DBPRODUSER -d ${DBCORENAME} -dp ${tmpfolder} -dB

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "ALTER TABLE gene MODIFY status ENUM('KNOWN','NOVEL','PUTATIVE','PREDICTED','KNOWN_BY_PROJECTION','UNKNOWN','ANNOTATED','published','biological role inferred','conserved unknown','sequence orphan','fission yeast specific family','dubious','transposon','Schizosaccharomyces pombe specific protein, uncharacterized','Schizosaccharomyces specific protein, uncharacterized');"
