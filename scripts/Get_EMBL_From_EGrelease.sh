#!/bin/bash --

# Set the required variables.
MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

# Get the dump from the remote server and extract
#wget "ftp://ftp.ensemblgenomes.org/pub/release-${EG_RELEASE}/fungi/embl/${SPECIES}/${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.dat.gz"

cp ../tmp/fungi/EMBL/${SPECIES}/${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.dat.gz .

gunzip ${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.dat.gz

csplit --prefix=${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE} -b '.%02d.embl' ${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.dat "/ID   /" "{*}"

rm ${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.dat

fname=''
for f in `grep ID\ \ \  *.embl`; do
  if [[ $f == 'I' || $f == 'II' || $f == 'III' || $f == 'MT' || $f == 'MTR' || $f == 'AB325691' ]]
  then
    if [[ $fname != '' ]]
    then
      echo "mv $fname ${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.$f.embl"
      grep -v "GO:" $fname > $fname.1
      grep -v "FYPO:" $fname.1 > $fname.2
      grep -v "PBO:" $fname.2 > $fname.3
      grep -v "MOD:" $fname.3 > ${SPECIES2}.${ASSEMBLY_NAME}.${EG_RELEASE}.$f.embl
      rm $fname*
      fname=''
    fi
  elif [[ $f == ${SPECIES2}* ]]
  then
    arr=$(echo $f | tr ":" "\n")
    for ff in $arr; do
      fname=$ff
      break
    done
  fi
  #echo "test -> $f"
done

rm *.${EG_RELEASE}.00.embl
