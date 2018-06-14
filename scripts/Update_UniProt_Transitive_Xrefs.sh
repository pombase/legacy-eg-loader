#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd $EG_DIR/eg-pipelines
perl -I modules scripts/xrefs_pipeline/load_uniprot_transitive_xrefs.pl -host $DBHOST -port $DBPORT -user $DBUSER -pass $DBPASS -dbname $DBCORENAME -uniprotdriver Oracle -uniprothost $DBORACLESPHOST -uniprotport $DBORACLESPPORT -uniprotuser $DBORACLESPUSER -uniprotpass $DBORACLESPPASS -uniprotdbname $DBORACLESPSID -dbnames PDB -dbnames EMBL -dbnames ArrayExpress
