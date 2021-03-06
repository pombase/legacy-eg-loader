#!/bin/bash --

. /nfs/panda/ensemblgenomes/perl/perlbrew/etc/bashrc_eg

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

perl --version

# echo $DBPERLNAME
#LSB_JOBINDEX=1

cd ..
# perl scripts/GenerateGeneModels.pl -chr $LSB_JOBINDEX -db $DBPERLNAME
genes=$(sed -n ${LSB_JOBINDEX}p data/tmp/batch_Gene_Dump.csv)
perl misc_scripts/GenerateGeneModels.pl -job ${LSB_JOBINDEX} -gene $genes -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -eg_dbontology $DBNAME
#perl misc_scripts/GenerateFinalGeneModels.pl -job ${LSB_JOBINDEX} -gene $genes -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME -eg_dbontology $DBNAME
