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
use Log::Log4perl qw(:easy);
 
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;

use PomLoader::Gene;
use PomLoader::Transcript;
use PomLoader::Translation;
use PomLoader::BioDefinitions;

$| = 1;

my $verbose;
my $printfull = 0;
my $just_genes = 1;
my $chromosome = 2;

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


my $track_progress = 0;

sub usage {
    print "Usage: $0 [-chr <obo>]\n";
    print "-chr <chr_id> Default is $chromosome\n";
    print "-track <0|1> Track the progress of execution\nDefault is $track_progress";
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
    print "-pg_dbname <pombase_chado_v41> Default is $pg_pass\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("chr=i"   => \$chromosome,
                               "track=i" => \$track_progress,
                               "eg_host=s"    => \$eg_host,
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
                               "help"    => sub {usage()});

if(!$options_okay) {
    usage();
}

GetOptions ("verbose"  => \$verbose)   
    or die("Error in command line arguments\n");

if($verbose) {
    Log::Log4perl->easy_init($DEBUG);
} else {
    Log::Log4perl->easy_init($INFO);
}
 
# this call can be in any subsequent piece of code
my $log = get_logger();



# Create a config
#my $config = Config::Tiny->new();

# Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );

# Reading properties
#my $ensembldb = $config->{$eg_db_config};
#my $chadodb   = $config->{postgresegpombe};

#print Dumper $ensembldb;
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

my $dbc_tracker = $db->dbc();

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

my $starttime = time;

my $analysis = Bio::EnsEMBL::Analysis->new(
    -logic_name      => $dbparam{'dbname'},
    -db              => $dbparam{'dbname'},
    -db_version      => 1,
    -description     => "Gene annotated by $dbparam{'dbname'} and imported into Ensembl Genomes",
    -display_label   => $dbparam{'dbname'},
    -displayable     => '1',
    -web_data        => {'caption' => $dbparam{'dbname'},
                            'label_key'  => '[biotype]',
                            'colour_key' => '[biotype]',
                            'name'       => "$dbparam{'dbname'} Genes",
                            'method'     => 'Annotation Method',
                            'default'    => {
                                             'contigviewbottom'     => 'transcript_label',
                                             'contigviewtop'        => 'gene_label',
                                             'cytoview'             => 'gene_label',
                                             'alignsliceviewbottom' => 'transcript_label',
                                             'MultiTop'             => 'gene_label',
                                             'MultiBottom'          => 'transcript_label'
                            }
    }
);



#
# Create a hash of all Chromosome slices
#
my %chr_slice_hash = ();
my $slice_adaptor = $db->get_adaptor('Slice');
my $gene_adaptor = $db->get_adaptor('Gene');

my $chr_slices = $slice_adaptor->fetch_all( 'chromosome' );
#print "Here 1\n";

my $slice_count = 0;
foreach my $slice ( @{ $chr_slices } ) {
    my @genes = @{ $gene_adaptor->fetch_all_by_Slice($slice) };
    ++$slice_count;
    $log->info("Chromosome: " . $slice_count . ' of ' . @{ $chr_slices } . "\tNo. of Genes: " . @genes . ".");
    
    my $gene_count = 0;
    if ( $slice_count != $chromosome ) {
      next;
    }
    #print "Here\n";
    foreach my $gene ( @genes ) {
        $log->debug($gene->stable_id . "\tTotal\tStart:" . time);
#        if ($track_progress == 1) {
#          my $sth = $dbc_tracker->prepare("UPDATE tmp_tracker SET status='LOADING' WHERE stable_id=?");
#          $sth->bind_param(1, $gene->stable_id);
#          $sth->execute();
#          $sth->finish();
#        }
        
        ++$gene_count;
        #if ($gene->stable_id eq 'SPAC2F7.03c') {
        #if ($gene->stable_id eq 'SPBC11B10.09') {
        #if ($gene->stable_id eq 'SPAC1783.07c') {
        #if ($gene->stable_id ne 'SPCC1795.06') {
        #if ($gene->stable_id ne 'SPAC2F7.03c') {
#        if ($gene->stable_id ne 'SPCC1223.13') {
#          next;
#        }
        
#        my $completed = '=';
#        my $pad = '';
#        if ( ($gene_count)*100/(scalar @genes) < 10 ) {
#          $pad = '  ';
#        } elsif ( ($gene_count)*100/(scalar @genes) < 100 ) {
#          $pad = ' ';
#        } 
#        print "\r|" . '='x(($gene_count)*75/(scalar @genes))
#              . '-' x ceil(((scalar @genes - $gene_count)*75/(scalar @genes))) . "| "
#              . $pad . floor(($gene_count)*100/(scalar @genes)) . '%';

        # Get all genes for a given organism
        my $rs = $chado->resultset('Sequence::Feature')
            ->search(
            { 'me.uniquename'  => $gene->stable_id() }
        );
        #print "\tChr: " . $slice_count . "; Gene: " . $gene_count . "\t" . $gene->stable_id . "\n";
        
        if ( my $rs_gene = $rs->next) {
            $log->debug($gene->stable_id . "\tGene:" . $gene->stable_id . "\tStart:" . time);
            my $pl_gene = PomLoader::Gene->new(
                            'dba_ensembl' => $db,
                            'dba_chado'   => $chado,
                            'gene_id'     => $rs_gene->feature_id,
                            'gene'        => $gene,
                            'slice'       => $slice,
                            'analysis'    => $analysis,
                            'dbparams'    => \%dbparam,
                            'current'     => 1);
            
            #print $rs_gene->feature_id . "\n";
            
            #print "Updating Gene\n";
            $pl_gene->update();
            $log->debug($gene->stable_id . "\tGene:" . $gene->stable_id . "\tEnd:" . time);
            
            if (!$just_genes) {
              next;
            }
            
            #print "Test";
            #
            # Obtain all transcripts for a given gene and update annotations.
            #
            my @transcripts = @{ $gene->get_all_Transcripts };
            foreach my $transcript ( @transcripts ) {
                # Get all genes for a given organism
                my $rs_transcript = $chado->resultset('Sequence::Feature')
                    ->search(
                    { 'me.uniquename'  => $transcript->stable_id() }
                );
                my $rs_feature = $rs_transcript->next;
                
                my $featurename = $rs_gene->uniquename;
                if (defined $rs_gene->name) {
                    $featurename = $rs_gene->name;
                }
                
                $log->debug($gene->stable_id . "\tTranscript:" . $transcript->stable_id . "\tStart:" . time);
                my $pl_transcripts = PomLoader::Transcript->new(
                    'dba_ensembl' => $db,
                    'dba_chado'   => $chado,
                    'gene_id'     => $rs_gene->feature_id,
                    'gene_name'   => $featurename,
                    'transcript'  => $transcript,
                    'dbparams'    => \%dbparam,
                    'current'     => 1,
                );
                #print "Updating Transcript\n";
                $pl_transcripts->update();
                $log->debug($gene->stable_id . "\tTranscript:" . $transcript->stable_id . "\tEnd:" . time);
                
                if ( $gene->biotype == 'protein_coding' ) {
	                $log->debug($gene->stable_id . "\tTranslation:" . $transcript->stable_id . "\tStart:" . time);
	                my $pl_translations = PomLoader::Translation->new(
	                    'dba_ensembl'   => $db,
	                    'dba_chado'     => $chado,
	                    'transcript_id' => $rs_feature->feature_id,
	                    'dbparams'      => \%dbparam,
	                );
	                #print "Updating Translation\n";
	                $pl_translations->update();
	                $log->debug($gene->stable_id . "\tTranslation:" . $transcript->stable_id . "\tEnd:" . time);
                }
            }
        }
        
        if ($track_progress == 1) {
          my $sth = $dbc_tracker->prepare("UPDATE tmp_tracker SET status='COMPLETE' WHERE stable_id=?");
          $sth->bind_param(1, $gene->stable_id);
          $sth->execute();
          $sth->finish();
        }
        $log->debug($gene->stable_id . "\tTotal\tEnd:" . time);
    }
}

my $endtime = time;
$log->info('Start: ', $starttime, "\tEnd: ", $endtime, "\tElapsed: ", $endtime-$starttime, "\n") or confess;


# Determines if the $name contains a values that can be used in Ensembl as 
# the short name, if not it uses the $uniquename.   In Chado the $uniquename
# can not be Null or empty.
#sub _feature_name {
#    my ( $self, $uniquename, $name) = @_;
#    if (!defined $name) {
#        return $uniquename;
#    }
#    return $name;
#}


__END__

=head1 NAME

GeneLoader.pl - Script to load genes and their products from a Chado
                database into an EnsEMB database.

=head1 DESCRIPTION

The script will extract all genes, transcripts, translations from ensembl and 
then create all the annotation for each feature from the chado database.   The
annotations are then loaded to the ensembl database.

-------------------------------------------------------------------------------
------------------------------- !!! WARNING !!! -------------------------------
-------------------------------------------------------------------------------
ONLY NEW TERMS ARE LOADED into the database.   DBEntries that are already 
present in the database are NOT UPDATED.
-------------------------------------------------------------------------------
------------------------------- !!! WARNING !!! -------------------------------
-------------------------------------------------------------------------------

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
EnsEMBL API Release v64

=back

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut



