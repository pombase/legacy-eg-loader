#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

sql="select * from variable where name like '%_division' and value != 's:13:\"genomebrowser\";';"

echo "HC: Check that dev points to the live genome browser and BioMart"
c=`mysql -u$DBDRUPALUSER -p$DBDRUPALPASS -h$DBDRUPALHOST -P$DBDRUPALPORT $DBDRUPALNAME -N -e "${sql}"`

if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo "  The divisional directions for for dev are not pointing towards that live site"
  echo ""
  echo "  RESULTS"
  mysql -u$DBDRUPALUSER -p$DBDRUPALPASS -h$DBDRUPALHOST -P$DBDRUPALPORT $DBDRUPALNAME -e "${sql}"
else
  echo "PASSED"
fi
