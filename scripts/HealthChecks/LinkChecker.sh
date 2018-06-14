#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Test that only the allowed files are present in the FTP directory."
echo "    Any extra files are listed below:"

testURL=$(lynx -dump http://eg-pombase:eg-pombase@dev.pombase.org/spombe/result/SPAC2F7.03c -auth=eg-pombase:eg-pombase | grep -A999 "^References$" | tail -n +3 | awk '{print $2 }' | grep http | uniq)

for url in ${testURL}
do
  c=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' ${url})
  
  if [ ${c} -gt 399 ]
  then
    echo "  FAILED ==> ${c} : ${url}"
  fi
  
  sleep 0.5
done
