#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check image request responses for non 200 HTTP response codes"

cd ../../data/tmp
c=$(grep HTTP\ request\ sent *.out | grep -v OK | wc -l)

if [ ${c} -gt 0 ]
then
  echo "  FAILED"
  echo "  There are ${c} non 200 HTTP reponse codes in the output files"
  echo ""
  grep HTTP\ request\ sent *.out | grep -v OK
else
  echo "PASSED"
fi
