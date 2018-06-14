#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that . pages in the eg-web-pombase web server plugins work. This is especially important for ensembl updates"

testsFailed=0
for o in GOSlimTerms test blastview
do
  echo "Checking ${o} ..."
  echo "  http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/${o}"
  c=`curl -s -o /dev/null -w "%{http_code}" http://test.genomebrowser.pombase.org/Schizosaccharomyces_pombe/$o`
  #c=`expr $c + 0`
  res="$( [[ $c -gt 299 ]]; echo $? )"
  if [ $res == "0" ]
  then
    echo "  Response Code: ${c}"
    testsFailed=1
  fi
done

if [ $testsFailed == "1" ]
then
  echo "###################################################"
  echo "#################    FAILED   #####################"
  echo "###################################################"
  echo "#   Check the code in the eg-web-pombase plugin!  #"
  echo "###################################################"
else
  echo "PASSED"
fi
