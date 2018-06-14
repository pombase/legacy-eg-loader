#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
mkdir -p ../data/tmp
mkdir -p ../data/caches

echo "Creating batch list ..."
mysql -N -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "SET SESSION group_concat_max_len = 4056; SELECT GROUP_CONCAT(stable_id SEPARATOR ',') FROM (SELECT sid.stable_id, CEILING((@curRow := @curRow + 1)/3) AS row_number FROM (SELECT stable_id, (FLOOR( 1 + RAND( ) * (SELECT COUNT(*) FROM gene)/3 )) AS set_id FROM gene ORDER BY set_id) sid JOIN (SELECT @curRow := 0) r) bid GROUP BY bid.row_number;" > ../data/tmp/batch_Gene_Dump.csv
job_count=$(wc -l < ../data/tmp/batch_Gene_Dump.csv)

echo "Submission time: $(date)"
bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "dmpGenePom[1-${job_count}]%50" "sh DumpJSONCacheRunner.sh"

