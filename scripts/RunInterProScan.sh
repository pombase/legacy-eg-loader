#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv
export PATH=/nfs/panda/ensemblgenomes/external/python/Python-2.7.5:${PATH}
export JAVA_HOME=/nfs/panda/ensemblgenomes/external/jdk1.8

# 3. Set the environment variables where core lives 
# DBHOST, DBPORT, DBUSER, DBPASS
eval $($DBCMD details env_DB)
 
# 4. Set the environment variables for HIVE_DB
# HIVE_HOST, HIVE_DBPORT, HIVE_DBUSER, HIVE_DBPASS
eval $($DBHIVECMD details env_HIVE_)
 
# 5. Set pipeline name
pipeline_name=InterProScanSeg_${ENSEMBL_RELEASE}
 
hive_dbname=${USER}_${pipeline_name}
mysql -u$DBHIVEUSER -p$DBHIVEPASS -h$DBHIVEHOST -P$DBHIVEPORT -e "DROP DATABASE IF EXISTS ${hive_dbname};"
echo Using ${hive_dbname} on ${DBHIVEHOST} as hive database
 
pipeline_dir=/nfs/nobackup/ensemblgenomes/${USER}/${pipeline_name}
echo Using ${pipeline_dir} as a temporary directory

cd $EG_DIR

registry=${PWD}/registry.ipr.${DBCMD}.pm
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

#echo ${JAVA_HOME}

init_pipeline.pl Bio::EnsEMBL::Hive::PipeConfig::InterProScanSeg_conf -registry ${registry} -species schizosaccharomyces_pombe -hive_host ${HIVE_HOST} -hive_port ${HIVE_PORT} -hive_user ${HIVE_USER} -hive_password ${HIVE_PASS} -hive_dbname ${hive_dbname} -pipeline_dir ${pipeline_dir}

beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -sync
beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -reg_conf ${registry} -loop

#runWorker.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -reg_conf ${registry}

