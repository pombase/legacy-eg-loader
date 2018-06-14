#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ../
mkdir -p data/tmp

if [ -e "${EG_DIR}/${DBREGISTRY}" ]
then
  echo "Ready to Start Dumping ..."
else
  echo "WARNING: Registry file does not exist!"
  echo "${EG_DIR}/${DBREGISTRY}"
  exit 10
fi

dump_dir=${PL}/data/tmp

cd $EG_DIR

registry=${PWD}/registry.${DBCMD}.pm
echo Registry file for this run is: ${registry}

echo "{
package reg;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
" > $registry

echo "
Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -HOST         => '$DBHOST',
    -PORT         => '$DBPORT',
    -USER         => '$DBUSER',
    -PASS         => '$DBPASS',
    -VERBOSE      => '1',
    -DB_VERSION   => '${ENSEMBL_RELEASE}',
    -WAIT_TIMEOUT => undef,
    -NO_CACHE     => undef,
    -DBNAME       => '${DBCORENAME}',
    -SPECIES      => '${SPECIES}',
);
" >> $registry

echo "
Bio::EnsEMBL::DBSQL::OntologyDBAdaptor->new(
    -HOST     => '$DBHOST',
    -PORT     => '$DBPORT',
    -USER     => '$DBUSER',
    -PASS     => '$DBPASS',
    -GROUP    => 'ontology',
    -SPECIES  => 'multi',
    -DBNAME   => '${DBNAME}',
);
" >> $registry

echo "
Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -HOST    => '$DBPRODHOST',
    -PORT    => '$DBPRODPORT',
    -USER    => '$DBPRODUSER',
    -DBNAME  => 'ensembl_production',
    -SPECIES => 'multi',
    -GROUP   => 'production',
  );
" >> $registry

echo "1;
}" >> $registry

echo "Creating EMBL files"
time standaloneJob.pl EGExt::FTP::Flatfile::RunnableDB::DumpFlatfile -reg_conf ${registry} -species schizosaccharomyces_pombe -type EMBL -dumps_dir ${dump_dir}

echo "Creating GenBank files"
time standaloneJob.pl EGExt::FTP::Flatfile::RunnableDB::DumpFlatfile -reg_conf ${registry} -species schizosaccharomyces_pombe -type GenBank -dumps_dir ${dump_dir}

echo "Creating GFF3 files"
#time standaloneJob.pl EGExt::FTP::Flatfile::RunnableDB::DumpFlatfile -reg_conf ${registry} -species schizosaccharomyces_pombe -type gff3 -dumps_dir ${dump_dir}
time standaloneJob.pl Bio::EnsEMBL::Production::Pipeline::GFF3::DumpFile -reg ${registry} -species schizosaccharomyces_pombe -eg 1 -dump_type gff3_genes -db_type core -per_chromosome 1 -include_scaffold 0 -feature_type "['Gene','Transcript','SimpleFeature']" -logic_name [] -eg_version ${EG_RELEASE} -sub_dir ${dump_dir} -out_file_stem gff3


