#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;
use Data::Dumper;
use Getopt::Long;
use POSIX;

use Bio::Chado::Schema;
use PomLoader::BioDefinitions;
use PomLoader::Genotypes;

my $printfull = 0;

my $eg_species = 'schizosaccharomyces_pombe';
my $pg_host    = 'postgres-eg-pombe';
my $pg_port    = '5432';
my $pg_user    = 'ensrw';
my $pg_pass    = 'xxxxx';
my $pg_dbname  = 'pombase_chado_v52';


my $track_progress = 0;

sub usage {
    print "Usage: $0 [-pg_host <pg_host>]\n";
    print "-eg_species <species> Default is $eg_species\n";
    print "-pg_host <postgres-eg-pombe> Default is $pg_host\n";
    print "-pg_port <5432> Default is $pg_port\n";
    print "-pg_user <ensrw> Default is $pg_user\n";
    print "-pg_pass <xxxxx> Default is $pg_pass\n";
    print "-pg_dbname <pombase_chado_v41> Default is $pg_dbname\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_species"   => \$eg_species,
                               "pg_host=s"    => \$pg_host,
                               "pg_port=s"    => \$pg_port,
                               "pg_user=s"    => \$pg_user,
                               "pg_pass=s"    => \$pg_pass,
                               "pg_dbname=s"  => \$pg_dbname);


my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$pg_dbname;host=$pg_host;port=$pg_port",
    $pg_user,
    $pg_pass
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

my $genotypes = PomLoader::Genotypes->new(
                   'dba_chado'    => $chado,
                   'feature_id'   => 109461,
                   'dbparams'     => \%dbparam,
                 );

print "Results\n;";
print Dumper $genotypes->genotypes;