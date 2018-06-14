#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
mkdir -p ../data/tmp

echo "Submission time: $(date)"
bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "dmpChrPom[1-6]%10" "sh DumpJSONCacheRunner.sh"

