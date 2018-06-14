#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ../data/sql/$DBCORENAME
echo "Generating the SQL_load.sql file ..."
#python ../../../BuildBioMartSQLLoader.py --host $DBPOMBEHOST --port $DBPOMBEPORT --user $DBPOMBEUSER --pswd $DBPOMBEPASS --mart $DBMARTNAME

echo "Creating the database $DBMARTNAME ..."
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "DROP DATABASE $DBMARTNAME;"
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBPOMBEHOST -P$DBPOMBEPORT -e "CREATE DATABASE $DBMARTNAME;"

echo "Loading the database $DBMARTNAME ..."
MY_DIR2=`dirname $0`
source $MY_DIR2/SQL_loader.sql



# go to the scripts directory
cd $EG_DIR/eg-biomart/scripts

DATASET_NAME=gene
SUFFIX_PARAMETER='-suffix _eg'


echo "\n#####perl generate_names.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE $SUFFIX_PARAMETER"
perl generate_names.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE $SUFFIX_PARAMETER

echo "\n#####perl calculate_sequence_data.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE -dataset_basename $DATASET_NAME"
perl calculate_sequence_data.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE -dataset_basename $DATASET_NAME

echo "\n#####perl generate_ontology_extension.pl -h $DBPOMBEHOST -port $DBPOMBEPORT -u $DBPOMBEUSER -p $DBPOMBEPASS -mart $DBMARTNAME -dataset ${SPECIES_SHORT}_eg"
perl generate_ontology_extension.pl -h $DBPOMBEHOST -port $DBPOMBEPORT -u $DBPOMBEUSER -p $DBPOMBEPASS -mart $DBMARTNAME -dataset "${SPECIES_SHORT}_eg"

echo "\n#####perl add_compara.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -compara $DBCOMPARANAME"
perl add_compara.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME -compara $DBCOMPARANAME

echo "\n#####perl tidy_tables.pl -h $DBPOMBEHOST -port $DBPOMBEPORT -u $DBPOMBEUSER -p $DBPOMBEPASS -mart $DBMARTNAME"
perl tidy_tables.pl -host $DBPOMBEHOST -port $DBPOMBEPORT -user $DBPOMBEUSER -pass $DBPOMBEPASS -mart $DBMARTNAME


