#!/bin/bash --

#
# This script needs to be executeed on treason.
# If not on treason the exit with relevant message.
#
if [ "$USER" != "w3_ens01" ]; then
  echo "Needs to be logged in as w3_ens01 to run this script"
  exit 1
fi

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

sql="select * from variable where name like '%_division' and value != 's:13:\"genomebrowser\";';"

echo "HC: Check that dev points to the live genome browser and BioMart"
c=`mysql -u$DBDRUPALUSER -p$DBDRUPALPASS -h$DBDRUPALHOST -P$DBDRUPALPORT $DBDRUPALNAME -N -e "${sql}"`

if [ ${#c} -gt 0 ]
then
  echo "  FAILED"
  echo "  The divisional directions for for dev are not pointing towards that live site"
  echo "  Correct this before "
  echo ""
  echo "  RESULTS"
  mysql -u$DBDRUPALUSER -p$DBDRUPALPASS -h$DBDRUPALHOST -P$DBDRUPALPORT $DBDRUPALNAME -e "${sql}"
  exit 1
else
  echo "  PASSED"
  echo "  Syncing dev to live ..."
  /nfs/public/rw/ensembl/drupal/bin/sync-files.sh pombase.org 6
  /nfs/public/rw/ensembl/drupal/bin/sync-db.pl pombase.org 6
fi
