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
my $genes      = '';
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

my %dbparam = (
                  'dbname'                     => 'PomBase',
                  'organism_id'                => '1',
                  'isoforms'                   => '1',
                  'includeobsolete'            => 0,
                  'includeproteinfeatures'     => 1,
                  'transcripts_with_gene_name' => 1,
              );

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
my @sf4json = ();

#
# Create a list of all genes for updating
#
my $gene_adaptor = $db->get_adaptor('Gene');
my @gene_list = split(/,/, $genes);
