#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv
cd ../../

echo "HC: Ensure that all interactions present in Chado are present in the ensembl db"

echo "python misc_scripts/CompareInteractions.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --chado_release $PB_VERSION --dbhost $DBHOST --dbport $DBPORT --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD"

if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo ${c}
else
  echo "PASSED"
fi
