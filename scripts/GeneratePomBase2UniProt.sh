#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "select distinct gene.stable_id, xref.dbprimary_acc from gene join transcript on (gene.gene_id=transcript.gene_id) join translation on (transcript.transcript_id=translation.transcript_id) join object_xref on (translation.translation_id=object_xref.ensembl_id) join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) where object_xref.ensembl_object_type='Translation' and external_db.db_name like 'Uniprot%' order by gene.stable_id" > PomBase2UniProt.tsv
