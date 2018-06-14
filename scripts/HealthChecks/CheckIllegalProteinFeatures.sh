#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that protein_features does not have any entries relating to Seg."
c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select count(*) from protein_feature join analysis on (protein_feature.analysis_id=analysis.analysis_id) where analysis.logic_name='seg';"`
if [ $c -gt 0 ]
then
  echo "  FAILED"
  echo $c
  echo "  Fix the loading code.   The SQL below can be used as a patch as a last resort."
  echo "  delete protein_feature.* from protein_feature join analysis on (protein_feature.analysis_id=analysis.analysis_id) where analysis.logic_name='seg';" 
else
  echo "PASSED"
fi
