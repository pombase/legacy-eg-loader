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

my $gene_id    = '';
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
    print "-gene_id <SPAC2F7.03c> : Using $gene_id\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "gene_id=s"    => \$gene_id,
                               "help"         => sub {usage()});

if ( !$eg_host or !$eg_port or !$eg_user or !$eg_pass or
     !$eg_species or !$eg_dbname or !$gene_id
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

my $gene = $gene_adaptor->fetch_by_stable_id($gene_id);

foreach my $translation ( @{ $gene->get_all_Transcripts } ) {
    print $translation->translate()->seq . "\n\n";
}

print $gene->stable_id . "\n";

#foreach my $entry ( @{ $gene->get_all_DBLinks } ) {
#  print "\t" . $entry->primary_id . "\n";
#  next;
#  if (ref $entry eq 'Bio::EnsEMBL::OntologyXref') {
#    print "\t" . $entry->primary_id;
#    print " <== Ontolopgy Term\n";
#    #print Data::Dumper->Dumper([$entry->get_all_associated_xrefs()]);
##    if ( $entry->primary_id eq 'FYPO:0000839' ) {
##      print Data::Dumper->Dumper([$entry->get_all_associated_xrefs]);
##    }
#    print "\t\tgid\tr" 
#          . "\tAX"
#          . "\tSX"
#          . "\tCT\n";
#    my $count = 0;
#    my %assoc_xrefs = %{ $entry->get_all_associated_xrefs() };
#    my @h_keys = keys %assoc_xrefs;
#    for (my $h = 0; $h < @h_keys; $h++) {
#      my $group = $assoc_xrefs{$h_keys[$h]};
#      my @i_keys = keys %{$group};
#      @i_keys = sort(@i_keys);
#      for (my $i = 0; $i < @i_keys; $i++) {
#        my @as = @{$group->{$i_keys[$i]}};
#        if (!defined($as[0])) {
#          next;
#        } 
#        print "\t\t" . $h_keys[$h] . "\t" . $i_keys[$i];
#        print "\t" . $as[0]->primary_id . ' (' . $as[0]->display_id . ')'; 
#        print "\t" . $as[1]->primary_id;
#        print "\t" . $as[2] . "\n";
#      }
#      $count++;
#    }
#    print "----------------------------------------------------------------\n";
#    print "---------------------Web Data-----------------------------------\n";
#    print "----------------------------------------------------------------\n";
#    my @rows = @{$entry->get_extensions};
#    print Dumper(@rows);
#    foreach my $row ( @rows ) {
#      #print Data::Dumper->Dumper($row);
#      my %r = %{$row};
#      print $r{'evidence'} . ' | ';
#      print $r{'description'} . ' | ';
#      print $r{'source'};
#      print "\n";
#    }
#    print "----------------------------------------------------------------\n";
#    print "----------------------------------------------------------------\n";
#    print "----------------------------------------------------------------\n";
#    
#  }
#}
