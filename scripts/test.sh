#!/bin/bash 

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

test1=
test2=
test3=

while getopts "t:u:v:" opt; do
  case $opt in
  t)
    echo "-t was triggered, Parameter: $OPTARG" >&2
    test1=$OPTARG
    ;;
  u)
    echo "-u was triggered, Parameter: $OPTARG" >&2
    test2=$OPTARG
    ;;
  v)
    echo "-v was triggered, Parameter: $OPTARG" >&2
    test3=$OPTARG
    ;;
  esac
done

shift $((OPTIND - 1))

echo "t: $test1"
echo "u: $test2"
echo "v: $test3"

cd ..

FULL_DIR=$(cd $(dirname "$0"); pwd)/data/search

echo $MY_DIR
echo $FULL_DIR
echo $EG_RELEASE
echo $ENSEMBL_RELEASE
echo $PB_RELEASE
echo $PB_VERSION
echo $DBNAME

