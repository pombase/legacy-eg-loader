#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;

use Data::Dumper;
use Getopt::Long;
use POSIX;
use Try::Tiny;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::DBEntry;

my $eg_host    = 'mysql-eg-devel-2.ebi.ac.uk';
my $eg_port    = '4207';
my $eg_user    = 'ensrw';
my $eg_pass    = 'xxxxx';
my $eg_species = 'schizosaccharomyces_pombe';
my $eg_dbname  = 'schizosaccharomyces_pombe_core_21_74_2';
my $accn_file  = 'PomBase2UniProt.tsv';

sub usage {
    print "Usage:\n";
    print "-eg_host <mysql-eg-devel-2.ebi.ac.uk> Default is $eg_host\n";
    print "-eg_port <4207> Default is $eg_host\n";
    print "-eg_user <ensro> Default is $eg_user\n";
    print "-eg_pass <xxxxx> Default is $eg_pass\n";
    print "-eg_species <schizosaccharomyces_pombe> Default is $eg_species\n";
    print "-eg_dbname <schizosaccharomyces_pombe_core_21_74_2> Default is $eg_dbname\n";
    print "-file <PomBase2UniProt.tsv> Default is $accn_file\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("eg_host=s"    => \$eg_host,
                               "eg_port=s"    => \$eg_port,
                               "eg_user=s"    => \$eg_user,
                               "eg_pass=s"    => \$eg_pass,
                               "eg_species=s" => \$eg_species,
                               "eg_dbname=s"  => \$eg_dbname,
                               "file=s"       => \$accn_file,
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

my $file = $accn_file;
open my ($fh), '<', $accn_file or die "Could not open $accn_file: $!";

while ( my $line = <$fh> ) {
	chomp($line);
	my @row = split /\t/, $line;
	my $gene_adaptor = $db->get_adaptor('Gene');
	my $gene = $gene_adaptor->fetch_by_stable_id($row[0]);
	#print "$row[0]\t$row[1]\n";
	my @transcripts = ();
	if ( defined $gene ) {
		@transcripts = @{ $gene->get_all_Transcripts };
	} else {
		push @transcripts, $db->get_adaptor('Transcript')->fetch_by_stable_id($row[0]);
	}
	
	foreach my $transcript ( @transcripts ) {
		if ( !defined $transcript ) {
			print "UNDEFINED: $row[0]\t$row[1]\n";
			next;
		}
		my $translation = $transcript->translation();
		my @dbentries = @{ $translation->get_all_DBEntries("Uniprot/SWISSPROT") };
		
		my $has_sp_entry = 0;
		foreach my $dbentry ( @dbentries ) {
			if ( $dbentry->primary_id() eq $row[1] ) {
				$has_sp_entry = 1;
			}
		}
		
		#
        	# Create a DBEntry for the feature_id
        	#
		if ( $has_sp_entry == 0 ) {
	        	my $uniprot_dbentry = Bio::EnsEMBL::DBEntry -> new (
		            -PRIMARY_ID  => $row[1],
		            -DBNAME      => 'Uniprot/SWISSPROT',
		            -DISPLAY_ID  => $row[1],
		            -INFO_TYPE   => 'NONE',
		        );
		        
		        print Dumper $uniprot_dbentry;
		        
		        $db->get_DBEntryAdaptor->store(
	            	    $uniprot_dbentry,
	            	    $translation->dbID,
	            	    'Translation'
	            	);
		}
	}
	
}
