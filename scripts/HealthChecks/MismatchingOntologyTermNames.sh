#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check GO, FYPO, MOD and SO term names match between the core and ontology db"

testsFailed=0
for o in GO FYPO MOD PBO SO
do
  echo "Checking ${o} ..."
  sql="select count(*) from (select distinct u.dbprimary_acc accession, u.description core_name, t.acc_name ontology_name, u.description=t.acc_name matching from (select distinct external_db.db_name, xref.dbprimary_acc, xref.description from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name='${o}') u join (select o.name, t.accession, t.name as acc_name from ${DBNAME}.term t join ${DBNAME}.ontology o on (t.ontology_id=o.ontology_id) where o.name='${o}') t on (u.dbprimary_acc=t.accession) having matching = 0) v;"
  c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "${sql}"`
  
  if [ ${c} -gt 0 ]
  then
    echo "  FAILED: ${c}"
    testsFailed=`expr $testsFailed + 1`
  else
    echo "  PASSED"
  fi
done

echo ""
echo "================================================================================"
echo ""

if [ $testsFailed -gt 0 ]
then
  echo "  FAILED"
  echo "  There are GO, FYPO, MOD and/or MOD term names in the ontology database that don't match"
  echo "  Check the loading of the ontology database."
  echo ""
  echo "  Useful SQL:"
  echo "  select distinct u.dbprimary_acc accession, u.description core_name, t.acc_name ontology_name, u.description=t.acc_name matching from (select distinct external_db.db_name, xref.dbprimary_acc, xref.description from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name='<ONTOLOGY_NAME>') u join (select o.name, t.accession, t.name as acc_name from ${DBNAME}.term t join ${DBNAME}.ontology o on (t.ontology_id=o.ontology_id) where o.name='<ONTOLOGY_NAME>') t on (u.dbprimary_acc=t.accession) having matching = 0;"
  echo ""
  echo "  REASON"
  echo "  Terms in the ontology db get used in the query builder and xref.descriptions get used on the gene pages."
else
  echo "PASSED"
fi
