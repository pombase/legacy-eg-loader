#!/bin/bash --

## Get the GO level:
#  select distinct object_xref.ensembl_object_type from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) join ensemblgenomes_ontology_26_79.term as t on (t.accession=xref.dbprimary_acc) where external_db.db_name='GO';

## Generates ox_goslim_goa - Translation
#  select distinct t.name as description_1074, xref.display_label as display_label_1074, object_xref.ensembl_id as translation_id_1068_key, xref.dbprimary_acc as dbprimary_acc_1074 from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) join ensemblgenomes_ontology_26_79.term as t on (t.accession=xref.dbprimary_acc) join ensemblgenomes_ontology_26_79.closure as c on (t.term_id=c.child_term_id) join ensemblgenomes_ontology_26_79.aux_GO_goslim_aspergillus_map as s on (c.parent_term_id=s.term_id) where external_db.db_name='GO' order by object_xref.ensembl_id;

## Generates ontology_goslim - Translation
#  select distinct ontology_xref.linkage_type, t.ontology_id, t.definition, object_xref.ensembl_id as translation_id_1068_key, t.is_root, t.name as name_1006, xref.dbprimary_acc as dbprimary_acc_1074 from object_xref join xref on (object_xref.xref_id=xref.xref_id) join external_db on (xref.external_db_id=external_db.external_db_id) join ontology_xref on (object_xref.object_xref_id=ontology_xref.object_xref_id) join ensemblgenomes_ontology_26_79.term as t on (t.accession=xref.dbprimary_acc) join ensemblgenomes_ontology_26_79.closure as c on (t.term_id=c.child_term_id) join ensemblgenomes_ontology_26_79.aux_GO_goslim_aspergillus_map as s on (c.parent_term_id=s.term_id) where external_db.db_name='GO' order by object_xref.ensembl_id;

DBUSER=
DBPASS=
DBHOST=
DBPORT=
division=
e_version=
eg_version=

if ( ! getopts "HpuPdeg" opt); then
  echo "Usage: `basename $0` -H HOST -p PORT -u USER -P PASSWORD -d DIVISION -e E_VERSION -g EG_VERSION";
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
      # User
      DBUSER=$OPTARG
      ;;
    P)
      # Password
      DBPASS=$OPTARG
      ;;
    d)
      # Division
      division=$OPTARG
      ;;
    e)
      # Ensembl Version
      e_version=$OPTARG
      ;;
    g)
      # Ensembl Genomes Version
      eg_version=$OPTARG
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 11
      ;;
  esac
done

if [ -z $DBHOST ] || [ -z $DBPORT ] || [ -z $DBUSER ] || [ -z $DBPASS ] || [ -z $division ] || [ -z $e_version ] || [ -z $eg_version ]
then
  echo "WARNING: Missing parameters"
  echo " -H : Host       = $DBHOST"
  echo " -p : Port       = $DBPORT"
  echo " -u : User       = $DBUSER"
  echo " -P : Password   = $DBPASS"
  echo " -d : Division   = $division"
  echo " -e : E Version  = $e_version"
  echo " -g : EG Version = $eg_version"
  exit 10
fi

declare -A mart
mart=(["EB"]="bacterial_mart_${eg_version}" ["EF"]="fungi_mart_${eg_version}" ["EM"]="metazoa_mart_${eg_version}" ["EPl"]="plants_mart_${eg_version}" ["EPr"]="protists_mart_${eg_version}")

ontology_db="ensemblgenomes_ontology_${eg_version}_${e_version}"

dbnames=$(sh process_division.sh $division | grep core | sort)

for dbAny in ${dbnames}
do
  spname=$(echo $dbAny | sed "s/_core_[0-9]*_[0-9]*_[0-9]*//")
  sp=$(echo $spname | sed "s/.*_//")
  genus=$(echo $spname | sed "s/_.*//")
  short_name="${spname:0:1}$sp"
  assembly=$(echo $dbAny | sed "s/\w*_\w*_core_[0-9]*_[0-9]*_//")
  db="${spname}_core_${eg_version}_${e_version}_${assembly}"
  
  level=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $db -s -N -e "select distinct object_xref.ensembl_object_type from ${db}.object_xref join ${db}.xref on (object_xref.xref_id=xref.xref_id) join ${db}.external_db on (xref.external_db_id=external_db.external_db_id) where external_db.db_name='GO';"`
  
  echo "$spname ==> $sp ==> $genus ==> $short_name ==> $level"
  declare -A col_title
  col_title=(["Transcript"]="transcript_id_1064_key" ["Translation"]="translation_id_1068_key")
  
  slim="aux_GO_goslim_generic_map"
  slim_short="generic"
  if [ "$spname" == "saccharomyces_cerevisiae" ]
  then
    slim="aux_GO_goslim_yeast_map"
    slim_short="yeast"
  elif [ "$spname" == "schizosaccharomyces_pombe" ]
  then
    slim="aux_GO_goslim_pombe_map"
    slim_short="pombe"
  elif [ "$genus" == "aspergillus" ]
  then
    slim="aux_GO_goslim_aspergillus_map"
    slim_short="aspergillus"
  elif [ "$division" == "EPl" ]
  then
    slim="aux_GO_goslim_plant_map"
    slim_short="plant"
  fi
  
  echo "  Creating ${short_name}_eg_gene__ox_goslim_goa__dm ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "drop table if exists ${short_name}_eg_gene__ox_goslim_goa__dm"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "create table ${short_name}_eg_gene__ox_goslim_goa__dm select distinct t.name as description_1074, xref.display_label as display_label_1074, object_xref.ensembl_id as ${col_title[$level]}, xref.dbprimary_acc as dbprimary_acc_1074 from ${db}.object_xref join ${db}.xref on (object_xref.xref_id=xref.xref_id) join ${db}.external_db on (xref.external_db_id=external_db.external_db_id) join ${ontology_db}.term as t on (t.accession=xref.dbprimary_acc) join ${ontology_db}.closure as c on (t.term_id=c.child_term_id) join ${ontology_db}.${slim} as s on (c.parent_term_id=s.term_id) where external_db.db_name='GO' order by object_xref.ensembl_id;"
  
  echo "  Creating ${short_name}_eg_gene__ontology_goslim_goa__dm ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "drop table if exists ${short_name}_eg_gene__ontology_goslim_goa__dm"
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "create table ${short_name}_eg_gene__ontology_goslim_goa__dm select distinct ontology_xref.linkage_type, t.ontology_id, t.definition, object_xref.ensembl_id as ${col_title[$level]}, t.is_root, t.name as name_1006, xref.dbprimary_acc as dbprimary_acc_1074 from ${db}.object_xref join ${db}.xref on (object_xref.xref_id=xref.xref_id) join ${db}.external_db on (xref.external_db_id=external_db.external_db_id) join ${db}.ontology_xref on (object_xref.object_xref_id=ontology_xref.object_xref_id) join ${ontology_db}.term as t on (t.accession=xref.dbprimary_acc) join ${ontology_db}.closure as c on (t.term_id=c.child_term_id) join ${ontology_db}.${slim} as s on (c.parent_term_id=s.term_id) where external_db.db_name='GO' order by object_xref.ensembl_id;"
  
  echo "  Modifying ${short_name}_eg_gene__${level,,}__main ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "alter table ${mart[$division]}.${short_name}_eg_gene__${level,,}__main add column (ox_goslim_goa_bool integer default 0);"
  
  echo "  Updating column ${short_name}_eg_gene__${level,,}__main ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT ${mart[$division]} -s -N -e "update ${mart[$division]}.${short_name}_eg_gene__${level,,}__main a set ox_goslim_goa_bool=(select case count(1) when 0 then null else 1 end from ${mart[$division]}.${short_name}_eg_gene__ox_go__dm b where a.${col_title[$level]}=b.${col_title[$level]} and not (b.description_1074 is null and b.dbprimary_acc_1074 is null and b.display_label_1074 is null));"
  
  levelType=$(echo $level | tr '[:upper:]' '[:lower:]')
  echo "  Creating index I_goslim_${short_name} ..."
  mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT test -s -N -e "create index I_goslim_${short_name} on ${mart[$division]}.${short_name}_eg_gene__${levelType}__main(ox_goslim_goa_bool);"
done

