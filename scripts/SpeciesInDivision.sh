#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..

python misc_scripts/SpeciesInDivision.py --division $DIVISION --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --dbhost $DBPOMBEHOST --dbport $DBPOMBEPORT --dbuser $DBPOMBEUSER --dbpass $DBPOMBEPASS
