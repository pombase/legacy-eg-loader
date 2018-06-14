#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

echo $HOSTNAME
if ! [[ "$HOSTNAME" =~ "ebi.ac.uk" ]]
then
  echo "WARNING: You need to be on an ebi login node"
  exit 10
fi

TO_SERVER=$1
if [ -z "$TO_SERVER" ]; then
  echo "Usage: $0 <dir> <to_server>" 1>&2
  exit 1
fi

EG_RELEASE_OLD=$((EG_RELEASE-1))
ENSEMBL_RELEASE_OLD=$((ENSEMBL_RELEASE-1))

if [ $TO_SERVER == "staging2" ]
then
  echo "Moving dbs from mysql-staging-1 to mysql-staging-2"
  sh process_division.sh EF | grep core | sort | while read newdb; do olddb=$(echo $newdb | sed "s/_${EG_RELEASE}_${ENSEMBL_RELEASE}_/_${EG_RELEASE_OLD}_${ENSEMBL_RELEASE_OLD}_/"); echo "Creating ${newdb} ..."; mysql-staging-2 test -e "create database ${newdb};"; echo "Copying ${olddb} ==> ${newdb}"; mysql-staging-1 mysqldump ${olddb} | mysql-staging-2 ${newdb}; done
  sh process_division.sh EF | grep otherfeatures | sort | while read newdb; do olddb=$(echo $newdb | sed "s/_${EG_RELEASE}_${ENSEMBL_RELEASE}_/_${EG_RELEASE_OLD}_${ENSEMBL_RELEASE_OLD}_/"); echo "Creating ${newdb} ..."; mysql-staging-2 test -e "create database ${newdb};"; echo "Copying ${olddb} ==> ${newdb}"; mysql-staging-1 mysqldump ${olddb} | mysql-staging-2 ${newdb}; done
elif [ $TO_SERVER == "staging1" ]
then
  echo "Moving dbs from mysql-staging-2 to mysql-staging-1"
  sh process_division.sh EF | grep core | sort | while read newdb; do olddb=$(echo $newdb | sed "s/_${EG_RELEASE}_${ENSEMBL_RELEASE}_/_${EG_RELEASE_OLD}_${ENSEMBL_RELEASE_OLD}_/"); echo "Creating ${newdb} ..."; mysql-staging-1 test -e "create database ${newdb};"; echo "Copying ${olddb} ==> ${newdb}"; mysql-staging-2 mysqldump ${olddb} | mysql-staging-1 ${newdb}; done
  sh process_division.sh EF | grep otherfeatures | sort | while read newdb; do olddb=$(echo $newdb | sed "s/_${EG_RELEASE}_${ENSEMBL_RELEASE}_/_${EG_RELEASE_OLD}_${ENSEMBL_RELEASE_OLD}_/"); echo "Creating ${newdb} ..."; mysql-staging-1 test -e "create database ${newdb};"; echo "Copying ${olddb} ==> ${newdb}"; mysql-staging-2 mysqldump ${olddb} | mysql-staging-1 ${newdb}; done
fi

