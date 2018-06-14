#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

export ONTOLOGY='CL'
export ONTOLOGY_TABLE='cl'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';
" > ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='CHEBI'
export ONTOLOGY_TABLE='chebi'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';
" > ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='ECO'
export ONTOLOGY_TABLE='eco'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" > ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='FYPO'
export ONTOLOGY_TABLE='fypo'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, count(distinct t.stable_id_1023) gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) join closure on (parent.term_id=closure.parent_term_id) left join term child on (closure.child_term_id=child.term_id) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__ox_"$ONTOLOGY_TABLE"__dm mart on (child.accession=mart.dbprimary_acc_1074) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t on (mart.transcript_id_1064_key=t.transcript_id_1064_key) where ontology.name='$ONTOLOGY' group by parent.accession, parent.name;" >> ontology_term_cache.tsv
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "SELECT parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, COUNT(DISTINCT t.stable_id_1023) gene_count FROM term parent JOIN ontology ON (parent.ontology_id=ontology.ontology_id) JOIN closure ON (parent.term_id=closure.parent_term_id) LEFT JOIN term child ON (closure.child_term_id=child.term_id) LEFT JOIN fungi_mart_${EG_RELEASE}.spombe_eg_gene__${ONTOLOGY_TABLE}_extension__dm mart ON (child.accession=mart.subject_acc) LEFT JOIN fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t ON(mart.transcript_id_1064_key=t.transcript_id_1064_key) WHERE ontology.name='$ONTOLOGY' GROUP BY parent.accession, parent.name;" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='FYPO_EXT'
export ONTOLOGY_TABLE='fypo_ext'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='GO'
export ONTOLOGY_TABLE='go'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, count(distinct t.stable_id_1023) gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) join closure on (parent.term_id=closure.parent_term_id) left join term child on (closure.child_term_id=child.term_id) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__ox_"$ONTOLOGY_TABLE"__dm mart on (child.accession=mart.dbprimary_acc_1074) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t on (mart.transcript_id_1064_key=t.transcript_id_1064_key) where ontology.name='$ONTOLOGY' group by parent.accession, parent.name;" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='MOD'
export ONTOLOGY_TABLE='mod'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, count(distinct t.stable_id_1023) gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) join closure on (parent.term_id=closure.parent_term_id) left join term child on (closure.child_term_id=child.term_id) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__ox_"$ONTOLOGY_TABLE"__dm mart on (child.accession=mart.dbprimary_acc_1074) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t on (mart.transcript_id_1064_key=t.transcript_id_1064_key) where ontology.name='$ONTOLOGY' group by parent.accession, parent.name;" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='PATO'
export ONTOLOGY_TABLE='pato'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='PBO'
export ONTOLOGY_TABLE='pbo'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, count(distinct t.stable_id_1023) gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) join closure on (parent.term_id=closure.parent_term_id) left join term child on (closure.child_term_id=child.term_id) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__ox_"$ONTOLOGY_TABLE"__dm mart on (child.accession=mart.dbprimary_acc_1074) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t on (mart.transcript_id_1064_key=t.transcript_id_1064_key) where ontology.name='$ONTOLOGY' group by parent.accession, parent.name;" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='PECO'
export ONTOLOGY_TABLE='peco'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='PR'
export ONTOLOGY_TABLE='pr'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='SO'
export ONTOLOGY_TABLE='so'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, count(distinct t.stable_id_1023) gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) join closure on (parent.term_id=closure.parent_term_id) left join term child on (closure.child_term_id=child.term_id) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__ox_"$ONTOLOGY_TABLE"__dm mart on (child.accession=mart.dbprimary_acc_1074) left join fungi_mart_${EG_RELEASE}.spombe_eg_gene__transcript__main t on (mart.transcript_id_1064_key=t.transcript_id_1064_key) where ontology.name='$ONTOLOGY' group by parent.accession, parent.name;" >> ontology_term_cache.tsv
date
echo "Complete!"

export ONTOLOGY='UO'
export ONTOLOGY_TABLE='uo'
echo "Generating $ONTOLOGY:"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select parent.accession term_accession, parent.name term_name, parent.definition term_definition, parent.is_obsolete, ontology.name ontology_name, ontology.namespace ontology_namespace, 0 gene_count from term parent join ontology on (parent.ontology_id=ontology.ontology_id) where ontology.name='$ONTOLOGY';" >> ontology_term_cache.tsv
date
echo "Complete!"

echo "  ============================================================================  "

#echo "Exporting Ontology term alt_ids"
#date
#mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select term.accession, alt_id.accession from term, ontology, alt_id where term.term_id=alt_id.term_id and term.ontology_id=ontology.ontology_id and ontology.name in ('CHEBI', 'FYPO', 'FYPO_EXT', 'GO', 'MOD', 'PATO', 'PBO', 'PECO', 'PR', 'SO', 'UO')" > ontology_term_altId_cache.tsv
#date
#echo "Comlplete!"

#echo "  ============================================================================  "

echo "Exporting Ontology term synonyms"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select term.accession, synonym.name, synonym.type from term, ontology, synonym where term.term_id=synonym.term_id and term.ontology_id=ontology.ontology_id and ontology.name in ('CL', 'CHEBI', 'FYPO', 'FYPO_EXT', 'GO', 'MOD', 'PATO', 'PBO', 'PECO', 'PR', 'SO', 'UO');" > ontology_term_synonym_cache.tsv
date
echo "Comlplete!"

echo "  ============================================================================  "

echo "Generating closure table"
date
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBNAME -N -e "select child.accession, parent.accession, closure.distance from term child, term parent, closure, ontology where child.term_id=closure.child_term_id and parent.term_id=closure.parent_term_id and parent.ontology_id=ontology.ontology_id and ontology.name in ('CL', 'CHEBI', 'FYPO', 'FYPO_EXT', 'GO', 'MOD', 'PATO', 'PBO', 'PECO', 'PR', 'SO', 'UO') order by ontology.name, child.accession;" > ontology_term_closure_cache.tsv
date
echo "Complete!"

echo "  ============================================================================  "

echo "Zipping the generated tables"
date
gzip ontology_term_cache.tsv
#gzip ontology_term_altId_cache.tsv
gzip ontology_term_synonym_cache.tsv
gzip ontology_term_closure_cache.tsv
date
echo "Complete!"
