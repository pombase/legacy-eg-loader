#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../../SetEnv

echo "HC: Check that terms have a child equal to themselves in the closure tables of the egontology BioMart."

sql_eg=""
sql_pg=""

declare -A chr2chr
chr2chr=(["chromosome_1"]="I" ["chromosome_2"]="II" ["chromosome_3"]="III" ["MISPCG"]="MT" ["mating_type_region"]="MTR" ["AB325691"]="AB325691")

testsFailed=0
for chr in chromosome_1 chromosome_2 chromosome_3 MISPCG mating_type_region AB325691
do
  echo "  Checking ${chr} ..."
  for s in published biological_role_inferred conserved_unknown sequence_orphan fission_yeast_specific_family dubious transposon "Schizosaccharomyces pombe specific family" "Schizosaccharomyces specific family"
  do
    #echo "    Counts for ${s} ..."
    #echo "    ${chr} - ${chr2chr["$chr"]}"
    eg=`mysql -u$DBUSER -p$DBPASS -h$DBHOST -P$DBPORT $DBCORENAME -s -N -e "select count(*) from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) where seq_region.name='${chr2chr[$chr]}' AND gene.biotype='protein_coding' AND gene.status='${s}';"`
    pg=`psql --username $DBPGUSER --host $DBPGHOST --port $DBPGPORT $DBPGNAME -t -A -c "select count(distinct f.uniquename) from feature f join featureloc fl on (f.feature_id=fl.feature_id) join feature flf on (fl.srcfeature_id=flf.feature_id) join feature_cvterm fc on (f.feature_id=fc.feature_id) join cvterm fcc on (fc.cvterm_id=fcc.cvterm_id) join cv fcccv on (fcc.cv_id=fcccv.cv_id) where fcccv.name='PomBase gene characterisation status' AND flf.uniquename='${chr}' AND fcc.name='${s}';"`
    #echo "    Result: ${eg} - ${pg}"
    if [ "$eg" -ne "$pg" ]
    then
      echo "    Mismatch: ${s} - ${eg} vs ${pg}"
      echo "    ---------------------"
      echo "    Use the following SQL to start to identify the erroneous genes"
      echo "    Genes from ${DBPGNAME}:"
      echo "      select f.uniquename from feature f join featureloc fl on (f.feature_id=fl.feature_id) join feature flf on (fl.srcfeature_id=flf.feature_id) join feature_cvterm fc on (f.feature_id=fc.feature_id) join cvterm fcc on (fc.cvterm_id=fcc.cvterm_id) join cv fcccv on (fcc.cv_id=fcccv.cv_id) where fcccv.name='PomBase gene characterisation status' AND flf.uniquename='${chr}' AND fcc.name='${s}';"
      echo "    Genes from ${DBCORENAME}:"
      echo "      select gene.stable_id from gene join seq_region on (gene.seq_region_id=seq_region.seq_region_id) where seq_region.name='${chr2chr[$chr]}' AND gene.biotype='protein_coding' AND gene.status='${s}';"
      testsFailed=`expr $testsFailed + 1`
    fi
  done
done

if [ $testsFailed -gt 0 ]
then
  echo "  FAILED"
  echo "  ------"
  echo "  Check the annotation status of the genes in the gene between Chado and ensembl"
  echo "  There may be cases were the gene has been newly introduced in Chado, but is"
  echo "  not present in the ensembl db due to conflicts with the compara. In these"
  echo "  cases the new gene will get picked up next time the core is reloaded from"
  echo "  scratch. This should be rare."
else
  echo "PASSED"
fi
