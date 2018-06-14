#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv
cd ../../

echo "HC: Ensure that all orthologues present in Chado are present in the esnembl db"
c=$(python misc_scripts/CheckOrthologAnnotations.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --dbhost $DBHOST --dbport $DBPORT --dbuser $DBUSER --dbpass $DBPASS --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD --chado_release $PB_VERSION)

if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo ${c}
else
  echo "PASSED"
fi
