#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

gene='SPAC1783.07c'
ont='GO'
ont_term='GO:0001077'
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -e "SELECT transcript.stable_id, x1.dbprimary_acc, associated_xref.associated_group_id, associated_xref.rank, associated_xref.condition_type, x2.dbprimary_acc from transcript join object_xref on (transcript.transcript_id=object_xref.ensembl_id) join associated_xref on (object_xref.object_xref_id=associated_xref.object_xref_id) join xref x1 on (object_xref.xref_id=x1.xref_id) join xref x2 on (associated_xref.xref_id=x2.xref_id) join external_db on (x1.external_db_id=external_db.external_db_id) where external_db.db_name='${ont}' and transcript.stable_id like '${gene}%' and x1.dbprimary_acc='${ont_term}';"


