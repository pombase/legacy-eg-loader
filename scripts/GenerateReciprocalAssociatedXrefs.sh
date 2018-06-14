#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

# GO relationships
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT DISTINCT g1.stable_id GeneA, x3.display_label, g1.description, x1.dbprimary_acc ontterm, associated_xref.condition_type, x2.dbprimary_acc GeneB, x4.dbprimary_acc, external_db.db_name FROM associated_xref JOIN object_xref ON (object_xref.object_xref_id=associated_xref.object_xref_id) JOIN transcript ON (object_xref.ensembl_id=transcript.transcript_id AND object_xref.ensembl_object_type='Transcript') JOIN gene g1 ON (g1.gene_id=transcript.gene_id) JOIN xref x1 ON (object_xref.xref_id=x1.xref_id) JOIN external_db ON (external_db.external_db_id=x1.external_db_id) JOIN xref x2 ON (associated_xref.xref_id=x2.xref_id) JOIN gene g2 ON (x2.dbprimary_acc=g2.stable_id) JOIN xref x3 ON (g1.display_xref_id=x3.xref_id) JOIN xref x4 ON (associated_xref.source_xref_id=x4.xref_id) WHERE associated_xref.condition_type IN ('has_regulation_target', 'localization_dependent_on', 'requires_direct_regulator', 'requires_regulator', 'assayed_using', 'has_input', 'has_direct_input', 'has_indirect_input') AND external_db.db_name='GO';" > reciprocalAssociatedXrefs.tsv

# FYPO relationships
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT DISTINCT g1.stable_id GeneA, x3.display_label, g1.description, x1.dbprimary_acc ontterm, associated_xref.condition_type, x2.dbprimary_acc GeneB, x4.dbprimary_acc, external_db.db_name FROM associated_xref JOIN object_xref ON (object_xref.object_xref_id=associated_xref.object_xref_id) JOIN transcript ON (object_xref.ensembl_id=transcript.transcript_id AND object_xref.ensembl_object_type='Transcript') JOIN gene g1 ON (g1.gene_id=transcript.gene_id) JOIN xref x1 ON (object_xref.xref_id=x1.xref_id) JOIN external_db ON (external_db.external_db_id=x1.external_db_id) JOIN xref x2 ON (associated_xref.xref_id=x2.xref_id) JOIN gene g2 ON (x2.dbprimary_acc=g2.stable_id) JOIN xref x3 ON (g1.display_xref_id=x3.xref_id) JOIN xref x4 ON (associated_xref.source_xref_id=x4.xref_id) WHERE associated_xref.condition_type IN ('assayed_using', 'assayed_enzyme', 'assayed_substrate') AND external_db.db_name='FYPO'" >> reciprocalAssociatedXrefs.tsv

gzip reciprocalAssociatedXrefs.tsv
