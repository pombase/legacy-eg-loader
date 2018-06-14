#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;
use Data::Dumper;

use Config::Tiny;

# Create a config
my $config = Config::Tiny->new();

# Open the config
$config = Config::Tiny->read( "tracks.txt" );

my %track_sections = ();
my %track_desc     = ();
my $track_string   = "";

# Reading properties
my $tracks = $config->{ENSEMBL_INTERNAL_BIGWIG_SOURCES};
foreach my $t (keys %{$tracks}) {
  if ( !exists $track_sections{$tracks->{$t}} ) {
  	$track_sections{$tracks->{$t}} = 1;
  }
  
  my $track_details = $config->{$t};
  $track_string .= "track $t\n"
                .  "parent $tracks->{$t}\n"
                .  "bigDataUrl $track_details->{source_url}\n"
                .  "shortLabel $track_details->{caption}\n"
                .  "longLabel $track_details->{source_name}\n"
                .  "type bigWig\n"
                .  "colour #263B21\n\n";
  
  $track_desc{$t} = $track_details->{description};
}

#print Dumper $track_string;

$tracks = $config->{ENSEMBL_INTERNAL_BED_SOURCES};
foreach my $t (keys %{$tracks}) {
  if ( !exists $track_sections{$tracks->{$t}} ) {
    $track_sections{$tracks->{$t}} = 1;
  }
  
  my $track_details = $config->{$t};
  $track_string .= "track $t\n"
                .  "parent $tracks->{$t}\n"
                .  "bigDataUrl $track_details->{source_url}\n"
                .  "shortLabel $track_details->{caption}\n"
                .  "longLabel $track_details->{source_name}\n"
                .  "type bed\n"
                .  "colour #263B21\n\n";
  
  $track_desc{$t} = $track_details->{description};
}

$tracks = $config->{ENSEMBL_INTERNAL_BAM_SOURCES};
foreach my $t (keys %{$tracks}) {
  if ( !exists $track_sections{$tracks->{$t}} ) {
    $track_sections{$tracks->{$t}} = 1;
  }
  
  my $track_details = $config->{$t};
  $track_string .= "track $t\n"
                .  "parent $tracks->{$t}\n"
                .  "bigDataUrl $track_details->{source_url}\n"
                .  "shortLabel $track_details->{caption}\n"
                .  "longLabel $track_details->{source_name}\n"
                .  "type bam\n"
                .  "colour #263B21\n\n";

  $track_desc{$t} = $track_details->{description};
}


my $track_composite = "";
foreach my $tSection (keys %track_sections) {
  $track_composite .= "track $tSection\n"
                   .  "compositeTrack on\n"
                   .  "shortLabel $tSection\n"
                   .  "longLabel $tSection\n\n";
}


#print $track_composite;
#print $track_string;
#print Dumper %track_sections;
#print Dumper %track_desc;

foreach my $td (keys %track_desc) {
	open my ($fh), '>', 'track_desc/' . $td . '.html' or die;
	print $fh $track_desc{$td};
	close $fh;
}
