#!/bin/bash --

. /nfs/panda/ensemblgenomes/perl/perlbrew/etc/bashrc_eg

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

#perl --version
cd ..

#LSB_JOBINDEX=2
perl misc_scripts/GeneLoader.pl -chr $LSB_JOBINDEX -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME

