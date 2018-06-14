#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that genes in associated_xrefs.xref_id have the external_db set to 'PomBase_Systematic_ID' only."
c=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select e1.db_name, count(distinct nx.dbprimary_acc) TotalGenes, count(*) TotalAnnotations from transcript join object_xref on (transcript.transcript_id=object_xref.ensembl_id and object_xref.ensembl_object_type='Transcript') join xref x on (object_xref.xref_id=x.xref_id) join external_db e1 on (x.external_db_id=e1.external_db_id) left join associated_xref on (associated_xref.object_xref_id=object_xref.object_xref_id) join xref ax on (associated_xref.xref_id=ax.xref_id) join xref nx on (ax.dbprimary_acc=nx.dbprimary_acc) join external_db e2 on ax.external_db_id=e2.external_db_id join external_db e3 on (nx.external_db_id=e3.external_db_id) where e2.db_name='PBO' and e3.db_name='PomBase_Systematic_ID' group by e1.db_name;"`
if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo $c
  echo "  Fix the loading code.   The SQL below can be used as a patch as a last resort."
  echo "  update transcript join object_xref on (transcript.transcript_id=object_xref.ensembl_id and object_xref.ensembl_object_type='Transcript') join xref x on (object_xref.xref_id=x.xref_id) join external_db e1 on (x.external_db_id=e1.external_db_id) join associated_xref on (associated_xref.object_xref_id=object_xref.object_xref_id) join xref ax on (associated_xref.xref_id=ax.xref_id) join xref nx on (ax.dbprimary_acc=nx.dbprimary_acc) join external_db e2 on ax.external_db_id=e2.external_db_id join external_db e3 on (nx.external_db_id=e3.external_db_id) set associated_xref.xref_id=nx.xref_id where e2.db_name='PBO' and e3.db_name='PomBase_Systematic_ID';" 
else
  echo "PASSED"
fi
