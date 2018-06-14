#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "select gene.stable_id, mass.value Mass, pi.value pI, c.value Charge, l.value NumResidues, round(cai.value, 3) CAI from gene join transcript on (gene.gene_id=transcript.gene_id) join translation on (transcript.transcript_id=translation.transcript_id) left join translation_attrib mass on (translation.translation_id=mass.translation_id) join attrib_type mass_type on (mass.attrib_type_id=mass_type.attrib_type_id and mass_type.code='MolecularWeight') left join translation_attrib pi on (translation.translation_id=pi.translation_id) join attrib_type pi_type on (pi.attrib_type_id=pi_type.attrib_type_id and pi_type.code='IsoPoint') left join translation_attrib c on (translation.translation_id=c.translation_id) join attrib_type c_type on (c.attrib_type_id=c_type.attrib_type_id and c_type.code='Charge') left join translation_attrib l on (translation.translation_id=l.translation_id) join attrib_type l_type on (l.attrib_type_id=l_type.attrib_type_id and l_type.code='NumResidues') left join translation_attrib cai on (translation.translation_id=cai.translation_id) join attrib_type cai_type on (cai.attrib_type_id=cai_type.attrib_type_id and cai_type.code='CodonAdaptIndex');" > PeptideStats.tsv
