#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;

use Data::Dumper;

use Getopt::Long;

use IO::File;
#use Time::Local;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;

## Create a config
#my $config = Config::Tiny->new();
#
## Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );
#
## Reading properties
#my $ensembldb = $config->{Spombe_2};

my $genes      = '';
my $eg_host    = '';
my $eg_port    = '';
my $eg_user    = '';
my $eg_pass    = '';
my $eg_species = '';
my $eg_dbname  = '';

sub usage {
    print "Usage:\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> : Using $eg_host\n";
    print "-eg_port <4207> : Using $eg_port\n";
    print "-eg_user <ensro> : Using $eg_user\n";
    print "-eg_pass <xxxxx> : Using $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> : Using $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> : Using $eg_dbname\n";
    print "-genes <SPAC2F7.03c> : Using $genes\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "genes=s"      => \$genes,
                               "help"         => sub {usage()});

if ( !$eg_host or !$eg_port or !$eg_user or !$eg_pass or
     !$eg_species or !$eg_dbname or !$genes
   ) {
    usage();
}

if(!$options_okay) {
    usage();
}

my $db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    '-host'    => $eg_host,
    '-port'    => $eg_port,
    '-user'    => $eg_user,
    '-group'   => "core",
    '-species' => $eg_species,
    '-dbname'  => $eg_dbname,
    '-pass'    => $eg_pass
);

my $gene_adaptor = $db->get_adaptor('Gene');
my @gene_list = split(/,/, $genes);

open my ($all_nointrons_noutrs), '>', 'data/tmp/cdna_nointrons_noutrs_ge100k.fa' or die;

foreach my $gene_id ( @gene_list ) {
	my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
	my @transcripts = @{ $gene->get_all_Transcripts };
	
	foreach my $transcript (@transcripts) {
		my $fasta_head_transcript = '>' . $gene->stable_id . "\n";
		
		# CDS without introns and without UTRs
	    my @rna_seq = @{ getSeq($gene, 'exclude', 'exclude') };
	    foreach my $sh (@rna_seq) {
	        my %s = %{$sh};
	        if ($s{'name'} eq $transcript->stable_id) {
	            my @seq = $s{'seq'} =~ /(.{1,60})/g;
	            my $fasta_str = $fasta_head_transcript . join("\n", @seq) . "\n\n";
	            print $all_nointrons_noutrs $fasta_str
	        }
	    }
	}
}

close($all_nointrons_noutrs);


sub getSeq {
  my ($gene, $utr, $intron)  = @_;
  
  my $sa = $db->get_adaptor('Slice');
  
  my @seq;
  
  my @transcript_seq;
  my @transcripts = @{ $gene->get_all_Transcripts };
  foreach my $transcript (@transcripts) {
      push @seq, {name => $transcript->stable_id, seq => $transcript->translateable_seq()};
  }
  
  return \@seq;
}
