#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check image request responses for non 200 HTTP response codes"

cd ../../data/tmp
c=$(grep ERRORs\ in\ Gene\ Models *.out | sed "s/\tNo.\ of\ ERRORs\ in\ Gene\ Models:\ //" | wc -l)

if [ ${c} -gt 0 ]
then
  echo "  FAILED"
  echo "  There are ${c} cluster output files that have identified ERRORs in the loading process"
  echo ""
  grep ERRORs\ in\ Gene\ Models *.out
else
  echo "PASSED"
fi
