#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/tmp

echo "Dropping any pre-existing tracker tables in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "DROP TABLE IF EXISTS tmp_tracker;"

echo "Creating tracker table in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "CREATE TABLE IF NOT EXISTS tmp_tracker SELECT stable_id, 'READY' status FROM gene;"

echo "Creating batch list ..."
mysql -N -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "SET SESSION group_concat_max_len = 4056; SELECT GROUP_CONCAT(stable_id SEPARATOR ',') FROM (SELECT stable_id, (FLOOR( 1 + RAND( ) * 50 )) AS set_id FROM gene) AS t GROUP BY set_id;" > ../data/tmp/batch_GeneLoad.csv

echo "Submission time: $(date)"
bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "upChrPombe[1-50]%50" "sh Update_Genes.sh"
#bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "upChrPombe[1-50]%1" "sh Update_Genes.sh"

REMAINING=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT count(*) FROM tmp_tracker WHERE status!='COMPL';")
BJ=$(bjobs | wc -l)
while [ $REMAINING -gt 0 ]
do
  sleep 2
  REMAINING=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT count(*) FROM tmp_tracker WHERE status!='COMPL';")
  PROGRESS=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT FLOOR((cc.c/tt.t)*100/2)+1 FROM (SELECT count(*) c FROM tmp_tracker WHERE status='COMPL') cc, (SELECT count(*) t FROM tmp_tracker) tt;")
  GLEFT=$(expr 51 - $PROGRESS)
  
  PBARL=$( seq -s= $PROGRESS|tr -d '[:digit:]' )
  PBARR=$( seq -s= $GLEFT|tr -d '[:digit:]' )
  echo -ne \\r "$PBARL|$PBARR Genes Left: $REMAINING"
done

echo ""
echo "Genes Loaded."

#echo "Dropping tracker table in ${DBCORENAME}"
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "DROP TABLE tmp_tracker;"

echo "Completion time: $(date)"

