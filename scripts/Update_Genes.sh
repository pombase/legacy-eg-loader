#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

perl --version
cd ..
#LSB_JOBINDEX=17
genes=$(sed -n ${LSB_JOBINDEX}p data/tmp/batch_GeneLoad.csv)
perl misc_scripts/Update_Annotation_Genes.pl -gene $genes -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME -track 1
