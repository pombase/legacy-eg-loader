#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
echo "perl misc_scripts/Test_$1.pl -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME"
perl misc_scripts/Test_$1.pl -pg_host $DBPGHOST -pg_port $DBPGPORT -pg_user $DBPGUSER -pg_pass $PGPASSWORD -pg_dbname $DBPGNAME 
