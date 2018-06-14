#!/bin/bash --

# Set the required variables.
MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

echo "python ../misc_scripts/CompareCoords.py --new_chado_dbname pombase_chado_v$PB_VERSION --old_chado_dbname pombase_chado_v$((PB_VERSION-1)) --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD"
