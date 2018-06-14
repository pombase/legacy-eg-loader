#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "SELECT gene.stable_id AS systematic_id, IF(gene.stable_id=xref.display_label, '', xref.display_label) AS gene_name, translation.stable_id AS peptide_id, protein_feature.hit_name AS domain_id, analysis.logic_name AS 'database', protein_feature.seq_start, protein_feature.seq_end FROM gene JOIN transcript ON (gene.gene_id=transcript.gene_id) JOIN translation ON (transcript.transcript_id=translation.transcript_id) JOIN protein_feature ON (translation.translation_id=protein_feature.translation_id) JOIN analysis ON (protein_feature.analysis_id=analysis.analysis_id) LEFT JOIN xref ON (gene.display_xref_id=xref.xref_id);" > Protein_Features.tsv
