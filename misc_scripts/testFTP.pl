#!/usr/bin/env perl

use strict;
use warnings;
use IO::File;
use File::Basename;
use Getopt::Long;
use Test::Simple tests => (52*4);
#                  Files --^  ^-- Tests
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

my %testFiles = (
  'CDS_Coordinates' => ['chromosome1.cds.coords', 'chromosome2.cds.coords', 'chromosome3.cds.coords'],
  'Chromosome_contigs' => [
    'chromosome1.contig',
    'chromosome2.contig',
    'chromosome3.contig',
    'mating_type_region.contig',
    'pMIT.contig',
    'telomeric.contig'
  ],
  'Chromosome_Dumps/embl' => [
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.AB325691.embl",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.I.embl",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.II.embl",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.III.embl",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MT.embl",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MTR.embl"
  ],
  'Chromosome_Dumps/fasta' => [ 
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.AB325691.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.genome.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.I.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.II.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.III.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.MT.fa.gz",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.dna.MTR.fa.gz"
  ],
  'Chromosome_Dumps/genbank' => [ 
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.AB325691.genbank",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.I.genbank",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.II.genbank",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.III.genbank",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MT.genbank",
    "Schizosaccharomyces_pombe.ASM294v2.$eg_release.MTR.genbank"
  ],
  'Chromosome_Dumps/gff3' => [
    "schizosaccharomyces_pombe.I.gff3",
    "schizosaccharomyces_pombe.II.gff3",
    "schizosaccharomyces_pombe.III.gff3",
    "schizosaccharomyces_pombe.MT.gff3",
    "schizosaccharomyces_pombe.nonchromosomal.gff3"
  ],
  #'Complexes' => ['Complex_annotation'],
  #'Cosmid_assembly_data' => ['SP_chr1_dump.text', 'SP_chr2_dump.text', 'SP_chr3_dump.text'],
  'Exon_Coordinates' => ['chromosome1.exon.coords', 'chromosome2.exon.coords', 'chromosome3.exon.coords'],
  'Gene_ontology' => ['gene_association.pombase.gz'],
  'Mappings' => ['allNames.tsv', 'PomBase2UniProt.tsv', 'sysID2product.tsv'],
  'orthologs' => ['human-orthologs.txt.gz'],
  'Phenotype_annotations' => ['phenotype_annotations.pombase.phaf.gz'],
  'Protein_data' => ['PeptideStats.tsv'],
  'UTR' => ['5UTR.fa.gz', '3UTR.fa.gz'],
  '../FASTA' => [
    'cdna_introns_utrs.fa.gz',
    'cdna_nointrons_noutrs.fa.gz',
    'cdna_nointrons_utrs.fa.gz',
    'introns.fa.gz',
    'ncrna.fa.gz',
    'pep.fa.gz'
  ]
);


foreach my $subfolder ( keys %testFiles ) {
	foreach my $testfile ( @{ $testFiles{$subfolder} } ) {
		fileExists($rootDir . '/' . $subfolder . '/' . $testfile);
		fileSize($rootDir . '/' . $subfolder . '/' . $testfile);
		fileDate($rootDir . '/' . $subfolder . '/' . $testfile);
		fileType($rootDir . '/' . $subfolder . '/' . $testfile);
	}
}


#
# Tests
#
sub fileExists {
  my ( $fileDir ) = @_;
  ok( -e($fileDir), "$fileDir exists" );
}
sub fileSize {
  my ( $fileDir ) = @_;
  ok( -s($fileDir) > 0, "$fileDir file size" );
}
sub fileDate {
  my ( $fileDir ) = @_;
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($fileDir);
  ok( time-$mtime <= 604800, "$fileDir current" );
}
sub fileType {
  my ( $fileDir ) = @_;
  my($filename, $directories, $suffix) = fileparse($fileDir, qr/\.[^.]*/);
  my $actualResult = -B($fileDir);
  if ( $suffix ne '.gz' ) {
  	ok( -T($fileDir) > 0, "$fileDir $suffix ASCII" );
  } else {
    if ( -e($fileDir) ) {
      ok( -B($fileDir) > 0, "$fileDir $suffix BINARY" );
    } else {
    	ok( -e($fileDir), "$fileDir BINARY does not exist" );
    }
  }
}
