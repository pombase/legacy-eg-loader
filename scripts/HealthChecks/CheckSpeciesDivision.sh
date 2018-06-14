#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that species.division in the meta table for cores is set to 'PomBase'."

for sp in schizosaccharomyces_cryophilus schizosaccharomyces_japonicus schizosaccharomyces_octosporus schizosaccharomyces_pombe
do
  DBCORENAME="${sp}_core_${EG_RELEASE}_${ENSEMBL_RELEASE}_${ASSEMBLY}"
  c=`mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -s -N -e "select count(*) from meta where meta_key='species.division' and meta_value!='PomBase';"`
  if [ $c -gt 0 ]
  then
    echo "  # FAILED: ${sp}"
    echo "  # Update species.division in the meta table to 'PomBase'"
    echo "  update ${DBCORENAME}.meta set meta_value='PomBase' where meta_key='species.division';" 
  else
    echo "# PASSED: ${sp}"
  fi
done

