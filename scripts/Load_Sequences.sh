#!/bin/bash --

. /nfs/panda/ensemblgenomes/perl/perlbrew/etc/bashrc_eg

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

perl --version

cd ..

perl misc_scripts/ChromosomeLoader.pl -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME

cd ${EG_DIR}

echo "Loading INSDC accessions ..."
cd eg-ena
perl -I modules/ misc-scripts/genome_collections/find_accessions_for_db_toplevel.pl -host $DBHOST -port $DBPORT -user $DBUSER -pass $DBPASS -dbname $DBCORENAME -esauser $DBORACLEESAUSER -esapass $DBORACLEESAPASS -esahost $DBORACLEESAHOST -esaport $DBORACLEESAPORT -esadbname $DBORACLEESASID -esadriver Oracle

