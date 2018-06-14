#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/FTP

perl misc_scripts/FASTA_dump.pl -eg_host $DBHOST -eg_port $DBPORT -eg_user $DBUSER -eg_pass $DBPASS -eg_species $SPECIES -eg_dbname $DBCORENAME

cp data/FTP/pep.fa data/tmp/.
python misc_scripts/Calculate_AA_Ratios.py > data/FTP/aa_composition.tsv

cd data/FTP
gzip *.fa
