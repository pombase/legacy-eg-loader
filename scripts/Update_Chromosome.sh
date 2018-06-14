#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

perl --version
cd ..
perl misc_scripts/Update_Annotation.pl -chr $LSB_JOBINDEX -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME -track 1
