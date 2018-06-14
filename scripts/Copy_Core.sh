#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

if [ "$1" = "toDev" ]
then
  echo "To Dev ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "create database $DBCORENAME"
  mysqldump -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME | mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME
elif [ "$1" = "toPombe" ]
then
  echo "To Pombe ..."
  mysqldump -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME | mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME
else
  printf "%s is not a valid option\nPlease one of the following:\n  - toDev\n  - toPombe\n" $1
fi
