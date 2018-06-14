#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;
use Data::Dumper;

#use Config::Tiny;

use IO::File;
#use Time::Local;
use Getopt::Long;
use POSIX;
use JSON;
#use PHP::Serialization qw(serialize unserialize);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::DBSQL::OntologyDBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;

use PomLoader::Gene;
use PomLoader::Transcript;
use PomLoader::Translation;
use PomLoader::BioDefinitions;

$| = 1;

my $printfull = 0;
my $job_id = 1;
my $genes      = 'SPBC23G7.07c,SPAC56F8.12,SPAC29E6.10c,SPAC4H3.01,SPNCRNA.1582';
my $eg_host    = 'mysql-eg-devel-2.ebi.ac.uk';
my $eg_port    = '4207';
my $eg_user    = 'ensrw';
my $eg_pass    = 'xxxxx';
my $eg_species = 'schizosaccharomyces_pombe';
my $eg_dbname  = 'schizosaccharomyces_pombe_core_21_74_2';
my $eg_dbontology = 'ensemblgenomes_ontology_21_74';

my $track_progress = 0;

sub usage {
    print "Usage: $0 [-chr <obo>]\n";
    print "-job <job_id> Default is $job_id\n";
    print "-genes <stable_id>\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> Default is $eg_host\n";
    print "-eg_port <4207> Default is $eg_host\n";
    print "-eg_user <ensro> Default is $eg_user\n";
    print "-eg_pass <xxxxx> Default is $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> Default is $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> Default is $eg_dbname\n";
    print "-eg_dbontology <ensemblgenomes_ontology_21_74> Default is $eg_dbontology\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("job=i"        => \$job_id,
                               "genes=s"      => \$genes,
                               "eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "eg_dbontology=s" => \$eg_dbontology,
                               "help"    => sub {usage()});

if(!$options_okay) {
    usage();
}

sub _get_feature_name {
  #my $class = shift;
  my ($self, $dbname, $query, $db)  = @_;
  #bless $self, $class;
  
  my @query_split = split(m/:/ms, $query);
  
  if ( scalar @query_split < 2 ) {
    if ( $dbname eq 'PomBase_GENE' ) {
      my $ga  = $db->get_adaptor('Gene');
      my $gene = $ga->fetch_by_stable_id($query);
      return $gene->display_xref->display_id;
    }
  } else {
    # warn $query;
    if ($query_split[0] eq 'GeneDB_Spombe' or $query_split[0] eq 'PomBase_GENE' or $query_split[0] eq 'PomBase_GENE') {
      my $ga  = $db->get_adaptor('Gene');
      my $gene = $ga->fetch_by_stable_id($query_split[1]);
      if ( defined $gene ) {
        return $gene->display_xref->display_id;
      } else {
        return '<del>' . $query_split[1] . '</del>';
      }
    }
  }
}

#my $options_okay = GetOptions ("chr=i"   => \$chromosome,
#                               #"track=i" => \$track_progress,
#                               "db=s"    => \$eg_db_config,
#                               "help"    => sub {usage()});
#
#if(!$options_okay) {
#    usage();
#}

# Create a config
#my $config = Config::Tiny->new();

# Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );

# Reading properties
#my $ensembldb = $config->{$eg_db_config};

# print Dumper $ensembldb;
# exit();

my $db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    '-host'    => $eg_host,
    '-port'    => $eg_port,
    '-user'    => $eg_user,
    '-group'   => 'core',
    '-species' => $eg_species,
    '-dbname'  => $eg_dbname,
    '-pass'    => $eg_pass
);

my $dbo = Bio::EnsEMBL::DBSQL::OntologyDBAdaptor->new (
    '-host'    => $eg_host,
    '-port'    => $eg_port,
    '-user'    => $eg_user,
    '-dbname'  => $eg_dbontology,
    '-species' => 'multi',
    '-group'   => 'ontology',
    '-pass'    => $eg_pass
);

# print Dumper $dbo->get_available_adaptors();
# exit();


my $dbc_tracker = $db->dbc();

my $starttime = time;

#
# Create a hash of all Chromosome slices
#
my %chr_slice_hash = ();
my $mc  = $db->get_adaptor('MetaContainer');
my $ga  = $db->get_adaptor('Gene');
my $sa  = $db->get_adaptor('Slice');
my $csa = $db->get_adaptor('CoordSystem');
my $poa = $dbo->get_adaptor( 'OntologyTerm' );
my $goa = $dbo->get_adaptor( 'OntologyTerm' );

# print Dumper $goa;
# print Dumper $poa;
# exit();

my $chr_slices = $sa->fetch_all( 'chromosome' );
#print "Here 1\n";

my $slice_count = 0;
my $species = $db->species;
my @genes4json = ();

#
# Create a list of all genes for updating
#
my $gene_adaptor = $db->get_adaptor('Gene');
my @gene_list = split(/,/, $genes);

#foreach my $slice ( @{ $chr_slices } ) {
foreach my $gene_id ( @gene_list ) {
  my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);
  #my @genes = @{ $ga->fetch_all_by_Slice($slice) };
  #++$slice_count;
  #print "\nChromosome: " . $slice_count . ' of ' . @{ $chr_slices } . "\tNo. of Genes: " . @genes . "\n";
  
  #my $gene_count = 0;
  #if ( $slice_count != $chromosome ) {
  #  next;
  #}
  #foreach my $gene ( @genes ) {
    #++$gene_count;
    #if ( $gene_count > 10 ) {
    #  next;
    #}
    
#    if ($gene->stable_id ne 'SPAC1610.01') {
#      next;
#    }
    
    #if ($gene_count % 100 == 0) {
    #  my $splittime = time;
    #  print $gene_count . " : " . $gene->stable_id . "\n";
    #  print 'Start: ', $starttime, "\tSplit: ", $splittime, "\tElapsed: ", $splittime-$starttime, "\n";
    #}
    
    print $gene_id . ' : '; 
    print $gene->stable_id . "\n";
    #my %gm = {};
    my @gene_DBentries = @{ $gene->get_all_DBEntries() };
    my @release = @{ $mc->list_value_by_key('annotation.release') };
    my @source  = @{ $mc->list_value_by_key('annotation.source') };
    my @date    = @{ $mc->list_value_by_key('annotation.date') };
    
    my %gm = ('meta' => {release => $release[0],
                         source  => $source[0],
                         date    => $date[0]});
    
    my @contigs = @{ $gene->slice->project('contig') };
  
    my %interactions;
    
    my $centre_slice = int((($gene->end-$gene->start)/2)+$gene->start);
    my $larger_slice = $sa->fetch_by_region($gene->slice->coord_system_name,$gene->slice->seq_region_name,$centre_slice-7500,$centre_slice+7500);
    
    my @genes_in_slice = @{ $larger_slice->get_all_Genes };
    my @neighbouring_genes = ();
    foreach my $gene_in_slice (@genes_in_slice) {
      my $neighbour_name = '';
      if (defined $gene_in_slice->display_xref) {
        $neighbour_name = $gene_in_slice->display_xref->display_id;
      }
      push @neighbouring_genes, {gene_id => $gene_in_slice->stable_id,
                                 name    => $neighbour_name};
    }
    
    my $gene_name = $gene->stable_id;
    if (defined $gene->display_xref) {
      $gene_name = $gene->display_xref->display_id;
    }
    $gm{"Gene"} = {gene_id     => $gene->stable_id,
               start       => $gene->start,
               end         => $gene->end,
               chromosome  => $gene->slice->seq_region_name,
               contig      => $contigs[0]->to_Slice()->seq_region_name,
               strand      => $gene->strand,
               name        => $gene_name,
               description => $gene->description,
               biotype     => $gene->biotype,
               status      => $gene->status,
               species     => $species,
               neighbours  => \@neighbouring_genes};
    
    foreach my $dbentry (@gene_DBentries) {
      if (ref $dbentry eq 'Bio::EnsEMBL::OntologyXref') {
        my @evidence = @{ $dbentry->get_all_linkage_info() };
        foreach my $evidencelink (@evidence) {
          my @el = @{ $evidencelink };
          my $evidence_id = $el[0];
          my $evidence_source   = q{};
          my $evidence_desc     = q{};
          my $evidence_dbname   = q{};
          my $evidence_info_text = q{};
          if (scalar @el > 1) {
            $evidence_source    = $el[1]->display_id;
            $evidence_desc      = $el[1]->description;
            $evidence_dbname    = $el[1]->dbname;
            $evidence_info_text = $el[1]->info_text;
          }
          
          my %evidence_hash = ($evidence_source => {
            'evidence_id'        => $evidence_id,
            'evidence_source'    => $evidence_source,
            'evidence_desc'      => $evidence_desc,
            'evidence_dbname'    => $evidence_dbname,
            'evidence_info_text' => $evidence_info_text
          });
          
          my $term = q{};
          if ($dbentry->dbname eq 'GO') {
            $term = $goa->fetch_by_accession($dbentry->primary_id);
          } else {
            $term = $poa->fetch_by_accession($dbentry->primary_id);
          }
          
          my $associated_xref = {};
          my $annot_ext = $dbentry->get_all_associated_xrefs();
          
          foreach my $ax_group (sort keys %{ $annot_ext }) {
            my $group = $annot_ext->{$ax_group};
            foreach my $ax_rank (sort keys %{ $group }) {
              my @ax = @{ $group->{$ax_rank} };
              my $name = $ax[0]->primary_id;
              #print Dumper $ax[0];
              if (
                $ax[0]->dbname eq 'PomBase_Systematic_ID' or
                $ax[0]->dbname eq 'PomBase_TRANSCRIPT' or
                $ax[0]->dbname eq 'PomBase_Gene_Name' or
                $ax[0]->dbname eq 'PomBase'
              ) {
                my $ax_gene = $ga->fetch_by_stable_id($ax[0]->primary_id);
                #print Dumper $ax_gene;
                if ( defined $ax_gene and defined $ax_gene->display_xref ) {
                  $name = $ax_gene->display_xref->display_id;
                }
              }
              my $ontology = '';
              if ( ref $ax[0] eq 'Bio::EnsEMBL::OntologyXref' ) {
                $ontology = $ax[0]->ontology;
              }
              
              $associated_xref->{$ax_group}->{$ax_rank} = {
                  condition_type   => $ax[2],
                  primary_id       => $ax[0]->primary_id,
                  name             => $name,
                  dbname           => $ax[0]->dbname,
                  accession        => $ax[0]->display_id,
                  description      => $ax[0]->description,
                  #name             => $ax[0]->name,
                  ontology         => $ontology,
                  source_accession => $ax[1]->display_id,
                  source_dbname    => $ax[1]->dbname,
                  #source_name      => $ax[1]->name,
                  #source_ontology  => $ax[1]->ontology,
              }
            }
          }
          
          if ( $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} ) {
          	my @evid_array = $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"};
          	push @evid_array, \%evidence_hash;
          	
          	my @assoc_xref_array = $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"};
          	push @assoc_xref_array, $associated_xref;
          	
          	$gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"} = \@evid_array;
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"} = @assoc_xref_array;
          } else {
          	$gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} = $term->name;
          	my @evid_array = (\%evidence_hash);
          	$gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"} = \@evid_array;
          	$gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"} = ($associated_xref);
          }
        }
      } else {
      	my %gene_dbentry = (type        => "Gene_DBEntry",
                   primary_id  => $dbentry->primary_id,
                   dbname      => $dbentry->dbname,
                   name        => $dbentry->display_id,
                   description => $dbentry->description,
                   synonyms    => $dbentry->get_all_synonyms,
                   info_text   => $dbentry->info_text);
        
      if ($dbentry->dbname eq 'PUBMED_POMBASE' or $dbentry->dbname eq 'PUBMED') {
        my @pmid_set = split /_/, $dbentry->primary_id;
        my @pmid = split /:/, $pmid_set[0];
        #print Dumper @pmid;
        if ( $pmid[-1] =~ /^\d+$/ ) {
	      if ( $gm{'Publications'} and $gm{'Publications'}{'PubMed_IDs'} ) {
	        if ( !defined $gm{'Publications'}{'PubMed_IDs'}{$pmid[-1]} ) {
	          $gm{'Publications'}{'PubMed_IDs'}{$pmid[-1]} = 1;
	        }
	      } else {
	        my %pubmed = ($pmid[-1] => 1);
	        $gm{'Publications'}{'PubMed_IDs'} = \%pubmed;
	      }
        }
        
        my @info_text = split /\s*/, $dbentry->info_text;
        if (
          $info_text[0] eq 'five_prime_utr' or
          $info_text[0] eq 'three_prime_utr' or
          $info_text[0] eq 'exon' or
          $info_text[0] eq 'intron' or
          $info_text[0] =~ /RNA/
        ) {
          my @region = split /-/, $info_text[-1];
          if ( $pmid[-1] =~ /^\d+$/ ) {
            my %exon_pub = (
                location => $info_text[0],
                start    => $region[0],
                end      => $region[1]
              );
            if (
              defined $gm['Exon'] and
              defined $gm['Exon']['PubMed_IDs'] and
              defined $gm['Exon']['PubMed_IDs'][$pmid[-1]]
            ) {
              push $gm['Exon']['PubMed_IDs'][$pmid[-1]], \%exon_pub;
            } else {
	          my @exon_pubs = (\%exon_pub);
	          $gm['Exon']['PubMed_IDs'][$pmid[-1]] = \@exon_pubs;
            }
          }
        }
      } elsif ( defined $dbentry->description and $dbentry->description eq 'ortholog' ) {
          $gm{'Gene'}{'Orthologs'}{$dbentry->primary_id} = \%gene_dbentry;
        } else {
          if ( $gm{'Gene'}{'DBEntry'} ) {
            push $gm{'Gene'}{'DBEntry'}, \%gene_dbentry;
          } else {
            my @gene_dbentry_array = (\%gene_dbentry);
            $gm{'Gene'}{'DBEntry'} = \@gene_dbentry_array;
          }
        }
      }
    }
    
    my @exons = @{ $gene->get_all_Exons };
    my @transcripts = @{ $gene->get_all_Transcripts };
    
    foreach my $exon (@exons) {
      $gm{"Exon"}{"exons"} = {exon_id => $exon->stable_id,
                 start   => $exon->start,
                 end     => $exon->end,
                 strand  => $exon->strand};
    }
    
    
    foreach my $transcript (@transcripts) {
      my $attributeAdaptor = $db->get_adaptor('Attribute');
      my @stats_to_show = ();
      my @protein_features_to_show = ();
      if ($transcript->translation()) { 
        my $attributes = $attributeAdaptor->fetch_all_by_Translation($transcript->translation());
        foreach my $stat (sort {$a->name cmp $b->name} @{$attributes}) {
          push @stats_to_show, {name=>$stat->name, value=>$stat->value};
        }
        my $translation = $transcript->translation();
        my @translation_features = @{ $translation->get_all_ProteinFeatures() };
        my $dbc = $db->dbc();
        my $sql = "select count(distinct translation_id) from protein_feature where hit_name = ?";
        foreach my $pf (@translation_features) {
          my $sth = $dbc->prepare($sql);
          $sth->bind_param(1, $pf->display_id);
          $sth->execute();
          
          # Returns an array reference for all rows.
          my @prot_dom_count = @{ $sth->fetchall_arrayref() };
          $sth->finish();
          push @protein_features_to_show, {name  => $pf->display_id,
                                           start => $pf->start,
                                           end   => $pf->end,
                                           score => $pf->score,
                                           source => $pf->analysis->logic_name,
                                           interpro => $pf->interpro_ac(),
                                           description => $pf->hdescription(),
                                           count => $prot_dom_count[0][0]};
        }
        $gm{"Transcript"} = {transcript_id   => $transcript->stable_id,
                     start           => $transcript->start,
                     end             => $transcript->end,
                     cds_start       => $transcript->coding_region_start,
                     cds_end         => $transcript->coding_region_end,
                     proteinstats    => \@stats_to_show,
                     proteinfeatures => \@protein_features_to_show};
      } else {
        my %transcript_element = {transcript_id   => $transcript->stable_id,
                   start           => $transcript->start,
                   end             => $transcript->end,
                   proteinstats    => \@stats_to_show,
                   proteinfeatures => \@protein_features_to_show};
        
        if ( $gm{"Transcript"}{'transcripts'} ) {
          push $gm{"Transcript"}{'transcripts'}, \%transcript_element;
        } else {
          my @transcript_elements = (\%transcript_element);
          $gm{"Transcript"}{'transcripts'} = \@transcript_elements;
        }
     }
    
    my @transcript_DBentries = @{ $transcript->get_all_DBLinks() };
    foreach my $dbentry (@transcript_DBentries) {
      if (ref $dbentry eq 'Bio::EnsEMBL::OntologyXref') {
        my @evidence = @{ $dbentry->get_all_linkage_info() };
        foreach my $evidencelink (@evidence) {
          my @el = @{ $evidencelink };
          my $evidence_id = $el[0];
          my $evidence_source   = q{};
          my $evidence_desc     = q{};
          my $evidence_dbname   = q{};
          my $evidence_info_text = q{};
          if (scalar @el > 1) {
            $evidence_source    = $el[1]->display_id;
            $evidence_desc      = $el[1]->description;
            $evidence_dbname    = $el[1]->dbname;
            $evidence_info_text = $el[1]->info_text;
          }
          
          my %evidence_hash = ($evidence_source => {
          	'evidence_id'        => $evidence_id,
          	'evidence_source'    => $evidence_source,
          	'evidence_desc'      => $evidence_desc,
          	'evidence_dbname'    => $evidence_dbname,
          	'evidence_info_text' => $evidence_info_text
          });
          
          my $term = q{};
          if ($dbentry->dbname eq 'GO') {
            $term = $goa->fetch_by_accession($dbentry->primary_id, 1);
          } else {
            $term = $poa->fetch_by_accession($dbentry->primary_id, 1);
          }
          # print Dumper $term;
          
          my $associated_xref = {};
          my $annot_ext = $dbentry->get_all_associated_xrefs();
          
          #print "\t" . $dbentry->primary_id . "\n";
          foreach my $ax_group (sort keys %{ $annot_ext }) {
            my $group = $annot_ext->{$ax_group};
            #print Data::Dumper->Dump([$group]);
            foreach my $ax_rank (sort keys %{ $group }) {
              my @ax = @{ $group->{$ax_rank} };
              #print $ax[0] . "\t" . $ax[1] . "\t" . $ax[2] . "\n";
              if (defined $ax[0]) {
                  my $name = $ax[0]->primary_id;
                  if (
                    $ax[0]->dbname eq 'PomBase_Systematic_ID' or
                    $ax[0]->dbname eq 'PomBase_TRANSCRIPT' or 
                    $ax[0]->dbname eq 'PomBase_Gene_Name' or 
                    $ax[0]->dbname eq 'PomBase'
                  ) {
                    my $ax_gene = $ga->fetch_by_stable_id($ax[0]->primary_id);
                    if ( defined($ax_gene) ) {
                      if ( defined $ax_gene->display_xref ) {
                        $name = $ax_gene->display_xref->display_id;
                      }
                    }
                  }
                  #print "\t\t" . $ax_group;
                  #print "\t" . $ax_rank;
                  #print "\t" . $ax[0]->primary_id;
                  #print "\t" . $ax[1]->primary_id;
                  #print "\t" . $ax[2] . "\n";
                  #print "\t" . $ax[2] . "\t" . $ax[0]->display_id . "\n";
                  $associated_xref->{$ax_group}->{$ax_rank} = {
                      condition_type   => $ax[2],
                      primary_id       => $ax[0]->primary_id || q{},
                      name             => $name || q{},
                      dbname           => $ax[0]->dbname || q{},
                      accession        => $ax[0]->display_id || q{},
                      description      => $ax[0]->description || q{},
                      #name             => $ax[0]->name || '',
                      #ontology         => $ax[0]->ontology || '',
                      source_accession => $ax[1]->display_id,
                      source_dbname    => $ax[1]->dbname,
                      info_text        => $ax[0]->info_text,
                      #source_name      => $ax[1]->name,
                      #source_ontology  => $ax[1]->ontology,
                  }
              } else {
                $associated_xref->{$ax_group}->{$ax_rank} = {
                      condition_type   => $ax[2],
                      primary_id       => q{},
                      name             => q{},
                      dbname           => q{},
                      accession        => q{},
                      description      => q{},
                      display_label    => q{},
                      source_accession => $ax[1]->display_id,
                      source_dbname    => $ax[1]->dbname,
                }
              }
            }
          }
            
          # my @el = @{ $evidencelink };
          #print Dumper $dbentry;
          #print Dumper $term;
          my $obo_name      = $dbentry->description;
          my $obo_namespace = $dbentry->dbname;
          my $obo_ontology  = $dbentry->dbname;
          
          if (!defined $term) {
            print "Missing Term:\n\t" . $dbentry->dbname . " : " . $dbentry->display_id . "\n";
          }# else {
          #  $obo_name      = $term->name;
          #  $obo_namespace = $term->namespace;
          #  $obo_ontology  = $term->ontology;
          #}
          
#          if ( $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} ) {
#            push $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"}, %evidence_hash;
#            push $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"}, $associated_xref;
#          } else {
#            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} = $term->name;
#            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"} = ();
#            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"} = ();
#            
#            push $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"}, %evidence_hash;
#            push $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"}, $associated_xref;
#          }
          
          if ( $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} ) {
            my @evid_array = $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"};
            push @evid_array, %evidence_hash;
            
            my @assoc_xref_array = $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"};
            push @assoc_xref_array, $associated_xref;
            
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"} = @evid_array;
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"} = @assoc_xref_array;
          } else {
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"name"} = $term->name;
            my @evid_array = (%evidence_hash);
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"evidence"} = @evid_array;
            $gm{"Ontology"}{$term->ontology}{$term->namespace}{$dbentry->primary_id}{"assocaited_xref"} = ($associated_xref);
          }
          
#          push @gm, {type               => "Transcript_DBEntry_Ontology",
#                     transcript_id      => $transcript->stable_id,
#                     primary_id         => $dbentry->primary_id,
#                     #description        => $dbentry->description,
#                     dbname             => $dbentry->dbname,
#                     accession          => $dbentry->display_id,
#                     name               => $obo_name,
#                     aspect             => $obo_namespace,
#                     ontology           => $obo_ontology,
#                     linkage_annotation => $dbentry->linkage_annotation,
#                     evidence_id        => $evidence_id,
#                     evidence_source    => $evidence_source,
#                     evidence_desc      => $evidence_desc,
#                     evidence_dbname    => $evidence_dbname,
#                     evidence_name      => _get_feature_name($evidence_dbname, $evidence_source, $db),  #####
#                     evidence_info_text => $evidence_info_text,
#                     associated_xref    => $associated_xref,
#                    };
        }
      } else {
        my %transcript_dbentry = (type => "Transcript_DBEntry",
                   primary_id  => $dbentry->primary_id,
                   dbname      => $dbentry->dbname,
                   name        => $dbentry->display_id,
                   description => $dbentry->description);
        
        if ( $gm{'Transcript'}{'DBEntry'} ) {
          push $gm{'Transcript'}{'DBEntry'}, \%transcript_dbentry;
        } else {
          my @transcript_dbentry_array = (\%transcript_dbentry);
          $gm{'Transcript'}{'DBEntry'} = \@transcript_dbentry_array;
        }
      }
    }
  }
  #push @genes4json, {$gene->stable_id => \@gm};
  my %json_object = ($gene->stable_id => \%gm);
  my $json_text = encode_json \%json_object;
  open my ($fh), '>>', 'data/caches/GeneModels_' . $job_id . '.json' or die;
  print $fh $json_text . "\n";
  close $fh;
  
  ###
  # Code to get me started just incase moving the PHP serialization is more effective
  # Will need to uncomment the package in the header.
  ###
  #open my ($fh), '>>', 'data/caches/GeneModels_' . $job_id . '.json' or die;
  #print serialize({$gene->stable_id => \@gm});
  #close $fh;
  
  
  #}
}

#my $json_text = encode_json (\@genes4json);
##print $json_text;
#
##open my ($fh), '>', 'data/FTP/GeneModels_chr' . $chromosome . '.json' or die;
#open my ($fh), '>', 'data/caches/GeneModels_' . $job_id . '.json' or die;
#print $fh $json_text;
#close $fh;

my $endtime = time;
print 'Start: ', $starttime, "\tEnd: ", $endtime, "\tElapsed: ", $endtime-$starttime, "\n" or confess;





__END__

