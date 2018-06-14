#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that annotation extensions that map to PomBase use valid gene stable IDs before loading."

pg=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "SELECT f1.uniquename, f1.feature_cvterm_id, f1.value, f2.uniquename FROM (SELECT f.uniquename, fcp.value, fc.feature_cvterm_id FROM feature f JOIN feature_cvterm fc ON (f.feature_id=fc.feature_id) JOIN cvterm fcc ON (fc.cvterm_id=fcc.cvterm_id) JOIN dbxref fccx ON (fcc.dbxref_id=fccx.dbxref_id) JOIN db fccd ON (fccx.db_id=fccd.db_id) LEFT JOIN feature_cvtermprop fcp ON (fc.feature_cvterm_id=fcp.feature_cvterm_id) LEFT JOIN cvterm fcpt ON (fcp.type_id=fcpt.cvterm_id) WHERE fcpt.name in ('with') and fcp.value like 'PomBase:%') AS f1 LEFT JOIN feature f2 ON (f1.value='PomBase:' || f2.uniquename) WHERE f2.uniquename IS NULL;"`

if [ ${#pg} -gt 0 ]
then
  echo "  FAILED"
  echo "  ------"
  echo "  Check the with annotions in the Chado database!"
  echo "  These require fixing before loading to the ensembl database."
else
  echo "PASSED"
fi
