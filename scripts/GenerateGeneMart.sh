#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ../data/sql/$DBCORENAME
echo "Generating the SQL_load.sql file ..."
#python ../../../misc_scripts/BuildBioMartSQLLoader.py --host $DBHOST --port $DBPORT --user $DBUSER --pswd $DBPASS --mart $DBMARTNAME

echo "Creating the database $DBMARTNAME ..."
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "DROP DATABASE IF EXISTS $DBMARTNAME;"
mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT -e "CREATE DATABASE $DBMARTNAME;"

echo "Loading the database $DBMARTNAME ..."
MY_DIR2=`dirname $0`
source $MY_DIR2/SQL_loader.sql



# go to the scripts directory
cd $EG_DIR/eg-biomart/scripts

DATASET_NAME=gene
SUFFIX_PARAMETER='-suffix _eg'


echo "\n#####perl generate_names.pl -host $DBHOST -port $DBPORT -user $DBUSER -pass $DBPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE $SUFFIX_PARAMETER"
perl generate_names.pl -host $DBHOST -port $DBPORT -user $DBUSER -pass $DBPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE $SUFFIX_PARAMETER

echo "\n#####perl calculate_sequence_data.pl --host $DBHOST -port $DBPORT --user $DBUSER --pass $DBPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE -dataset_basename $DATASET_NAME"
perl calculate_sequence_data.pl --host $DBHOST -port $DBPORT --user $DBUSER --pass $DBPASS -mart $DBMARTNAME -release $ENSEMBL_RELEASE -dataset_basename $DATASET_NAME

echo "\n#####perl generate_ontology_extension.pl -h $DBHOST -port $DBPORT -u $DBUSER -p $DBPASS -mart $DBMARTNAME -dataset ${SPECIES_SHORT}_eg"
perl generate_ontology_extension.pl -h $DBHOST -port $DBPORT -u $DBUSER -p $DBPASS -mart $DBMARTNAME -dataset "${SPECIES_SHORT}_eg"

#echo "\n#####perl add_compara.pl -host $DBHOST -port $DBPORT -u $DBUSER -pass $DBPASS -mart $DBMARTNAME -compara $DBCOMPARANAME"
#perl add_compara.pl -host $DBHOST -port $DBPORT -u $DBUSER -pass $DBPASS -mart $DBMARTNAME -compara $DBCOMPARANAME
#echo "\n#####python ${MY_DIR}/add_compara_bool.py --dbhost $DBHOST --dbport $DBPORT --dbuser $DBUSER --dbpass $DBPASS --eg_release ${EG_RELEASE}"
#python ${MY_DIR}/add_compara_bool.py --dbhost $DBHOST --dbport $DBPORT --dbuser $DBUSER --dbpass $DBPASS --eg_release ${EG_RELEASE}

echo "\n#####perl tidy_tables.pl -host $DBHOST -port $DBPORT -u $DBUSER -pass $DBPASS -mart $DBMARTNAME"
perl tidy_tables.pl -host $DBHOST -port $DBPORT -u $DBUSER -pass $DBPASS -mart $DBMARTNAME


