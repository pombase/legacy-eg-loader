#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use JSON qw(to_json);
use Carp;
use IO::File;
#use Config::Tiny;
use Getopt::Long;
use Data::Dumper;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;
use Bio::EnsEMBL::Attribute;

use PomLoader::FeatureLocation;


## Create a config
#my $config = Config::Tiny->new();
#
## Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );
#
## Reading properties
#my $ensembldb = $config->{Spombe_2};

my $eg_host    = 'mysql-eg-devel-2.ebi.ac.uk';
my $eg_port    = '4207';
my $eg_user    = 'ensrw';
my $eg_pass    = 'xxxxx';
my $eg_species = 'schizosaccharomyces_pombe';
my $eg_dbname  = 'schizosaccharomyces_pombe_core_21_74_2';

sub usage {
    print "Usage:\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> Default is $eg_host\n";
    print "-eg_port <4207> Default is $eg_host\n";
    print "-eg_user <ensro> Default is $eg_user\n";
    print "-eg_pass <xxxxx> Default is $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> Default is $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> Default is $eg_dbname\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "help"         => sub {usage()});

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

#
# Create a hash of all Chromosome slices
#
my $slice_adaptor = $db->get_adaptor('Slice');
my $chr_slices = $slice_adaptor->fetch_all( 'chromosome' );

my %chromosomes = ();

# open my ($all_genes), '>>', '/nfs/nobackup/ensemblgenomes/mcdowall/PomBase_EG13_FASTA/all.fa' or die;
open my ($all_nointrons_noutrs), '>', 'data/FTP/cdna_nointrons_noutrs.fa' or die;
open my ($all_nointrons_utrs), '>', 'data/FTP/cdna_nointrons_utrs.fa' or die;
open my ($all_introns_utrs), '>', 'data/FTP/cdna_introns_utrs.fa' or die;
open my ($ncrna_genes), '>', 'data/FTP/ncrna.fa' or die;
open my ($proteins), '>', 'data/FTP/pep.fa' or die;
open my ($introns), '>', 'data/FTP/introns.fa' or die;
open my ($utr5), '>', 'data/FTP/5UTR.fa' or die;
open my ($utr3), '>', 'data/FTP/3UTR.fa' or die;
 

my $count=0;
foreach my $slice ( @{ $chr_slices } ) {
    my @genes = @{ $slice->get_all_Genes };
    # >EG:SPAC212.11.1:pep pep:known chromosome:EF2:I:1:5662:-1 gene:SPAC212.11 transcript:SPAC212.11.1 gene-name:AAAAAA 
    # >SPAC110.03|1916054|1917656|cdc42|I
    foreach my $gene ( @genes ) {
        my $five_prime_pub  = '';
        my $three_prime_pub = '';
        my %five_prime_pubs  = ();
        my %three_prime_pubs = ();
        foreach my $dbentry (@{$gene->get_all_DBEntries()}) {
          if ($dbentry->dbname eq 'PUBMED_POMBASE') {
            if ($dbentry->info_text =~ /^five_prime_UTR.+/ and !exists($five_prime_pubs{$dbentry->display_id})) {
              $five_prime_pub .= $dbentry->display_id . ',';
              $five_prime_pubs{$dbentry->display_id} = 1;
            } elsif ($dbentry->info_text =~ /^three_prime_UTR.+/ and !exists($three_prime_pubs{$dbentry->display_id})) {
              $three_prime_pub .= $dbentry->display_id . ',';
              $three_prime_pubs{$dbentry->display_id} = 1;
            }
          }
        }
        
        $five_prime_pub  =~ s/,$//;
        $three_prime_pub =~ s/,$//;
        
        if (length $five_prime_pub > 0) {
          $five_prime_pub = '|' . $five_prime_pub;
        }
        if (length $three_prime_pub > 0) {
          $three_prime_pub = '|' . $three_prime_pub;
        }
        
        my @transcripts = @{ $gene->get_all_Transcripts };
        my $new_desc = $gene->description;
        if ( defined $new_desc ) {
          if (length $new_desc > 0) {
            ($new_desc = $gene->description) =~ s/\ \[Source:.*;Acc:.+\]$//;
          }
        }
        foreach my $transcript (@transcripts) {
            my $fasta_head = '>' . $gene->stable_id;
            $fasta_head .= '|' . $gene->start . '|' . $gene->end . '|' . $gene->strand;
            $fasta_head .= '|' . $gene->external_name;
            $fasta_head .= '|' . $gene->chr_name . '|' . $gene->biotype;
            $fasta_head .= '|' . $new_desc . "\n";
            
            my $fasta_head_pep = '>' . $gene->stable_id;
            $fasta_head_pep .= '|' . $gene->external_name;
            $fasta_head_pep .= '|' . $gene->chr_name; 
            $fasta_head_pep .= '|' . $new_desc . "\n";

            my $fasta_head_transcript = '>' . $gene->stable_id;
            $fasta_head_transcript .= '|' . $transcript->stable_id;
            $fasta_head_transcript .= '|' . $gene->start . '|' . $gene->end . '|' . $gene->strand;
            $fasta_head_transcript .= '|' . $gene->external_name;
            $fasta_head_transcript .= '|' . $gene->chr_name . '|' . $gene->biotype;
            $fasta_head_transcript .= '|' . $new_desc . "\n";
            
            my $fasta_head_intron = '>' . $gene->stable_id;
            $fasta_head_intron .= '|' . $transcript->stable_id;
            $fasta_head_intron .= '|' . $gene->start . '|' . $gene->end . '|' . $gene->strand;
            $fasta_head_intron .= '|' . $gene->external_name;
            $fasta_head_intron .= '|' . $gene->chr_name . '|' . $gene->biotype;
            $fasta_head_intron .= '|' . $new_desc . "\n";
            
#            my $fasta_head_utr5 = '>' . $gene->stable_id;
#            $fasta_head_utr5 .= '|' . $transcript->stable_id;
#            $fasta_head_utr5 .= '|' . $gene->start . '|' . $gene->end . '|' . $gene->strand;
#            $fasta_head_utr5 .= '|' . $gene->external_name;
#            $fasta_head_utr5 .= '|' . $gene->chr_name . '|' . $gene->biotype;
#            $fasta_head_utr5 .= '|' . $new_desc;
#            $fasta_head_utr5 .= '|' . $five_prime_pub . "\n";
            
#            my $fasta_head_utr3 = '>' . $gene->stable_id;
#            $fasta_head_utr3 .= '|' . $transcript->stable_id;
#            $fasta_head_utr3 .= '|' . $gene->start . '|' . $gene->end . '|' . $gene->strand;
#            $fasta_head_utr3 .= '|' . $gene->external_name;
#            $fasta_head_utr3 .= '|' . $gene->chr_name . '|' . $gene->biotype;
#            $fasta_head_utr3 .= '|' . $new_desc;
#            $fasta_head_utr3 .= '|' . $three_prime_pub . "\n";
            
            my @seq = $transcript->seq->seq() =~ /(.{1,60})/g;
            my $fasta_str = $fasta_head . join("\n", @seq) . "\n\n";
            
            
            foreach my $intron ( @{ $transcript->get_all_Introns() } ) {
                my $start      = $intron->start();
                my $end        = $intron->end();
                my $strand     = $intron->strand();
                my $seq_region = $gene->chr_name . '|' . $gene->biotype;
                my @intron_seq = $intron->seq() =~ /(.{1,60})/g;
                print $introns sprintf(">%s|%s|%d|%d|%d|%s\n%s\n\n", $gene->stable_id, $transcript->stable_id, $start, $end, $strand, $seq_region, join("\n", @intron_seq));
            }
            
            if ($gene->biotype ne 'protein_coding') {
                $fasta_str = $fasta_head_transcript . join("\n", @seq) . "\n\n";
                print $ncrna_genes $fasta_str;
            } else {
              # Print cDNA with UTRs and no introns
              print $all_nointrons_utrs $fasta_str;
              
              # CDS with introns and UTRs
              # This should return a single sequence only.
              my @rna_seq = @{ getSeq($gene, 'include', 'include') };
              foreach my $sh (@rna_seq) {
                my %s = %{$sh};
                @seq = $s{'seq'} =~ /(.{1,60})/g;
                $fasta_str = $fasta_head_transcript . join("\n", @seq) . "\n\n";
                print $all_introns_utrs $fasta_str
              }
              
              # CDS without introns and without UTRs
              @rna_seq = @{ getSeq($gene, 'exclude', 'exclude') };
              foreach my $sh (@rna_seq) {
                my %s = %{$sh};
                if ($s{'name'} eq $transcript->stable_id) {
                  @seq = $s{'seq'} =~ /(.{1,60})/g;
                  $fasta_str = $fasta_head_transcript . join("\n", @seq) . "\n\n";
                  print $all_nointrons_noutrs $fasta_str
                }
              }
              
              my $five_prime  = $transcript->five_prime_utr;
              if ($five_prime) {
                my $utr5feature = $transcript->five_prime_utr_Feature;
                
                my $fasta_head_utr5 = '>' . $gene->stable_id;
	            $fasta_head_utr5 .= '|' . $transcript->stable_id;
	            $fasta_head_utr5 .= '|' . $utr5feature->start . '|' . $utr5feature->end . '|' . $utr5feature->strand;
	            $fasta_head_utr5 .= '|' . $gene->external_name;
	            $fasta_head_utr5 .= '|' . $gene->chr_name . '|' . $gene->biotype;
	            $fasta_head_utr5 .= '|' . $new_desc;
	            $fasta_head_utr5 .= '|' . $five_prime_pub . "\n";
                
                my @seq5 = $five_prime->seq() =~ /(.{1,60})/g;
                my $fasta_str_utr5 = $fasta_head_utr5 . join("\n", @seq5) . "\n\n";
                print $utr5 $fasta_str_utr5;
              }
              
              my $three_prime  = $transcript->three_prime_utr;
              if ($three_prime) {
                my $utr3feature = $transcript->three_prime_utr_Feature;
                
                my $fasta_head_utr3 = '>' . $gene->stable_id;
	            $fasta_head_utr3 .= '|' . $transcript->stable_id;
	            $fasta_head_utr3 .= '|' . $utr3feature->start . '|' . $utr3feature->end . '|' . $utr3feature->strand;
	            $fasta_head_utr3 .= '|' . $gene->external_name;
	            $fasta_head_utr3 .= '|' . $gene->chr_name . '|' . $gene->biotype;
	            $fasta_head_utr3 .= '|' . $new_desc;
	            $fasta_head_utr3 .= '|' . $three_prime_pub . "\n";
                
                my @seq3 = $three_prime->seq() =~ /(.{1,60})/g;
                my $fasta_str_utr3 = $fasta_head_utr3 . join("\n", @seq3) . "\n\n";
                print $utr3 $fasta_str_utr3;
              }
                
              my @aa = $transcript->translation->seq() =~ /(.{1,60})/g;
              $fasta_str = $fasta_head_pep . join("\n", @aa) . "\n\n";
              print $proteins $fasta_str;
            }
        }
    }
}

close($all_nointrons_noutrs);
close($all_nointrons_utrs);
close($all_introns_utrs);
close($ncrna_genes);
close($proteins);
close($utr5);
close($utr3);


sub getSeq {
  my ($gene, $utr, $intron)  = @_;
  
  my $sa = $db->get_adaptor('Slice');
  
  my @seq;
  
  if ($intron eq 'include') {
    my $start = 0;
    my $end = 0;
    if ($gene->strand == -1) {
      $start = $gene->seq_region_start();
      $end = $gene->seq_region_end();
    } else {
      $start = $gene->seq_region_start();
      $end = $gene->seq_region_end();
    }
    
    #if ($gene->strand == -1) {
    #  my $reverse = $end;
    #  $end = $start;
    #  $start = $reverse;
    #}
    
    if ($utr eq 'exclude') {
      my @transcripts = @{ $gene->get_all_Transcripts };
      foreach my $transcript (@transcripts) {
        if ($gene->strand == -1) {
          $start = $transcript->coding_region_start();
          $end   = $transcript->coding_region_end();
        } else {
          $start = $transcript->coding_region_start();
          $end   = $transcript->coding_region_end();
        }
        
        my $slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$start,$end);
        if ($gene->strand == -1) {
          $slice = $slice->invert();
        }
        push @seq, {name => $transcript->stable_id, seq => $slice->seq(), test => '1', start => $start, end => $end};
      }
    } else {
      my $slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$start,$end);
      if ($gene->strand == -1) {
        $slice = $slice->invert();
      }
      push @seq, {name => $gene->stable_id, seq => $slice->seq(), test => '2', start => $start, end => $end, seq_region => $gene->slice->seq_region_name, coord_sys => $gene->slice->coord_system_name, seq_len => length($slice->seq())};
    }
    
  } else {
    my @transcript_seq;
    my @transcripts = @{ $gene->get_all_Transcripts };
    foreach my $transcript (@transcripts) {
      if ($utr eq 'include') {
        push @seq, {name => $transcript->stable_id, seq => $transcript->seq->seq(), test => '3', seq_len => length($transcript->seq->seq())};
      } else {
        push @seq, {name => $transcript->stable_id, seq => $transcript->translateable_seq(), test => '4'};
      }
    }
  }

  return \@seq;
}

1;
