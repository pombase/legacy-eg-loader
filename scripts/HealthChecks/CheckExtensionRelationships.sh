#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that PomBase annotation extensions have a matching is_a relationship."
c1=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "select count(distinct fc.feature_cvterm_id) from feature_cvterm fc join cvterm fcc on (fc.cvterm_id=fcc.cvterm_id) join cv on (fcc.cv_id=cv.cv_id) where cv.name='PomBase annotation extension terms';"`
c2=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "select count(distinct fc.feature_cvterm_id) from feature_cvterm fc join cvterm fcc on (fc.cvterm_id=fcc.cvterm_id) join cv on (fcc.cv_id=cv.cv_id) join cvterm_relationship cr on (fcc.cvterm_id=cr.subject_id) join cvterm crt on (cr.type_id=crt.cvterm_id) where cv.name='PomBase annotation extension terms' and crt.name='is_a';"`

if [ ${c1} -ne ${c2} ]
then
  echo "  FAILED"
  echo "  Raise issue with the curators to fix this in the Chado db before continuing!"
  echo "  There are missing is_a relatioships for PomBase annotation extension terms"
  echo "  feature_cvterm_id:           ${c1}"
  echo "  feature_cvterm_id with is_a: ${c2}"
else
  echo "PASSED"
fi
