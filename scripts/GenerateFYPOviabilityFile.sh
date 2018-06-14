#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -N -e "SELECT c.stable_id, IF(COUNT(DISTINCT c.accession)='2', 'condition-dependent', IF(c.accession='FYPO:0002060', 'viable', 'inviable')) FROM  ( SELECT gene.stable_id, object_xref.object_xref_id, parent.accession, x1.dbprimary_acc, x1.display_label, associated_xref.associated_group_id, COUNT(x2.dbprimary_acc), GROUP_CONCAT(x2.info_text) AS allele_type FROM gene JOIN transcript ON (gene.gene_id=transcript.gene_id) JOIN object_xref ON (transcript.transcript_id=object_xref.ensembl_id AND object_xref.ensembl_object_type='Transcript') JOIN associated_xref ON (object_xref.object_xref_id=associated_xref.object_xref_id) JOIN xref x1 ON (object_xref.xref_id=x1.xref_id) JOIN external_db ON (x1.external_db_id=external_db.external_db_id) JOIN xref x2 ON (associated_xref.xref_id=x2.xref_id) JOIN ensemblgenomes_ontology_${EG_RELEASE}_${ENSEMBL_RELEASE}.term child ON (x1.dbprimary_acc=child.accession) JOIN ensemblgenomes_ontology_${EG_RELEASE}_${ENSEMBL_RELEASE}.closure c ON (child.term_id=c.child_term_id) JOIN ensemblgenomes_ontology_${EG_RELEASE}_${ENSEMBL_RELEASE}.term parent ON (c.parent_term_id=parent.term_id) WHERE external_db.db_name='FYPO' AND associated_xref.condition_type='allele' AND parent.accession IN ('FYPO:0002060', 'FYPO:0002061') GROUP BY gene.stable_id, object_xref.object_xref_id, parent.accession, x1.dbprimary_acc, x1.display_label, associated_xref.associated_group_id HAVING COUNT(x2.dbprimary_acc)=1  ) c WHERE c.allele_type='deletion' GROUP BY c.stable_id;" > FYPOviability.tsv
