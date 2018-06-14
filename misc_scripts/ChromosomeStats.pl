#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use JSON qw(to_json);
use Carp;
use IO::File;
#use Config::Tiny;
use Data::Dumper;
use Getopt::Long;
use POSIX;

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
#my $ensembldb = $config->{Spombe_1};
##my $chadodb   = $config->{postgresegpombe};

my $printfull = 0;
my $eg_host    = 'mysql-eg-devel-2.ebi.ac.uk';
my $eg_port    = '4207';
my $eg_user    = 'ensrw';
my $eg_pass    = 'xxxxx';
my $eg_species = 'schizosaccharomyces_pombe';
my $eg_dbname  = 'schizosaccharomyces_pombe_core_21_74_2';
my $eg_version = 18;
my $e_version = 71;
my $release_date = 20130811;
my $track_progress = 0;
my $json_file = 'data/FTP/ChromosomeStatistics.json';

sub usage {
    print "Usage:\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> Default is $eg_host\n";
    print "-eg_port <4207> Default is $eg_host\n";
    print "-eg_user <ensro> Default is $eg_user\n";
    print "-eg_pass <xxxxx> Default is $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> Default is $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> Default is $eg_dbname\n";
    print "-date <date> Default is $release_date\n";
    print "-eg_version <eg_v> Default is $eg_version\n";
    print "-e_version  <e_v> Default is $e_version\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
    	                       "date=i"       => \$release_date,
                               "eg_version=i" => \$eg_version,
                               "e_version=i"  => \$e_version,
                               "help"         => sub {usage()});

if(!$options_okay) {
    usage();
}

my %dbparam = (
                  'dbname'      => 'PomBase',
                  'dbdate'      => $release_date,
                  'eg_version'  => $eg_version,
                  'db_version'  => $e_version,
              );

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

foreach my $slice ( @{ $chr_slices } ) {
    my @genes = @{ $slice->get_all_Genes };
    my %biotypes = ();
    
    my $intron_coding_count = 0;
    
    my $gene_pc_count       = 0;
    my $gene_pc_length      = 0;
    my $gene_total_length   = 0;
    my $intergene_length    = 0;
    
    
    
    
    my %total_gc_count      = ();
    my %gene_gc_count       = ();
    my %gene_pc_gc_count    = ();
    my %intergene_gc_count  = ();
    
    my @chr_seq = $slice->seq =~ /(.)/gs;
    map { $total_gc_count{$_}++ } @chr_seq;
    
    my @previous_gene = (0,0);
    
    foreach my $gene ( @genes ) {
#        #
#        # Get all information about the Gene from Chado.   This is required for
#        # getting the GC of the full length of the genes outside of the
#        # transcript regions.
#        #
#        my $rs = $chado->resultset('Sequence::Feature')
#               ->search(
#                   {'me.uniquename'  => $gene->stable_id},
#                   {select => ['me.feature_id', 'me.name', 'me.uniquename', 'me.type_id'],
#                    join => ['featureloc_features'],
#                    '+select' => [
#                       'featureloc_features.fmin',
#                       'featureloc_features.fmax',
#                       'featureloc_features.strand',
#                       'featureloc_features.phase',],
#                    '+as' => ['fmin', 'fmax', 'strand', 'phase']
#                   }
#               );
#        
#        my $rs_feature = $rs->next();
#        my ($featurestart, $featureend) = PomLoader::FeatureLocation->_feature_range(
#              $rs_feature->get_column('fmin'),
#              $rs_feature->get_column('fmax'),
#              $rs_feature->get_column('strand'));
#        my @gene_seq = @chr_seq[($featurestart-1)..($featureend-1)];
        
        #
        # Get the Gene from the ensembl core
        #
        my @gene_seq = $gene->seq =~ /(.)/gs;
        
        
        #
        # Get all information from Ensembl
        #
        my $exon_count          = 0;
        my $exon_length         = 0;
        my %exon_gc_count       = ();
        
        my $trans_exon_count    = 0;
        my $trans_exon_length   = 0;
        my %trans_exon_gc_count = ();
        
        my $utr5_count          = 0;
        my $utr5_length         = 0;
        my %utr5_gc_count       = ();
        
        my $utr3_count          = 0;
        my $utr3_length         = 0;
        my %utr3_gc_count       = ();
        
        my $has_intron          = 0;
        my $intron_count        = 0;
        my $intron_length       = 0;
        my %intron_gc_count     = ();
        
        
        my $has_introns = 0;
        # my @gene_seq = @chr_seq[($gene->start-1)..($gene->end-1)];
        my $exons = $gene->get_all_Exons();
        
        my $transcripts = $gene->get_all_Transcripts();
        foreach my $transcript ( @{ $transcripts } ) {
            my $utr5 = $transcript->five_prime_utr();
            my $utr3 = $transcript->three_prime_utr();
            if (defined $utr5) {
                my @utr5_seq = $utr5->seq =~ /(.)/gs;
                map { $utr5_gc_count{$_}++ } @utr5_seq;
                $utr5_length += $utr5->length;
                $utr5_count += 1;
            }
            if (defined $utr3) {
                my @utr3_seq = $utr3->seq =~ /(.)/gs;
                map { $utr3_gc_count{$_}++ } @utr3_seq;
                $utr3_length += $utr3->length;
                $utr3_count += 1;
            }
          
#          my $exon_count = $transcript->get_all_translateable_Exons();
#          if ( scalar @{ $exon_count } > 1 ) {
#              $has_introns = 1;
#              $intron_coding_count += scalar @{ $exon_count } - 1;
#              my $max_intron_loc = 0;
#              my $min_intron_loc = $slice->end();
#              my $exon_length = 0;
#              foreach my $exon (@{ $exon_count }) {
#                  $exon_length += $exon->end-$exon->start;
#                  if ($exon->end>$max_intron_loc) {
#                      $max_intron_loc = $exon->end;
#                  }
#                  if ($exon->start<$min_intron_loc) {
#                      $min_intron_loc = $exon->start;
#                  }
#              }
#              $intron_length += $max_intron_loc-$min_intron_loc-$exon_length;
#          }
          
            my $trans_exons = $transcript->get_all_translateable_Exons();
            foreach my $exon ( @{ $trans_exons } ) {
                #my @trans_exon_seq = @chr_seq[($exon->seq_region_start-1)..($exon->seq_region_end-1)];
                my @trans_exon_seq = $exon->seq->seq =~ /(.)/gs;
                map { $trans_exon_gc_count{$_}++ } @trans_exon_seq;
                $trans_exon_length += scalar @trans_exon_seq;
                $trans_exon_count += 1;
            }
           
            my $introns = $transcript->get_all_Introns();
            foreach my $intron ( @{ $introns } ) {
                $has_intron = 1;
                my @intron_seq = $intron->seq =~ /(.)/gs;
                map { $intron_gc_count{$_}++ } @intron_seq;
                $intron_length += scalar @intron_seq;
                $intron_count += 1;
            }
        }
        
        #
        # Count for all exons (Translatable and Untranslatable regions)
        #
        foreach my $exon ( @{ $exons } ) {
            #my @exon_seq = @chr_seq[($exon->seq_region_start-1)..($exon->seq_region_end-1)];
            my @exon_seq = $exon->seq->seq =~ /(.)/gs;
            map { $exon_gc_count{$_}++ } @exon_seq;
            $exon_length += $exon->length;
            $exon_count += 1;
        }
        
        
        if ($biotypes{$gene->biotype}) {
            #print $gene->biotype . "\n";
            #my $d = Data::Dumper->new( [%biotypes] );
            #print $d->Dump();
            
            my %biotype_gc_count      = ();
            map { $biotype_gc_count{$_}++ } @gene_seq;
            
            $biotypes{$gene->biotype}{count} += 1;
            if ( $gene->status eq 'dubious' ) {
                print $gene->stable_id . "\t" . $gene->biotype . "\n";
            } else {
                $biotypes{$gene->biotype}{count_not_dubious} += 1;
            }
            
            $biotypes{$gene->biotype}{sum_length} += $gene->length();
            $biotypes{$gene->biotype}{exon_count} += $exon_count;
            $biotypes{$gene->biotype}{exon_length} += $exon_length;
            $biotypes{$gene->biotype}{translatable_exon_count} += $trans_exon_count;
            $biotypes{$gene->biotype}{translatable_exon_length} += $trans_exon_length;
            $biotypes{$gene->biotype}{has_introns} += $has_intron;
            $biotypes{$gene->biotype}{intron_count} += $intron_count;
            $biotypes{$gene->biotype}{intron_length} += $intron_length;
            $biotypes{$gene->biotype}{utr5_count} += $utr5_count;
            $biotypes{$gene->biotype}{utr5_length} += $utr5_length;
            $biotypes{$gene->biotype}{utr3_count} += $utr3_count;
            $biotypes{$gene->biotype}{utr3_length} += $utr3_length;
            
            foreach my $base ( keys %biotype_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{gc_count}{$base} += $biotype_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{gc_count}{$base} = $biotype_gc_count{$base};
                }
            }
            
            foreach my $base ( keys %exon_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{exon_gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{exon_gc_count}{$base} += $exon_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{exon_gc_count}{$base} = $exon_gc_count{$base};
                }
            }
            
            foreach my $base ( keys %trans_exon_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{exon_gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{translatable_exon_gc_count}{$base} += $trans_exon_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{translatable_exon_gc_count}{$base} = $trans_exon_gc_count{$base};
                }
            }
            
            foreach my $base ( keys %intron_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{exon_gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{intron_gc_count}{$base} += $intron_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{intron_gc_count}{$base} = $intron_gc_count{$base};
                }
            }
            
            foreach my $base ( keys %utr5_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{utr5_gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{utr5_gc_count}{$base} += $utr5_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{utr5_gc_count}{$base} = $utr5_gc_count{$base};
                }
            }
            
            foreach my $base ( keys %utr3_gc_count ) {
                if ( exists $biotypes{$gene->biotype}{utr3_gc_count}{$base} ) {
                    $biotypes{$gene->biotype}{utr3_gc_count}{$base} += $utr3_gc_count{$base};
                } else {
                    $biotypes{$gene->biotype}{utr3_gc_count}{$base} = $utr3_gc_count{$base};
                }
            }
            
            
        } else {
            my %biotype_gc_count      = ();
            map { $biotype_gc_count{$_}++ } @gene_seq;
            $biotypes{$gene->biotype} = {
              count                      => 1,
              count_not_dubious          => 0,
              sum_length                 => $gene->length(),
              gc_count                   => \%biotype_gc_count,
              exon_count                 => $exon_count,
              exon_length                => $exon_length,
              exon_gc_count              => \%exon_gc_count,
              translatable_exon_count    => $trans_exon_count,
              translatable_exon_length   => $trans_exon_length,
              translatable_exon_gc_count => \%trans_exon_gc_count,
              has_introns                => $has_intron,
              intron_count               => $intron_count,
              intron_length              => $intron_length,
              intron_gc_count            => \%intron_gc_count,
              utr5_count                 => $utr5_count,
              utr5_length                => $utr5_length,
              utr5_gc_count              => \%utr5_gc_count,
              utr3_count                 => $utr3_count,
              utr3_length                => $utr3_length,
              utr3_gc_count              => \%utr3_gc_count,
            };
            
            if ( $gene->status eq 'dubious' ) {
                print $gene->stable_id . "\t" . $gene->biotype . "\n";
            } else {
                $biotypes{$gene->biotype}{count_not_dubious} += 1;
            }
        }
        
        
        #print scalar @gene_seq . "\t" . $gene->length . "\t" . join('', @gene_seq[0..9]) . "\n";
        map { $gene_gc_count{$_}++ } @gene_seq;
        $gene_total_length += $gene->length();
        
        if ($gene->biotype eq 'protein_coding') {
            $gene_pc_length += $gene->length();
            $gene_pc_count += 1;
            map { $gene_pc_gc_count{$_}++ } @gene_seq;
        }
        
        my @previous_gene_seq = @chr_seq[($previous_gene[1])..($gene->start-2)];
        map { $intergene_gc_count{$_}++ } @previous_gene_seq;
        $intergene_length += $gene->start - $previous_gene[1] - 1;
        
#        $intron_count += $has_introns;
        
        @previous_gene = ($gene->start,$gene->end);
    }

    $chromosomes{$slice->seq_region_name} = {   start              => $slice->start(), 
                                                end                => $slice->end(),
                                                size               => $slice->length(),
                                                gc_cont_chr        => \%total_gc_count,
#                                                gc_cont_gene       => \%gene_gc_count,
#                                                gc_cont_pc_gene    => \%gene_pc_gc_count,
                                                intergene_len      => $intergene_length,
                                                intergene_gc_count => \%intergene_gc_count,
                                                biotypes           => \%biotypes,
#                                                intron_gc          => $intron_count,
#                                                intron_tot         => $intron_coding_count,
#                                                intron_len         => $intron_length,
#                                                utr5_count         => $utr5_count,
#                                                utr5_length        => $utr5_total_length,
#                                                utr3_count         => $utr3_count,
#                                                utr3_length        => $utr3_total_length,
                                                gene_count         => scalar @genes,
#                                                gene_pc_count      => $gene_pc_count,
#                                                gene_pc_length     => $gene_pc_length,
#                                                gene_total_length  => $gene_total_length,
                                            };
}

$chromosomes{'meta'} = {
  date    => $dbparam{'dbdate'},
  release => $dbparam{'eg_version'} . '.' . $dbparam{'db_version'},
  source  => $dbparam{'dbname'} 
};

open my ($fh), '>', $json_file or die;
print $fh to_json(\%chromosomes);
close $fh;

1;

