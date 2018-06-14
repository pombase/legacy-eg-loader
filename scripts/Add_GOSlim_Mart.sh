#!/bin/bash --

DBUSER=
DBPASS=
DBHOST=
DBPORT=
division=
e_version=
eg_version=

if ( ! getopts "HpuPdeg" opt); then
  echo "Usage: `basename $0` -H HOST -p PORT -u USER -P PASSWORD -e E_VERSION -g EG_VERSION";
  exit 10
fi

while getopts ":H:p:u:P:d:e:g:" opt; do
  case $opt in
    H)
      # Host
      DBHOST=$OPTARG
      ;;
    p)
      # Port
      DBPORT=$OPTARG
      ;;
    u)
      DBUSER=$OPTARG
      ;;
    P)
      DBPASS=$OPTARG
      ;;
    e)
      e_version=$OPTARG
      ;;
    g)
      eg_version=$OPTARG
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 11
      ;;
  esac
done

if [ -z $DBHOST ] || [ -z $DBPORT ] || [ -z $DBUSER ] || [ -z $DBPASS ] || [ -z $e_version ] || [ -z $eg_version ]
then
  echo "WARNING: Missing parameters"
  echo " -H : Host       = $DBHOST"
  echo " -p : Port       = $DBPORT"
  echo " -u : User       = $DBUSER"
  echo " -P : Password   = $DBPASS"
  echo " -e : E Version  = $e_version"
  echo " -g : EG Version = $eg_version"
  exit 10
fi

ontology_db="ensemblgenomes_ontology_${eg_version}_${e_version}"
ontology_mart="egontology_mart_${eg_version}"

for slim in "aspergillus" "candida" "generic" "metagenomics" "pir" "plant" "pombe" "synapse" "virus" "yeast"
do
  slim_table="aux_GO_goslim_${slim}_map"
  echo "CREATE TABLE tmp_slim SELECT DISTINCT closure.child_term_id, closure.parent_term_id, term.accession, term.name, term.definition FROM ${ontology_db}.closure JOIN ${ontology_db}.${slim_table} ON (closure.parent_term_id=${slim_table}.term_id) JOIN ${ontology_db}.term ON (closure.parent_term_id=term.term_id);"
  echo "CREATE INDEX idx_chld ON tmp_slim (child_term_id);"
  echo "CREATE TABLE closure_GO__goslim_${slim}__dm SELECT cc.closure_id_301_key, cc.accession_305, c2.accession AS accession_305_r1, c2.name AS name_305_r1, c2.definition AS definition_305_r1 FROM ${ontology_mart}.closure_GO__closure__main cc JOIN ${ontology_db}.closure c ON (cc.closure_id_301_key=c.closure_id) JOIN ${ontology_db}.ontology o ON (c.ontology_id=o.ontology_id) LEFT JOIN tmp_slim c2 ON (c.child_term_id=c2.child_term_id) WHERE o.name='GO';"
  echo "CREATE INDEX accession_305_${slim} ON closure_GO__goslim_${slim}__dm (accession_305);"
  echo "CREATE INDEX closure_id_301_key_${slim} ON closure_GO__goslim_${slim}__dm (closure_id_301_key);"
  echo "CREATE INDEX accession_305_r1_${slim} ON closure_GO__goslim_${slim}__dm (accession_305_r1);"
  echo "DROP TABLE tmp_slim;"
  
  echo ""
  echo "
      <AttributeCollection displayName=\"goslim ${slim}\" internalName=\"goslim_${slim}\" useDefault=\"true\">
        <AttributeDescription displayName=\"Accession 305\" field=\"accession_305\" internalName=\"goslim_${slim}__dm_accession_305\" key=\"closure_id_301_key\" maxLength=\"64\" tableConstraint=\"closure_GO__goslim_${slim}__dm\" useDefault=\"true\" />
        <AttributeDescription displayName=\"Accession 305 r1\" field=\"accession_305_r1\" internalName=\"goslim_${slim}__dm_accession_305_r1\" key=\"closure_id_301_key\" maxLength=\"64\" tableConstraint=\"closure_GO__goslim_${slim}__dm\" useDefault=\"true\" />
        <AttributeDescription displayName=\"Name 305 r1\" field=\"name_305_r1\" internalName=\"goslim_${slim}__dm_name_305_r1\" key=\"closure_id_301_key\" maxLength=\"255\" tableConstraint=\"closure_GO__goslim_${slim}__dm\" useDefault=\"true\" />
        <AttributeDescription displayName=\"Definition 305 r1\" field=\"definition_305_r1\" internalName=\"goslim_${slim}__dm_definition_305_r1\" key=\"closure_id_301_key\" maxLength=\"255\" tableConstraint=\"closure_GO__goslim_${slim}__dm\" useDefault=\"true\" />
      </AttributeCollection>"
  echo ""
done

