#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

#if ! [ "$HOSTNAME" =~ "ebi.ac.uk" ]
#then
#  echo "WARNING: It is best to run this on an ebi login node or bshell"
#  exit 10
#fi

DBHOSTSERVER=${DBPOMBEHOST}
case "$1" in
  oy)
    DBHOSTSERVER=${DBPOMBEHOSTOY}
    ;;
  pg)
    DBHOSTSERVER=${DBPOMBEHOSTPG}
    ;;
  *)
    DBHOSTSERVER=${DBPOMBEHOST}
    ;;
esac

mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT  ensembl_compara_fungi_${EG_RELEASE}_${ENSEMBL_RELEASE} -N -e 'show tables' | while read table; do echo "Optimizing $table ..."; mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT ensembl_compara_fungi_${EG_RELEASE}_${ENSEMBL_RELEASE} -e "optimize table $table;"; done
mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT  ensembl_compara_pan_homology_${EG_RELEASE}_${ENSEMBL_RELEASE} -N -e 'show tables' | while read table; do echo "Optimizing $table ..."; mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT ensembl_compara_pan_homology_${EG_RELEASE}_${ENSEMBL_RELEASE} -e "optimize table $table;"; done

for sp in schizosaccharomyces_cryophilus schizosaccharomyces_japonicus schizosaccharomyces_octosporus schizosaccharomyces_pombe
do
  DBCORENAME="${sp}_core_${EG_RELEASE}_${ENSEMBL_RELEASE}_${ASSEMBLY}"
  mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT $DBCORENAME -N -e "show tables;" | while read table; do echo "Optimizing $table ..."; mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT $DBCORENAME -e "optimize table $table;"; done
done

mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT schizosaccharomyces_pombe_variation_${EG_RELEASE}_${ENSEMBL_RELEASE}_${ASSEMBLY} -N -e 'show tables' | while read table; do echo "Optimizing $table ..."; mysql -u$DBPOMBEUSER -p$DBPOMBEPASS -h$DBHOSTSERVER -P$DBPOMBEPORT schizosaccharomyces_pombe_variation_${EG_RELEASE}_${ENSEMBL_RELEASE}_${ASSEMBLY} -e "optimize table $table;"; done
