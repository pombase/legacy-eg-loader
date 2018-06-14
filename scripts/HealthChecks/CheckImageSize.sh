#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check all image files are larger than 500b"

cd ../../data/images
c=$(find . -type f -size -500c | wc -l)

if [ ${c} -gt 0 ]
then
  echo "  FAILED"
  echo "  There are ${c} images have not been correctly generated"
  echo ""
  echo "  RESULTS"
  echo "  The following file contains the missing Gene Stable IDs:"
  echo "  ../../data/tmp/missingImages.csv"
  find . -type f -size -500c | grep -o "SP[A-Z0-9]*.[a-Z0-9]*" | sort | uniq | while read gid; do echo -n "$gid "; done > ../tmp/missingImages.csv
else
  echo "PASSED"
fi
