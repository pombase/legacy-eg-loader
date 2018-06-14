#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Compare annotations between releases ..."

if [ "$1" = "chado" ]
then
  echo "    - Chado"
  echo "      - feature_relationship"
  psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT DISTINCT frt.name FROM feature_relationship fr JOIN cvterm frt ON (fr.type_id=frt.cvterm_id);" | while read dbx
  do
    old=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT COUNT(fr.type_id) FROM feature_relationship fr JOIN cvterm frt ON (fr.type_id=frt.cvterm_id) WHERE frt.name='${dbx}';")
    new=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "SELECT COUNT(fr.type_id) FROM feature_relationship fr JOIN cvterm frt ON (fr.type_id=frt.cvterm_id) WHERE frt.name='${dbx}';")
    
    #echo "${dbx}: ${old} ==> ${new}"
    
    if [ "$old" -gt "$new" ]
    then
      z=$((old / new))
      
      if [ "$z" -gt "5" ]
      then
        echo "WARNING: Significant reduction in ${dbx} annotations from ${old} ==> ${new}"
      fi
    fi
  done
  
  echo "      - feature_cvterm"
  psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT DISTINCT fccv.name FROM feature_cvterm fc JOIN cvterm fcc ON (fc.cvterm_id=fcc.cvterm_id) JOIN cv fccv ON (fcc.cv_id=fccv.cv_id)" | while read dbx
  do
    old=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT COUNT(fc.feature_cvterm_id) FROM feature_cvterm fc JOIN cvterm fcc ON (fc.cvterm_id=fcc.cvterm_id) JOIN cv fccv ON (fcc.cv_id=fccv.cv_id) WHERE fccv.name='${dbx}';")
    new=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "SELECT COUNT(fc.feature_cvterm_id) FROM feature_cvterm fc JOIN cvterm fcc ON (fc.cvterm_id=fcc.cvterm_id) JOIN cv fccv ON (fcc.cv_id=fccv.cv_id) WHERE fccv.name='${dbx}';")
    
    #echo "${dbx}: ${old} ==> ${new}"
    
    if [ "$old" -gt "$new" ]
    then
      z=$((old / new))
      
      if [ "$z" -gt "5" ]
      then
        echo "WARNING: Significant reduction in ${dbx} annotations from ${old} ==> ${new}"
      fi
    fi
  done
  
  echo "      - feature_dbxref"
  psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT DISTINCT fxxd.name FROM feature_dbxref fx JOIN dbxref fxx ON (fx.dbxref_id=fxx.dbxref_id) JOIN db fxxd ON (fxx.db_id=fxxd.db_id)" | while read dbx
  do
    old=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAMEOLD -t -A -c "SELECT COUNT(fx.feature_dbxref_id) FROM feature_dbxref fx JOIN dbxref fxx ON (fx.dbxref_id=fxx.dbxref_id) JOIN db fxxd ON (fxx.db_id=fxxd.db_id) WHERE fxxd.name='${dbx}';")
    new=$(psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "SELECT COUNT(fx.feature_dbxref_id) FROM feature_dbxref fx JOIN dbxref fxx ON (fx.dbxref_id=fxx.dbxref_id) JOIN db fxxd ON (fxx.db_id=fxxd.db_id) WHERE fxxd.name='${dbx}';")
    
    #echo "${dbx}: ${old} ==> ${new}"
    
    if [ "$old" -gt "$new" ]
    then
      z=$((old / new))
      
      if [ "$z" -gt "5" ]
      then
        echo "WARNING: Significant reduction in ${dbx} annotations from ${old} ==> ${new}"
      fi
    fi
  done
fi

if [ "$1" = "ensembl" ]
then
  echo "    - Ensembl"
  mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -s -N -e "SELECT DISTINCT external_db.db_name FROM object_xref, xref, external_db WHERE object_xref.xref_id=xref.xref_id AND xref.external_db_id=external_db.external_db_id;" | while read dbx
  do
    old=$(mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -s -N -e "SELECT COUNT(DISTINCT object_xref.object_xref_id) FROM object_xref, xref, external_db WHERE object_xref.xref_id=xref.xref_id AND xref.external_db_id=external_db.external_db_id AND external_db.db_name=\"$dbx\";")
    new=$(mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "SELECT COUNT(DISTINCT object_xref.object_xref_id) FROM object_xref, xref, external_db WHERE object_xref.xref_id=xref.xref_id AND xref.external_db_id=external_db.external_db_id AND external_db.db_name=\"$dbx\";")
    
    #echo "${dbx}: ${old} ==> ${new}"
    
    if [ "$old" -gt "$new" ]
    then
      z=$((old / new))
      
      if [ "$z" -gt "5" ]
      then
        echo "WARNING: Significant reduction in ${dbx} annotations from ${old} ==> ${new}"
      fi
    fi
  done
fi
