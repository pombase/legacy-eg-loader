#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use File::Basename;
use Getopt::Long;
#use Test::Simple tests => (67*4);

my $rootDir = "";
my $eg_release = 21;

sub usage {
  print "Usage: $0 [-rootDir <obo>]\n";
  print "-eg_release <21> Default is $eg_release\n",
  print "-help \n";
  exit 1;
};

my $options_okay = GetOptions ("rootDir=s"    => \$rootDir,
                               "eg_release=i" => \$eg_release,
                               "help"  => sub {usage()});

if(!$options_okay) {
  usage();
}

my @testFiles = (
	  'chromosome1.cds.coords',
	  'chromosome2.cds.coords',
	  'chromosome3.cds.coords',
	  'chromosome1.contig',
	  'chromosome2.contig',
	  'chromosome3.contig',
	  'mating_type_region.contig',
	  'pMIT.contig',
	  'telomeric.contig',
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.AB325691.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.AB325691.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.AB325691.gff3",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.AB325691.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.genome.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.I.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.II.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.III.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.MT.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.MTR.fa.gz",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.I.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.I.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.I.gff3",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.II.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.II.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.II.gff3",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.III.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.III.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.III.gff3",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MT.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MT.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MT.gff3",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MTR.embl",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MTR.genbank",
	  "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MTR.gff3",
	  'Complex_annotation',
	  'SP_chr1_dump.text', 'SP_chr2_dump.text', 'SP_chr3_dump.text',
	  'chromosome1.exon.coords', 'chromosome2.exon.coords', 'chromosome3.exon.coords',
	  'gene_association.pombase.gz',
	  'allNames.tsv', 'PomBase2UniProt.tsv', 'sysID2product.tsv', 'sysID2product.rna.tsv', 'gp2EC.txt',
	  'human-orthologs.txt.gz',
	  'phenotype_annotations.pombase.phaf.gz', 'FYPOviability.tsv',
	  'PeptideStats.tsv', 'Protein_Features.tsv', 'aa_composition.tsv', 'pombase-chado-v57-2016-01-27.modifications.gz',
	  '5UTR.fa.gz', '3UTR.fa.gz', 'UTR_README.txt',
      'cdna_introns_utrs.fa.gz',
      'cdna_nointrons_noutrs.fa.gz',
      'cdna_nointrons_utrs.fa.gz',
      'introns.fa.gz',
      'ncrna.fa.gz',
      'pep.fa.gz',
      'README'
);

my @ignoreFiles = ('.', '..', 'OLD');

my @testFolders = (
    'pombe/CDS_Coordinates',
    'pombe/Chromosome_contigs',
    'pombe/Chromosome_Dumps',
    'pombe/Complexes',
    #'pombe/Cosmid_assembly_data',
    'pombe/Exon_Coordinates',
    'pombe/Gene_ontology',
    'pombe/Mappings',
    'pombe/orthologs',
    'pombe/Phenotype_annotations',
    'pombe/Protein_data',
    'pombe/UTR',
    'FASTA'
);


my %testHash;
foreach my $subfolder ( @testFolders ) {
	opendir(my $dh, $rootDir . '/' . $subfolder) || die "Can't open $rootDir/$subfolder";
	while ( readdir $dh ) {
		if ( $_ ~~ @ignoreFiles ) {
			next;
		}
		if ( $_ ~~ @testFiles ) {
			next;
		} else {
		    print "$rootDir/$subfolder/$_\n";
		}
	}
	
}

