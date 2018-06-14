#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that annotated ontology terms, ensure that the term prefix matches the external_db db_name column. This is to ensure that PBO/PomBase is not used as a prefix when importing the annotation extension terms that have come from a merge custom term. The health check covers the GO, FYPO, MOD, PBO and SO ontologies."
c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select external_db.db_name, SUBSTRING(xref.dbprimary_acc, 1, LOCATE(':', xref.dbprimary_acc)-1) acc, SUBSTRING(xref.display_label, 1, LOCATE(':', xref.display_label)-1) disp, count(*) from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name in ('GO', 'PBO', 'MOD', 'SO', 'FYPO') group by db_name, acc, disp having acc!=db_name or disp!=db_name;"`
if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo $c
  echo "  Fix the loading code."
else
  echo "PASSED"
fi
