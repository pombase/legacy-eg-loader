#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use Config::Tiny;
use IO::File;

use Bio::EnsEMBL::Registry;
use Bio::Chado::Schema;

use PomLoader::SpeciesClassification;
use PomLoader::BioDefinitions;

## Create a config
#my $config = Config::Tiny->new();
#
## Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );
#
## Reading properties
#my $ensembldb = $config->{Spombe_2};
#my $chadodb   = $config->{postgresboxpombe};
#
##my $ensembldb = $config->{Lmajor};
##my $chadodb   = $config->{GeneDB};

my $savefile = '../data/sql/meta_species.txt';


my $eg_host    = 'mysql-eg-devel-2.ebi.ac.uk';
my $eg_port    = '4207';
my $eg_user    = 'ensrw';
my $eg_pass    = 'xxxxx';
my $eg_species = 'schizosaccharomyces_pombe';
my $eg_dbname  = 'schizosaccharomyces_pombe_core_21_74_2';

my $pg_host    = 'postgres-eg-pombe';
my $pg_port    = '5432';
my $pg_user    = 'ensrw';
my $pg_pass    = 'xxxxx';
my $pg_dbname  = 'pombase_chado_v41';

sub usage {
    print "Usage:\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> Default is $eg_host\n";
    print "-eg_port <4207> Default is $eg_host\n";
    print "-eg_user <ensro> Default is $eg_user\n";
    print "-eg_pass <xxxxx> Default is $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> Default is $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> Default is $eg_dbname\n";
    print "-pg_host <postgres-eg-pombe> Default is $pg_host\n";
    print "-pg_port <5432> Default is $pg_port\n";
    print "-pg_user <ensrw> Default is $pg_user\n";
    print "-pg_pass <xxxxx> Default is $pg_pass\n";
    print "-pg_dbname <pombase_chado_v41> Default is $pg_dbname\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "pg_host=s"    => \$pg_host,
                               "pg_port=s"    => \$pg_port,
                               "pg_user=s"    => \$pg_user,
                               "pg_pass=s"    => \$pg_pass,
                               "pg_dbname=s"  => \$pg_dbname,
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

my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$pg_dbname;host=$pg_host;port=$pg_port",
    $pg_user,
    $pg_pass
) or croak();

my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $chado);

my %dbparam = (
                  'dbname'                         => 'PomBase',
                  'organism_id'                    => $biodef->organism_id()->{ucfirst $eg_species},
                  'division'                       => 'EnsemblFungi',
                  'taxon_id'                       => '4896',
                  'example_gene'                   => 'SPAC2F7.03c',
                  'example_location'               => 'I:521420-541420',
                  'example_searchterm'             => 'ribosome',
                  'example_transcript'             => 'SPAC2F7.03c.1',
                  'schema_type'                    => 'core',
                  'schema_version'                 => 66,
                  'provider_name'                  => 'PomBase',
                  'provider_url'                   => 'http://www.pombase.org/',
                  'genebuild_version'              => '2012-03-PomBase',
                  'genebuild_start_date'           => '2012-03-PomBase',
                  'genebuild_last_geneset_update'  => '2012-03',
                  'genebuild_initial_release_date' => '2009-12',
                  'assembly_name'                  => 'EF2',
                  'assembly_default'               => 'EF2',
                  'assembly_date'                  => '2009-05',
                  'genebuild_method'               => 'Imported from PomBase',
                  'genebuild_level'                => 'toplevel',
                  'transcriptbuild_level'          => 'toplevel',
                  'exonbuild_level'                => 'toplevel',
              );

my $sppclass = PomLoader::SpeciesClassification->new(
                       'dba_chado'   => $chado,
                       'dbparams'    => \%dbparam,);
my $taxon = $sppclass->get_organism_taxonomy();

my ($strain, $species, $genus, $common_name) = q{};
my @sppclass = @{ $taxon->{'taxon'} };
if (exists $taxon->{'genus'}) {
    ($strain, $species, $genus, $common_name) = ( $taxon->{'strain'},
                                                  $taxon->{'species'},
                                                  $taxon->{'genus'},
                                                  $taxon->{'common_name'} );
} else {
    my $classsize = scalar @sppclass;
    ($species, $genus) = @sppclass[-2, -1];
    $common_name = $taxon->{'common_name'};
}

open my ($metatable), '>', $savefile or confess;
#
# Schema
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_version', '$dbparam{'schema_version'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (NULL, 'schema_type', '$dbparam{'schema_type'}');\n" or confess;


#
# Provider
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'provider.name', '$dbparam{'provider_name'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'provider.url', '$dbparam{'provider_url'}');\n" or confess;


#
# Assembly
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'assembly.name', '$dbparam{'assembly_name'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'assembly.default', '$dbparam{'assembly_default'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'assembly.date', '$dbparam{'assembly_date'}');\n" or confess;


#
# Genebuild
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.level', '$dbparam{'genebuild_level'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.version', '$dbparam{'genebuild_version'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.start_date', '$dbparam{'genebuild_start_date'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.initial_release_date', '$dbparam{'genebuild_initial_release_date'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.method', '$dbparam{'genebuild_method'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'genebuild.last_geneset_update', '$dbparam{'genebuild_last_geneset_update'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'transcriptbuild.level', '$dbparam{'transcriptbuild_level'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'exonbuild.level', '$dbparam{'exonbuild_level'}');\n" or confess;


#
# Species
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.classification', '$species');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.classification', '$genus');\n" or confess;

foreach my $classificationlevel ( reverse @sppclass[(-(scalar @sppclass)+2)..-3] ) {
    print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.classification', '$classificationlevel');\n" or confess;
}

print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.production_name', '", lc $genus, "_", lc $species, "');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.alias', '$genus $species');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.alias', '$genus $species $strain');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.ensembl_alias_name', '$genus $species $strain');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.scientific_name', '$genus $species $strain');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.short_name', '$common_name');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.taxonomy_id', '$dbparam{'taxon_id'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.division', '$dbparam{'division'}');\n" or confess;
if (length $strain>0) {
    print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'species.strain', '$strain');\n" or confess;
}


#
# Sample.
#
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.search_text', '$dbparam{'example_searchterm'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.gene_param', '$dbparam{'example_gene'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.gene_text', '$dbparam{'example_gene'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.location_param', '$dbparam{'example_location'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.location_text', '$dbparam{'example_location'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.transcript_param', '$dbparam{'example_transcript'}');\n" or confess;
print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.transcript_text', '$dbparam{'example_transcript'}');\n" or confess;
#print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.variation_param', '$dbparam{'example_variation'}');\n" or confess;
#print "INSERT INTO meta (species_id, meta_key, meta_value) VALUES (1, 'sample.variation_text', '",$dbparam{'example_variation'}');\n" or confess;

$metatable->close();

__END__




