#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that strange UNICODE characters do not exist in the db."
c=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "select count(distinct f.uniquename) from feature f join cvterm ft on (f.type_id=ft.cvterm_id) where f.name like E'%\x05%';"`
if [ $c -gt 0 ]
then
  echo "  FAILED"
  echo "  Raise issue with the curators to fix this in the Chado db before continuing!"
else
  echo "PASSED"
fi
