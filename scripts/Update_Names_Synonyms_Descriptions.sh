#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/sql
cd ..

echo "Matching existing PomBase_Gene_Names with the genes"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "update gene, xref, external_db set gene.display_xref_id=xref.xref_id where gene.stable_id=xref.dbprimary_acc and xref.external_db_id=external_db.external_db_id and external_db.db_name='PomBase_Gene_Name';"

echo "Generating gene name and synonyms update file data/sql/update_gene_names_synonyms.sql"
echo "python misc_scripts/Check_Name_Synonym.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --chado_release $PB_VERSION --dbhost $DBHOST --dbport $DBPORT --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD"

echo "Generating gene description update file data/sql/update_gene_descriptions.sql"
echo "python misc_scripts/Check_Gene_Descriptions.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --chado_release $PB_VERSION --dbhost $DBHOST --dbport $DBPORT --dbchadohost $DBPGHOST --dbchadoport $DBPGPORT --dbchadouser $DBPGUSER --dbchadopass $PGPASSWORD"

echo "Generating gene exon phase update file data/sql/update_gene_exon_phase.sql"
echo "python misc_scripts/UpdateExonPhase.py --species $SPECIES --assembly $ASSEMBLY --eg_release $EG_RELEASE --e_release $ENSEMBL_RELEASE --dbhost $DBHOST --dbport $DBPORT --dbuser $DBUSER --dbpass $DBPASS --file 'data/sql/update_gene_exon_phase.sql'"

#echo "Applying updates to ${DBCORENAME}"
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME < data/sql/update_gene_names_synonyms.sql
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME < data/sql/update_gene_descriptions.sql

