#!/bin/bash --

# Set the required variables.
MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/chado
cd data/chado

# Get the dump from the remote server and extract
wget "http://curation.pombase.org/dumps/releases/pombase-chado-v$PB_VERSION-$PB_RELEASE.dump.gz"
gunzip pombase-chado-v$PB_VERSION-$PB_RELEASE.dump.gz

# Create the new database
psql --host="postgres-eg-pombe.ebi.ac.uk" --username="ensrw" --dbname="test" -c "CREATE DATABASE pombase_chado_v$PB_VERSION"

# Load the new database
psql --host="postgres-eg-pombe.ebi.ac.uk" --username="ensrw" --dbname="pombase_chado_v$PB_VERSION" -f "pombase-chado-v$PB_VERSION-$PB_RELEASE.dump"

echo "--> Database Loaded!"

python ../../misc_scripts/CompareCoords.py --new_chado_dbname pombase_chado_v$PB_VERSION --old_chado_dbname pombase_chado_v$(($PB_VERSION-1)) --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD
