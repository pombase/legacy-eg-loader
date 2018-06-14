#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..

mkdir -p data/sql/dbs_new
mkdir -p data/sql/dbs_old

DBTOTRANSFER=$DBCORENAME
echo "Creating backup of ${DBTOTRANSFER} from $DBPOMBEHOST ..."
mysqldump -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_old/${DBTOTRANSFER}.sql.gz
echo "Dumping ${DBTOTRANSFER} from $DBHOST ..."
mysqldump -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_new/${DBTOTRANSFER}.sql.gz

#echo "Transfering ${DBTOTRANSFER} to $DBPOMBEHOST ..."
#gunzip < data/sql/dbs_new/${DBTOTRANSFER}.sql.gz | mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER}


#DBTOTRANSFER=$DBMARTNAME
#echo "Creating backup of ${DBTOTRANSFER} from $DBPOMBEHOST ..."
#mysqldump -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_old/${DBTOTRANSFER}.sql.gz
#echo "Dumping ${DBTOTRANSFER} from $DBHOST ..."
#mysqldump -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_new/${DBTOTRANSFER}.sql.gz

#echo "Transfering ${DBTOTRANSFER} to $DBPOMBEHOST ..."
#gunzip < data/sql/dbs_new/${DBTOTRANSFER}.sql.gz | mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER}


DBTOTRANSFER=$DBNAME
echo "Creating backup of ${DBTOTRANSFER} from $DBPOMBEHOST ..."
mysqldump -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_old/${DBTOTRANSFER}.sql.gz
echo "Dumping ${DBTOTRANSFER} from $DBHOST ..."
mysqldump -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_new/${DBTOTRANSFER}.sql.gz

#echo "Transfering ${DBTOTRANSFER} to $DBPOMBEHOST ..."
#gunzip < data/sql/dbs_new/${DBTOTRANSFER}.sql.gz | mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER}


#DBTOTRANSFER=$DBNAMEMART
#echo "Creating backup of ${DBTOTRANSFER} from $DBPOMBEHOST ..."
#mysqldump -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_old/${DBTOTRANSFER}.sql.gz
#echo "Dumping ${DBTOTRANSFER} from $DBHOST ..."
#mysqldump -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${DBTOTRANSFER} | gzip > data/sql/dbs_new/${DBTOTRANSFER}.sql.gz

#echo "Transfering ${DBTOTRANSFER} to $DBPOMBEHOST ..."
#gunzip < data/sql/dbs_new/${DBTOTRANSFER}.sql.gz | mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT ${DBTOTRANSFER}

