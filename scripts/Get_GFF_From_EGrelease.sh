#!/bin/bash --

# Set the required variables.
MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

mkdir -p ../data/FTP
cd ../data/FTP

# Get the dump from the remote server and extract
cp ../tmp/${SPECIES}.*.gff3 .

for f in `ls *.gff3`; do
  #echo "Before -> $f"
  new=`echo "$f" | sed -e "s/chromosome.//"`
  #echo "After -> $new"
  mv $f $new
done

ls *.gff3

