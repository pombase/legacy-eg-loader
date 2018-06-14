#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that terms have a child equal to themselves in the closure tables of the egontology BioMart."

testsFailed=0
for o in GO FYPO MOD PBO SO
do
  echo "  Checking ${o} ..."
  c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAMEMART -s -N -e "select child.accession_305, child.name_305, parent.accession_305_r1, parent.name_305_r1 from closure_${o}__closure__main parent left join closure_${o}__closure__main child on (parent.accession_305_r1=child.accession_305 and parent.accession_305_r1=child.accession_305_r1) where child.accession_305_r1 is NULL;"`
  if [ ${#c} -gt 0 ]
  then
    testsFailes=`expr $testsFailed + 1`
  fi
done

if [ $testsFailed -gt 0 ]
then
  echo "  FAILED"
  echo $c
  echo "  Fix the loading code for the egontology BioMart."
else
  echo "PASSED"
fi
