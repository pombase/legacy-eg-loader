#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/sql

#echo "Generating ontology update file data/sql/update_ontology.sql"
#python UpdateOntologyDescriptions.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --dbhost $DBHOST --dbport $DBPORT

#echo "Applying updates to ${DBCORENAME}"
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME < data/sql/update_ontology.sql

echo "Clearing required entries in xref table except for PubMeds from ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "delete xref.* from xref, external_db where xref.external_db_id=external_db.external_db_id and external_db.db_name in ('GO', 'GO_REF', 'FYPO', 'FYPO_EXT', 'PBQ', 'PATO', 'MOD', 'PomBase_GO_AnnotationExtensions', 'PBO', 'SO', 'PomBase_ORTHOLOG', 'PomBase', 'PomBase_Interaction_GENETIC', 'PomBase_Interaction_PHYSICAL');"

echo "Deleteing rows from object_xref table in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "delete object_xref.* from object_xref left join xref on (object_xref.xref_id=xref.xref_id) where xref.xref_id IS NULL;"

echo "Deleting rows from ontology_xref table in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "delete ontology_xref.* from ontology_xref left join object_xref on (ontology_xref.object_xref_id=object_xref.object_xref_id) where object_xref.object_xref_id IS NULL;"

echo "Deleting rows from dependent_xref table in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "delete dependent_xref.* from dependent_xref left join object_xref on (dependent_xref.object_xref_id=object_xref.object_xref_id) where object_xref.object_xref_id IS NULL;"

echo "Truncating associated_N tables in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "TRUNCATE TABLE associated_xref;"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "TRUNCATE TABLE associated_group;"

echo "Truncating external_synonym table in ${DBCORENAME}"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "TRUNCATE TABLE external_synonym;"

echo "${DBCORENAME} ready to be updated!"
