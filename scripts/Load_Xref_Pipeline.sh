#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd $EG_DIR/ensembl/misc-scripts/xref_mapping

perl xref_config2sql.pl > sql/populate_metadata.sql

mkdir -p /nfs/nobackup/ensemblgenomes/${USER}/${SPECIES_SHORT}

perl xref_parser.pl -host $DBHOST -port $DBPORT -user $DBUSER -pass $DBPASS -species $SPECIES -drop_db -create -dbname ${SPECIES}_xref_${EG_RELEASE}_${ENSEMBL_RELEASE}_${ASSEMBLY} -stats -download_dir /nfs/nobackup/ensemblgenomes/${USER}/${SPECIES_SHORT} &> PARSER_Chadov${PB_VERSION}.out

echo "xref
host=$DBHOST
port=$DBPORT
dbname=$DBXREFNAME
user=$DBUSER
password=$DBPASS
dir=/nfs/nobackup/ensemblgenomes/${USER}/${SPECIES_SHORT}

species=$SPECIES
taxon=eukaryota
host=$DBHOST
port=$DBPORT
dbname=$DBCORENAME
user=$DBUSER
password=$DBPASS
dir=/nfs/nobackup/ensemblgenomes/${USER}/${SPECIES_SHORT}

farm
queue=production-rh6
exonerate=/nfs/panda/ensemblgenomes/external/exonerate-2/bin/exonerate
" > ${SPECIES_SHORT}_xref_mapper.input

perl xref_mapper.pl -file ${EG_DIR}/ensembl/misc-scripts/xref_mapping/${SPECIES_SHORT}_xref_mapper.input -nofarm >& MAPPER1.out

echo "Please review the mapper output file " ${pwd}/MAPPER1.out
echo "Do you wish to upload the data?"
select yn in "Yes" "No"; do
  case $yn in
    Yes ) perl xref_mapper.pl -file ${EG_DIR}/ensembl/misc-scripts/xref_mapping/${SPECIES_SHORT}_xref_mapper.input -upload >& mapper2.out; break;;
    No ) exit;;
  esac
done

