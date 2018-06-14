#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ../data/sql/$DBNAME
pwd
echo "Generating the SQL_load.sql file ..."
echo "python ../../../misc_scripts/BuildBioMartSQLLoader.py --host $DBHOST --port $DBPORT --user $DBUSER --pswd $DBPASS --mart $DBNAMEMART"

echo "Creating the database $DBNAMEMART ..."
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "DROP DATABASE IF EXISTS $DBNAMEMART;"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "CREATE DATABASE $DBNAMEMART;"

echo "Loading the database $DBNAMEMART ..."
MY_DIR2=`dirname $0`
source $MY_DIR2/SQL_loader.sql

