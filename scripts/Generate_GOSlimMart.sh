#!/bin/bash --

DBUSER=
DBPASS=
DBHOST=
DBPORT=
e_version=
eg_version=

if ( ! getopts "HpuPdeg" opt); then
  echo "Usage: `basename $0` -H HOST -p PORT -u USER -P PASSWORD -e E_VERSION -g EG_VERSION";
  exit 10
fi

while getopts ":H:p:u:P:e:g:" opt; do
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

db="ensemblgenomes_ontology_${eg_version}_${e_version}"
db_mart="egontology_mart_${eg_version}"

mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $db_mart -e "CREATE TABLE slim_GO_slim_dm (slim varchar(25) CHARACTER SET utf8 NOT NULL DEFAULT '', name_302 varchar(64) NOT NULL, namespace_302 varchar(64) NOT NULL, accession_305_r1 varchar(64) NOT NULL, name_305_r1 varchar(255) NOT NULL, definition_305 text);"

for slim in aspergillus candida generic metagenomics pir plant pombe synapse virus yeast
do
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${db_mart} -e "insert into slim_GO_slim_dm (slim, name_302, namespace_302, accession_305_r1, name_305_r1, definition_305) select '${slim}', ontology.name as name_302, ontology.namespace as namespace_302, term.accession as accession_305_r1, term.name as name_305_r1, term.definition as definition_305 from ${db}.aux_GO_goslim_${slim}_map join ${db}.term on (aux_GO_goslim_${slim}_map.term_id=term.term_id) join ${db}.ontology on (term.ontology_id=ontology.ontology_id);"
done
