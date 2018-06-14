#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

# 3. Set the environment variables where core lives 
# DBHOST, DBPORT, DBUSER, DBPASS
eval $($DBCMD details env_DB)
 
# 4. Set the environment variables for HIVE_DB
# HIVE_HOST, HIVE_DBPORT, HIVE_DBUSER, HIVE_DBPASS
eval $($DBHIVECMD details env_HIVE_)
 
# 5. Set pipeline name
pipeline_name=dna_features_${ENSEMBL_RELEASE}

hive_dbname=${USER}_${pipeline_name}
mysql -u$DBHIVEUSER -p$DBHIVEPASS -h$DBHIVEHOST -P$DBHIVEPORT -e "DROP DATABASE IF EXISTS ${hive_dbname};"
echo Using ${hive_dbname} on ${DBHIVEHOST} as hive database

pipeline_dir=/nfs/nobackup/ensemblgenomes/${USER}/${pipeline_name}
echo Using ${pipeline_dir} as a temporary directory
 
cd $EG_DIR

registry=${PWD}/registry.${DBCMD}.pm
echo Registry file for this run is: ${registry}

echo "{
package reg;
" > $registry
echo "
Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -HOST => '$DBHOST',
    -PORT => '$DBPORT',
    -USER => '$DBUSER',
    -PASS => '$DBPASS',
    -VERBOSE => '1',
    -DB_VERSION => '${ENSEMBL_RELEASE}',
    -WAIT_TIMEOUT => undef,
    -NO_CACHE => undef,
    -DBNAME => '${DBCORENAME}',
    -SPECIES => '${SPECIES}',
);
" >> $registry
echo "
Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -host    => '$DBPRODHOST',
    -port    => '$DBPRODPORT',
    -user    => '$DBPRODUSER',
    -dbname  => 'ensembl_production',
    -species => 'multi',
    -group   => 'production'
  );
" >> $registry
echo "1;
}" >> $registry

init_pipeline.pl Bio::EnsEMBL::EGPipeline::PipeConfig::DNAFeatures_conf -registry ${registry} -species schizosaccharomyces_pombe $($DBHIVECMD details script) -pipeline_dir ${pipeline_dir}

beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -sync
beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -reg_conf ${registry} -loop

