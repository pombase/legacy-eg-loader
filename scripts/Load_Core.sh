#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv
mkdir -p ../data/tmp

bsub -q production-rh6 -o $PL/data/tmp -e $PL/data/tmp -J "spombe[1-6]%10" "sh Load_Chromosome.sh"
