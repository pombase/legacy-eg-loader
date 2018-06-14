#!/bin/bash --

MY_DIR=`dirname $0`
source $MY_DIR/../SetEnv

cd ..
mkdir -p data/tmp/bindingMotif
mkdir -p data/FTP
EG_VERSION=30
cd data/tmp/bindingMotif
rm *
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/release-$EG_VERSION/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.chromosome.I.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.I.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/release-$EG_VERSION/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.chromosome.II.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.II.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/release-$EG_VERSION/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.chromosome.III.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.III.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/release-$EG_VERSION/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.chromosome.MT.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.MT.fa.gz
wget "ftp://ftp.ensemblgenomes.org/pub/fungi/release-$EG_VERSION/fasta/schizosaccharomyces_pombe/dna/Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.toplevel.fa.gz" -O Schizosaccharomyces_pombe.ASM294v2.$EG_VERSION.dna.genome.fa.gz

gunzip *

cd ../../../

python misc_scripts/GenerateBindingSitTracks.py

cat data/tmp/bindingMotif/binding_motifs_chrI.bed > data/tmp/bindingMotif/binding_motifs_pre.bed
cat data/tmp/bindingMotif/binding_motifs_chrII.bed >> data/tmp/bindingMotif/binding_motifs_pre.bed
cat data/tmp/bindingMotif/binding_motifs_chrIII.bed >> data/tmp/bindingMotif/binding_motifs_pre.bed
cat data/tmp/bindingMotif/binding_motifs_chrMT.bed >> data/tmp/bindingMotif/binding_motifs_pre.bed
sort -k1,1 -k2,2n data/tmp/bindingMotif/binding_motifs_pre.bed > data/FTP/binding_motifs.bed


