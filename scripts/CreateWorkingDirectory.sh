#!/bin/bash --

dir=$1
if [ -z "$dir" ]; then
  echo "Usage: $0 <dir> <eg_release> <ensembl_release>" 1>&2
  exit 1
fi

EG_RELEASE=$2
ENSEMBL_RELEASE=$3
if [ -z "$EG_RELEASE" ]; then
  echo "Usage: $0 <dir> <eg_release> <ensembl_release>" 1>&2
  exit 1
fi

if [ -z "$ENSEMBL_RELEASE" ]; then
  echo "Usage: $0 <dir> <eg_release> <ensembl_release>" 1>&2
  exit 1
fi

mkdir -p $dir

cd $dir

git clone https://github.com/Ensembl/ensembl-git-tools.git
export PATH=$PWD/ensembl-git-tools/bin:$PATH

#[api] - API module set used for querying and processing Ensembl data
#	ensembl
#	ensembl-compara
#	ensembl-funcgen
#	ensembl-variation
git ensembl --clone --branch master api


git clone https://github.com/Ensembl/ensembl-analysis.git
git clone https://github.com/Ensembl/ensembl-hive.git
git clone https://github.com/Ensembl/ensembl-orm.git
git clone https://github.com/Ensembl/ensembl-pipeline.git
git clone https://github.com/Ensembl/ensembl-production.git
git clone https://github.com/Ensembl/ensembl-rest.git
git clone https://github.com/Ensembl/ensembl-tools.git
git clone https://github.com/Ensembl/ensembl-webcode.git
git clone https://github.com/Ensembl/ensj-healthcheck.git

git clone https://github.com/EnsemblGenomes/ensemblgenomes-api.git
git clone https://github.com/EnsemblGenomes/eg-web-common.git
git clone https://github.com/EnsemblGenomes/eg-web-pombase.git

git clone https://${USER}@scm.ebi.ac.uk/git/eg-analysis.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-biomart.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-ena.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-pipelines.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-projectgoterms.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-proteinfeature.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-release.git
git clone https://${USER}@scm.ebi.ac.uk/git/eg-utils.git

git ensembl --checkout --branch master all

cd ensj-healthcheck
ln -s /nfs/panda/ensemblgenomes/apis/ensembl/master/ perlcode

cd ..
sh eg-utils/bin/create_setup_script.sh $EG_DIR

