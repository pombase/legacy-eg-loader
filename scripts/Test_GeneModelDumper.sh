#!/bin/bash --

. /nfs/panda/ensemblgenomes/perl/perlbrew/etc/bashrc_eg

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

#perl --version
cd ..

mkdir -p data/caches

# perl scripts/GenerateGeneModels.pl -chr $LSB_JOBINDEX -db $DBPERLNAME
genes=$1
perl misc_scripts/GenerateGeneModels.pl -job 1 -gene $genes -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -eg_dbontology $DBNAME

