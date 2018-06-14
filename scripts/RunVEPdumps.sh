#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

export PATH=$PATH:/nfs/panda/ensemblgenomes/external/mysql-cmds/combined

# 3. Set the environment variables where core lives 
# DBHOST, DBPORT, DBUSER, DBPASS
eval $($DBCMD details env_DB)
 
# 4. Set the environment variables for HIVE_DB
# HIVE_HOST, HIVE_DBPORT, HIVE_DBUSER, HIVE_DBPASS
eval $($DBHIVECMD details env_HIVE_)
 
# 5. Set pipeline name

pipeline_name=pombase_ftpDataDump
eg_version=$EG_RELEASE
ftp_site_dir=${PL}/data/FTP
temp_dir=/nfs/nobackup/ensemblgenomes/${USER}/workspace/${pipeline_name}/temp_dir
 
hive_dbname=${USER}_${pipeline_name}
#mysql -u$DBHIVEUSER -p$DBHIVEPASS -h$DBHIVEHOST -P$DBHIVEPORT -e "DROP DATABASE IF EXISTS ${hive_dbname};"
echo Using ${hive_dbname} on ${DBHIVEHOST} as hive database

cd $EG_DIR

registry=${PWD}/registry.vepdump.${DBCMD}.pm
echo Registry file for this run is: ${registry}

echo "{
package reg;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
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
    Bio::EnsEMBL::DBSQL::OntologyDBAdaptor->new(
        -HOST => '$DBHOST',
        -PORT => '$DBPORT',
        -USER => '$DBUSER',
        -PASS => '$DBPASS',
        -group        => 'ontology',
        -species      => 'multi',
        -dbname       => 'ensemblgenomes_ontology_$eg_version_$e_version',
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

HIVE_DB_PARAMS=
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -dbname=${hive_dbname}"
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -driver=mysql"
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -host=$HIVE_HOST"
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -port=$HIVE_PORT"
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -user=$HIVE_USER"
HIVE_DB_PARAMS="${HIVE_DB_PARAMS} -pipeline_db -pass=$HIVE_PASS"
echo $HIVE_DB_PARAMS
 
init_pipeline_args="-registry ${registry}
                    -ftp_dir ${ftp_site_dir}
                    -temp_dir ${temp_dir}
                    $HIVE_DB_PARAMS
                    -ensembl_cvs_root_dir ${EG_DIR}
                    -eg_git_root_dir ${EG_DIR}
                    -eg_version ${EG_RELEASE}
                    -pipeline_name ${pipeline_name}
                    -hive_root_dir ${EG_DIR}/ensembl-hive/
                    -hive_force_init 1"

# Create an empty hive database
init_pipeline.pl EGExt::FTP::PipeConfig::Empty ${init_pipeline_args}

init_pipeline.pl EGExt::FTP::PipeConfig::DumpsCoreVEP_conf ${init_pipeline_args} -species schizosaccharomyces_pombe -compara fungi -dump_vep_script ${EG_DIR}/ensembl-variation/scripts/export/dump_vep.pl -variant_effect_predictor_script ${EG_DIR}/ensembl-tools/scripts/variant_effect_predictor/variant_effect_predictor.pl -data_db host=$DBHOST -data_db port=$DBPORT -data_db user=$DBUSER -data_db pass=$DBPASS -hive_no_init 1

beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -sync
beekeeper.pl -url mysql://${HIVE_USER}:${HIVE_PASS}@${HIVE_HOST}:${HIVE_PORT}/${hive_dbname} -reg_conf ${registry} -loop


init_pipeline.pl Bio::EnsEMBL::EGPipeline::PipeConfig::CoreStatistics_conf $(${DBCMD} details script) -registry ${registry} -species ${SPECIES} -no_pepstats 1

beekeeper.pl -url mysql://${DBUSER}:${DBPASS}@${DBHOST}:${DBPORT}/${USER}_core_statistics_${ENSEMBL_RELEASE} -sync
beekeeper.pl -url mysql://${DBUSER}:${DBPASS}@${DBHOST}:${DBPORT}/${USER}_core_statistics_${ENSEMBL_RELEASE} -reg_conf ${registry} -loop

