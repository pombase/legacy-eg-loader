#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that exons, 5\' and 3\'UTR regions do not overlap in the db before loading gene models."
c=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "select count(*) from feature f1 join cvterm ft1 on (f1.type_id=ft1.cvterm_id) join featureloc fl1 on (f1.feature_id=fl1.feature_id) join feature_relationship fr1 on (f1.feature_id=fr1.subject_id) join cvterm frt1 on (fr1.type_id=frt1.cvterm_id) join feature f2 on (fr1.object_id=f2.feature_id) join cvterm ft2 on (f2.type_id=ft2.cvterm_id) join feature_relationship fr2 on (f2.feature_id=fr2.object_id) join cvterm frt2 on (fr2.type_id=frt2.cvterm_id) join feature f3 on (fr2.subject_id=f3.feature_id) join cvterm ft3 on (f3.type_id=ft3.cvterm_id) join featureloc fl3 on (f3.feature_id=fl3.feature_id) where f1.feature_id!=f3.feature_id and frt1.name='part_of' and frt2.name='part_of' and ft1.name in ('exon', 'five_prime_UTR', 'three_prime_UTR') and ft3.name in ('exon', 'five_prime_UTR', 'three_prime_UTR') and fl1.fmin < fl3.fmin and fl1.fmax>fl3.fmin;"`
if [ $c -gt 0 ]
then
  echo "  FAILED"
  echo "  Raise issue with the curators to fix this in the Chado db before continuing!"
  echo "  Use the following SQL to identify the regions that are failing:"
  echo "  select f1.feature_id, f1.uniquename, ft1.name, frt1.name, fl1.fmin, fl1.fmax, f2.uniquename, ft2.name, frt2.name, f3.feature_id, f3.uniquename, ft3.name, fl3.fmin, fl3.fmax from feature f1 join cvterm ft1 on (f1.type_id=ft1.cvterm_id) join featureloc fl1 on (f1.feature_id=fl1.feature_id) join feature_relationship fr1 on (f1.feature_id=fr1.subject_id) join cvterm frt1 on (fr1.type_id=frt1.cvterm_id) join feature f2 on (fr1.object_id=f2.feature_id) join cvterm ft2 on (f2.type_id=ft2.cvterm_id) join feature_relationship fr2 on (f2.feature_id=fr2.object_id) join cvterm frt2 on (fr2.type_id=frt2.cvterm_id) join feature f3 on (fr2.subject_id=f3.feature_id) join cvterm ft3 on (f3.type_id=ft3.cvterm_id) join featureloc fl3 on (f3.feature_id=fl3.feature_id) where f1.feature_id!=f3.feature_id and frt1.name='part_of' and frt2.name='part_of' and ft1.name in ('exon', 'five_prime_UTR', 'three_prime_UTR') and ft3.name in ('exon', 'five_prime_UTR', 'three_prime_UTR') and fl1.fmin < fl3.fmin and fl1.fmax>fl3.fmin;"
else
  echo "PASSED"
fi
