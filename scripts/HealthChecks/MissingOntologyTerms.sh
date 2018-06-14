#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Missing GO, FYPO, MOD and SO Terms Ontology DB"

testsFailed=0
for o in GO FYPO MOD PBO SO
do
  echo "Checking ${o} ..."
  sql="select count(u.dbprimary_acc) from (select distinct external_db.db_name, xref.dbprimary_acc from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name='${o}') u left join (select o.name, t.accession from ${DBNAME}.term t join ${DBNAME}.ontology o on (t.ontology_id=o.ontology_id) where o.name='${o}') t on (u.db_name=t.name and u.dbprimary_acc=t.accession) where t.accession is NULL;"
  #echo $sql
  c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "${sql}"`
  
  if [ ${c} -gt 0 ]
  then
    echo "  FAILED: ${c}"
    testsFailed=`expr $testsFailed + 1`
  else
    echo "  PASSED"
  fi
done

sqlCount="select u.db_name, count(u.dbprimary_acc) from (select distinct external_db.db_name, xref.dbprimary_acc from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name in ('GO', 'FYPO', 'MOD', 'PBO', 'SO')) u left join (select o.name, t.accession from ${DBNAME}.term t join ${DBNAME}.ontology o on (t.ontology_id=o.ontology_id) where o.name in ('GO', 'FYPO', 'MOD', 'PBO', 'SO')) t on (u.db_name=t.name and u.dbprimary_acc=t.accession) where t.accession is NULL group by u.db_name;"

echo ""
echo "================================================================================"
echo ""
if [ $testsFailed -gt 0 ]
then
  echo "  FAILED"
  echo "  There are missing terms from one or more of the following ontologies: GO, FYPO, MOD, SO"
  echo "  Check the loading of the ontology database."
  echo ""
  echo "  RESULTS"
  echo "  ${sqlCount}"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "${sqlCount}"
  echo ""
  echo "  REASON"
  echo "  Terms missing in the ontology db cause blanks to be present on the gene pages."
else
  echo "  PASSED"
fi
