#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

echo "# Annotation_source: PomBase Chadov${PB_VERSION}
# Created: ${PB_RELEASE}" > allNames.tsv

echo "# Annotation_source: PomBase Chadov${PB_VERSION}
# Created: ${PB_RELEASE}" > sysID2product.tsv

echo "# Annotation_source: PomBase Chadov${PB_VERSION}
# Created: ${PB_RELEASE}" > sysID2product.rna.tsv

mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -N -e "SELECT gene.stable_id, IF(gene.stable_id=xref.display_label, '', xref.display_label) name, IF(external_synonym.synonym IS NULL,'',GROUP_CONCAT(external_synonym.synonym SEPARATOR ',')) AS synonyms FROM gene JOIN xref ON (gene.display_xref_id=xref.xref_id) LEFT JOIN external_synonym ON (xref.xref_id=external_synonym.xref_id) GROUP BY gene.stable_id;" >> allNames.tsv

mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -N -e "SELECT gene.stable_id, IF(gene.stable_id=xref.display_label, '', xref.display_label) name, IF(external_synonym.synonym IS NULL,'',GROUP_CONCAT(external_synonym.synonym SEPARATOR ',')) AS synonyms, SUBSTRING_INDEX(gene.description, ' [', 1) FROM gene JOIN xref ON (gene.display_xref_id=xref.xref_id) LEFT JOIN external_synonym ON (xref.xref_id=external_synonym.xref_id) WHERE biotype='protein_coding' GROUP BY gene.stable_id;" >> sysID2product.tsv

mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT $DBCORENAME -N -e "SELECT gene.stable_id, IF(gene.stable_id=xref.display_label, '', xref.display_label) name, IF(external_synonym.synonym IS NULL,'',GROUP_CONCAT(external_synonym.synonym SEPARATOR ',')) AS synonyms, SUBSTRING_INDEX(gene.description, ' [', 1) FROM gene JOIN xref ON (gene.display_xref_id=xref.xref_id) LEFT JOIN external_synonym ON (xref.xref_id=external_synonym.xref_id) WHERE biotype!='protein_coding' GROUP BY gene.stable_id;" >> sysID2product.rna.tsv
