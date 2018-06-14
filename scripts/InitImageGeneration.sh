#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/images/I
mkdir -p ../data/images/II
mkdir -p ../data/images/III
mkdir -p ../data/images/MT
mkdir -p ../data/images/MTR
mkdir -p ../data/images/AB325691

echo "Creating batch list ..."
mysql -N -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "SET SESSION group_concat_max_len = 4096; SELECT GROUP_CONCAT(stable_id SEPARATOR ' ') FROM (SELECT stable_id, (FLOOR( 1 + RAND( ) * 50 )) AS set_id FROM gene) AS t GROUP BY set_id;" > ../data/tmp/batch_GeneImages.csv

echo "Submission time: $(date)"
bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "PB_Images[1-50]%5" "sh GenerateImages.sh"
