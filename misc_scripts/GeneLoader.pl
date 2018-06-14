#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;

#use Config::Tiny;

use IO::File;
#use Time::Local;
use Getopt::Long;
use POSIX;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::SimpleFeature;

use PomLoader::Gene;
use PomLoader::BioDefinitions;

sub memory_usage() {
    my $t = new Proc::ProcessTable;
    foreach my $got (@{$t->table}) {
        next
            unless $got->pid eq $$;
        return $got->size . "\t" . $got->rss;
    }
}

my $printfull = 0;
my $chromosome = 1;

my $eg_host    = '';
my $eg_port    = '';
my $eg_user    = '';
my $eg_pass    = '';
my $eg_species = '';
my $eg_dbname  = '';

my $pg_host    = '';
my $pg_port    = '';
my $pg_user    = '';
my $pg_pass    = '';
my $pg_dbname  = '';

sub usage {
    print "Usage: $0 [-chr <obo>]\n";
    print "-chr <obo> Default is $chromosome\n";
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

my $options_okay = GetOptions ("chr=i" => \$chromosome,
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
                               "help"  => sub {usage()});

if(!$options_okay) {
    usage();
}

print "Loading Chromosome " . $chromosome . "\n";

#my %dbparam = (
#                  'dbname'                 => 'GeneDB',
#                  'organism_id'            => '15',
#                  'isoforms'               => '1',
#                  'includeobsolete'        => 0,
#                  'includeproteinfeatures' => 0,
#              );
print "================= Here =================\n";
my $db = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    '-host'    => $eg_host,
    '-port'    => $eg_port,
    '-user'    => $eg_user,
    '-group'   => "core",
    '-species' => $eg_species,
    '-dbname'  => $eg_dbname,
    '-pass'    => $eg_pass
);
print "================= Here =================\n";
my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$pg_dbname;host=$pg_host;port=$pg_port",
    $pg_user,
    $pg_pass
) or croak();
print "================= Here =================\n";
my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $chado);
#print $biodef->biotype_id()->{'gene'} . "\n";


my %dbparam = (
                  'dbname'                     => 'PomBase',
                  'organism_id'                => $biodef->organism_id()->{ucfirst $eg_species},
                  'isoforms'                   => '1',
                  'includeobsolete'            => 0,
                  'includeproteinfeatures'     => 1,
                  'transcripts_with_gene_name' => 1,
                  'biodef'                     => $biodef,
              );

my $analysis = Bio::EnsEMBL::Analysis->new(
    -logic_name      => lc $dbparam{'dbname'},
    -db              => $dbparam{'dbname'},
    -db_version      => 1,
    -description     => "Gene annotated by $dbparam{'dbname'} and imported into Ensembl Genomes",
    -display_label   => $dbparam{'dbname'},
    -displayable     => '1',
    -web_data        => {'caption'    => 'Genes',
                         'label_key'  => '[biotype]',
                         'colour_key' => '[biotype]',
                         'name'       => "$dbparam{'dbname'} Genes",
                         'method'     => 'Annotation Method',
                         'key'        => 'ensembl',
                         'default'    => {'contigviewbottom'     => 'transcript_label',
                                          'contigviewtop'        => 'gene_label',
                                          'cytoview'             => 'gene_label',
                                          'alignsliceviewbottom' => 'transcript_label',
                                          'MultiTop'             => 'gene_label',
                                          'MultiBottom'          => 'transcript_label'
                         }
    }
);

#my $simple_feature_analysis = Bio::EnsEMBL::Analysis->new(
#    -logic_name      => $dbparam{'dbname'}.'_SimpleFeature',
#    -db              => $dbparam{'dbname'},
#    -db_version      => 1,
#    -description     => "Simple feature annotated by $dbparam{'dbname'} and imported into Ensembl Genomes",
#    -display_label   => "$dbparam{'dbname'} Sequence Feature",
#    -displayable     => '1',
#    -web_data        => {'caption' => $dbparam{'dbname'},
#                            'label_key'  => '[display_label]',
#                            'name'       => "$dbparam{'dbname'} Sequence Feature",
#                            'key'        => 'pombase_simplefeature',
#                            'default'    => {
#                                             'contigviewbottom'     => 'display_label',
#                                             'contigviewtop'        => 'display_label',
#                                             'cytoview'             => 'display_label'
#                            }
#    }
#);


#
# Create a hash of all Chromosome slices
#
my %chr_slice_hash = ();
my $slice_adaptor = $db->get_adaptor('Slice');
my $chr_slices = $slice_adaptor->fetch_all( 'chromosome' );
my $slice_count = 0;

foreach my $slice ( @{ $chr_slices } ) {
  ++$slice_count;
  print "\nChromosome: " . $slice_count . ' of ' . @{ $chr_slices } . "\n";
  print $slice->seq_region_name . "\n";
  if ( $slice_count != $chromosome ) {
    next;
  }
  $chr_slice_hash{$slice->seq_region_name} = $slice;
}



# Get all genes for a given organism
my $rs = $chado->resultset('Sequence::Feature')
               ->search(
                   {'me.organism_id' => $dbparam{'organism_id'},
                    'me.type_id' => [$biodef->biotype_id()->{'gene'},
                                     $biodef->biotype_id()->{'contig'},
                                     $biodef->biotype_id()->{'pseudogene'},
#                                     $biodef->biotype_id()->{'nuclear_mt_pseudogene'},
#                                     $biodef->biotype_id()->{'origin_of_replication'},
#                                     $biodef->biotype_id()->{'promoter'},
#                                     $biodef->biotype_id()->{'sequence_conflict'},
#                                     $biodef->biotype_id()->{'intron'},
#                                     $biodef->biotype_id()->{'centromere'},
#                                     $biodef->biotype_id()->{'mating_type_region'},
#                                     $biodef->biotype_id()->{'long_terminal_repeat'},
#                                     $biodef->biotype_id()->{'low_complexity_region'},
#                                     $biodef->biotype_id()->{'LTR_retrotransposon'},
#                                     $biodef->biotype_id()->{'TR_box'},
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
my $genecount = 0;
my $genestored = 0;
my $simplefeaturecount = 0;
my $geneskipped = 0;
my $geneerrors = 0;
my $geneobsolete = 0;
my $starttime = time;
while( my $rs_gene = $rs->next) {
#    if ($rs_gene->feature_id == 94448 or $rs_gene->feature_id == 62012 or $rs_gene->feature_id == 80752) {
#    if ($rs_gene->feature_id == 80752) {
#    if ($rs_gene->feature_id == 71896 or $rs_gene->feature_id == 62012) {
#    if ($genecount > 6000 and $genecount < 20000) {
#    if ($genecount < 500) {
	
#	 if ($rs_gene->uniquename ne 'SPAC17A5.19') {
#       next;
#	 }
        
    if ($chr_slice_hash{$rs_gene->get_column('srcfeatureuniquename')}) {
        
        if ($printfull eq 1) { 
            if ($biodef->biotype_id()->{'pseudogene'} == $rs_gene->type_id) {
                print "Pseudogene: $genecount"  or next;
            } else {
                print "Gene: $genecount"  or next;
            }
        }

        if ($rs_gene->is_obsolete==1) {
            $geneobsolete = $geneobsolete + 1;
            if ($dbparam{'includeobsolete'}==0) {
                print "\tObsolete (Skipped to next gene)\n";
                $genecount = $genecount + 1;
                $geneskipped = $geneskipped + 1;
                next;
            }
        }
        
        my $gene = PomLoader::Gene->new(
                       'dba_ensembl' => $db,
                       'dba_chado'   => $chado,
                       'gene_id'     => $rs_gene->feature_id,
                       'analysis'    => $analysis,
                       'slice'       => $chr_slice_hash{$rs_gene->get_column('srcfeatureuniquename')},
                       'dbparams'    => \%dbparam,
                       'current'     => $rs_gene->is_obsolete);
    
        my $output = $gene->genes();
        if (exists $output->{'ERROR'}) {
            $geneskipped = $geneskipped + 1;
            $geneerrors = $geneerrors + 1;
            warn 'ERROR: ', $output->{'ERROR'};
        } else {
            $genestored = $genestored + 1;
            $gene->store();
        }
        undef($gene);
        #print $genecount . "\t" . $rs_gene->feature_id. "\tMemory usage: ", memory_usage(), "\n";
    }
    $genecount = $genecount + 1;
    #my $kids = $chado->storage->dbh->{CachedKids};
    #delete @{$kids}{keys %$kids}
}

my $endtime = time;
print 'Start: ', $starttime, "\tEnd: ", $endtime, "\tElapsed: ", $endtime-$starttime, "\n" or confess;
print "\n\n\tSummary\n" or next;
print "\t=======\n" or next;
print "\tNo. of genes: $genecount\n" or next;
print "\t\tOf which $geneobsolete were obsolete.\n" or next;
print "\t\tOf which $simplefeaturecount were sequence features.\n" or next;
print "\tNo. of genes stored: $genestored\n" or next;
print "\tNo. of skipped genes: $geneskipped\n" or next;
print "\tNo. of ERRORs in Gene Models: $geneerrors\n" or next;


__END__

=head1 NAME

GeneLoader.pl - Script to load genes and their products from a Chado
                database into an EnsEMB database.

=head1 DESCRIPTION

The script will extract all genes, transcripts, translations, exons, associated
GO terms and publications from a specified Chado database and use them to build
the Gene Models that are then loaded into the EnsEMBL database via the API.

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
EnsEMBL API Release v61

=back

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut


