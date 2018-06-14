#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
perl misc_scripts/Import_UniParc.pl -osid $DBORACLESID -ohost $DBORACLEHOST -oport $DBORACLEPORT -ouser $DBORACLEUSER -opass $DBORACLEPASS -ehost $DBHOST -eport $DBPORT -euser $DBUSER -epass $DBPASS -division $DIVISION -species $SPECIES -dbname $DBCORENAME
