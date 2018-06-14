#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Missing GO Terms in Ontology Mart DB"

sql="SELECT DISTINCT t.dbprimary_acc_1074 FROM (SELECT DISTINCT dbprimary_acc_1074 FROM ${DBMARTNAME}.spombe_eg_gene__ontology_go__dm WHERE dbprimary_acc_1074 IS NOT NULL) t LEFT JOIN ${DBNAMEMART}.closure_GO__closure__main main ON (main.accession_305_r1 = t.dbprimary_acc_1074) WHERE main.accession_305_r1 IS NULL;"
sqlCount="SELECT COUNT(DISTINCT t.dbprimary_acc_1074) FROM (SELECT DISTINCT dbprimary_acc_1074 FROM ${DBMARTNAME}.spombe_eg_gene__ontology_go__dm WHERE dbprimary_acc_1074 IS NOT NULL) t LEFT JOIN ${DBNAMEMART}.closure_GO__closure__main main ON (main.accession_305_r1 = t.dbprimary_acc_1074) WHERE main.accession_305_r1 IS NULL;"

c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "${sql}"`

if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo "  There are missing terms in the ${DBNAMEMART} db for GO, so probably affecting all ontologies."
  echo "  Check the loading of the ontology mart database."
  echo ""
  echo "  RESULTS"
  echo "  ${sqlCount}"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "${sqlCount}"
  echo ""
  echo "  REASON"
  echo "  Terms missing in the ontology mart db caused INNER JOIN and the term not in a defined subset. LEFT JOINS are required."
else
  echo "PASSED"
fi
