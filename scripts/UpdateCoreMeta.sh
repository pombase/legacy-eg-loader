#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

if [ "$1" = "new" ]
then

  echo "Loading the meta table for $DBCORENAME ..."
  echo "  Setting annotation.source = 'PomBase'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES ('1', 'annotation.source', 'PomBase');"
  
  echo "  Setting annotation.release = '${EG_RELEASE}_${PB_VERSION}'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES ('1', 'annotation.release', '${EG_RELEASE}_${PB_VERSION}');"

  echo "  Setting annotation.date    = '$CHADODATE'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'annotation.date', '$CHADODATE');"

  echo "  Setting genebuild.version = 'Chadov${PB_VERSION}'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.version', 'Chadov${PB_VERSION}');";
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.last_geneset_update', '${GENEBUILDDATE}');";
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.start_date', '${GENEBUILDDATE}-PomBase');";

elif [ "$1" = "update" ]
then

  echo "Updating the meta table for $DBCORENAME ..."
  echo "  Setting annotation.release = '${EG_RELEASE}_${PB_VERSION}'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "UPDATE meta SET meta_value='${EG_RELEASE}_${PB_VERSION}' WHERE meta_key='annotation.release';"

  echo "  Setting annotation.date    = '$CHADODATE'"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "UPDATE meta SET meta_value='$CHADODATE' WHERE meta_key='annotation.date';"

else
  printf "%s is not a valid option\nPlease one of the following:\n  - new\n  - update\n" $1
fi


