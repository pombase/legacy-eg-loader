#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;

use Proc::ProcessTable;

use Config::Tiny;

use IO::File;
#use Time::Local;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;

use PomLoader::BioDefinitions;
use PomLoader::Transcript;
use PomLoader::FeaturePublications;
use PomLoader::FeatureLocation;
use PomLoader::FeatureSynonyms;
use PomLoader::FeatureXrefs;
use PomLoader::Orthology;
use PomLoader::Interactions;

use Test::Memory::Cycle;

sub memory_usage() {
    my $t = new Proc::ProcessTable;
    foreach my $got (@{$t->table}) {
        next
            unless $got->pid eq $$;
        return [$got->size, $got->rss];
    }
}

# Create a config
my $config = Config::Tiny->new();

# Open the config
$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );

# Reading properties
my $ensembldb = $config->{Spombe_3};
my $chadodb   = $config->{postgresboxpombe};

my $db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    '-host'    => $ensembldb->{host},
    '-port'    => $ensembldb->{port},
    '-user'    => $ensembldb->{user},
    '-group'   => $ensembldb->{group},
    '-species' => $ensembldb->{species},
    '-dbname'  => $ensembldb->{dbname},
    '-pass'    => $ensembldb->{pass}
);

my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$chadodb->{dbname};host=$chadodb->{host};port=$chadodb->{port}",
    $chadodb->{user},
    $chadodb->{pass}
) or croak();

my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $chado);

my %dbparam = (
                  'dbname'                     => 'PomBase',
                  'organism_id'                => $biodef->organism_id()->{ucfirst $eg_species},
                  'isoforms'                   => '1',
                  'includeobsolete'            => 0,
                  'includeproteinfeatures'     => 1,
                  'transcripts_with_gene_name' => 1,
                  'biodef'                     => $biodef,
              );

# Get all genes for a given organism
my $rs = $chado->resultset('Sequence::Feature')
               ->search(
                   {'me.organism_id' => $dbparam{'organism_id'},
                    'me.type_id' => [$biodef->biotype_id()->{'gene'},
                                     $biodef->biotype_id()->{'contig'},
                                     $biodef->biotype_id()->{'pseudogene'},
                                     $biodef->biotype_id()->{'origin_of_replication'},
                                     $biodef->biotype_id()->{'promoter'},
                                     $biodef->biotype_id()->{'sequence_conflict'},
                                     $biodef->biotype_id()->{'intron'},
                                     $biodef->biotype_id()->{'centromere'},
                                     $biodef->biotype_id()->{'mating_type_region'},
                                     $biodef->biotype_id()->{'long_terminal_repeat'},
                                     $biodef->biotype_id()->{'low_complexity_region'},
                                     $biodef->biotype_id()->{'LTR_retrotransposon'},
                                     ]},
                   {join => {'featureloc_features' => 'srcfeature'},
                    '+select' => [
                        'featureloc_features.feature_id',
                        'featureloc_features.fmin',
                        'featureloc_features.fmax',
                        'featureloc_features.strand',
                        'featureloc_features.srcfeature_id',
                        'srcfeature.uniquename',
                    ],
                    '+as' => ['featurelocfeatureid', 'featureloc_start', 'featureloc_end', 'featureloc_strand', 'featurelocsrcfeatureid', 'srcfeatureuniquename'],
                   }
               );

my @start_mem = ();

my $count = 0;
while( my $rs_gene = $rs->next and $count < 500) {
  #
  # Get all information about the Gene.
  #
  my $feature_gene = PomLoader::FeatureLocation->new(
                            'dba_chado'   => $chado,
                            'feature_id'  => $rs_gene->feature_id);
  my $featureloc_gene = $feature_gene->featurelocation();
#  
#  #
#  # Create Hash of all Xrefs
#  #
#  my $feature_xrefs = PomLoader::FeatureXrefs->new(
#                            'dba_chado'  => $chado,
#                            'feature_id' => $rs_gene->feature_id,
#                            'dbparams'   => \%dbparam,);
#  my $xrefs = $feature_xrefs->featurexrefs();
#  
#  #
#  # Get all publications linked to a given feature_id
#  #
#  my $pubs = PomLoader::FeaturePublications->new(
#                   'dba_chado'  => $chado,
#                   'feature_id' => $rs_gene->feature_id,
#             );
#  my $gene_pub_dbentries = $pubs->get_all_publications();
#  
#  
#  #
#  # Get all the GO terms of the gene.
#  #
#  my $goterms = PomLoader::GOTerms->new(
#                   'dba_chado'  => $chado,
#                   'feature_id' => $rs_gene->feature_id,
#                   'dbparams'   => \%dbparam,
#               );
#  my $goterm_dbentries = $goterms->goterms();
#  
#  
#  #
#  # Get all the Ontology terms of the gene.
#  #
#  my $ontologyterms = PomLoader::OntologyTerms->new(
#                   'dba_chado'    => $self->dba_chado,
#                   'feature_id'   => $rs_gene->feature_id,
#                   'dbparams'     => \%dbparam,
#                   'feature_type' => 'Gene',
#               );
#  my $ontology_dbentries = $ontologyterms->ontologyterms();
  
  #weakened_memory_cycle_ok($featureloc_gene);
  #print scalar keys %{$chado->storage->dbh->{CachedKids}};
  #print $rs_gene->feature_id . "\n";
  #my $kids = $chado->storage->dbh->{CachedKids};
  #delete @{$kids}{keys %$kids}
  
  if ($count == 0) {
    @start_mem = @{memory_usage()};
  }
  #print $count . "\t" . $rs_gene->feature_id. "\tMemory usage: ". $mem[0] . "\t" . $mem[1] . "\n";
  $count++;
}

my @end_mem = @{memory_usage()};

print "Start:      " . $start_mem[0] . "\t" . $start_mem[1] . "\n";
print "End:        " . $end_mem[0] . "\t" . $end_mem[1] . "\n";
print "Difference: " , $end_mem[0]-$start_mem[0] , "\t" , $end_mem[1]-$start_mem[1] , "\n"; 
