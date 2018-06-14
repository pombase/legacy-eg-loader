#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use diagnostics;

use Getopt::Long;
use POSIX;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;

use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::SimpleFeature;
use Bio::EnsEMBL::RepeatFeature;
use Bio::EnsEMBL::RepeatConsensus;

use Data::Dumper;

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
                               "help"  => sub {usage()});

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
#print $biodef->biotype_id()->{'gene'} . "\n";
#print Dumper $biodef->organism_id();
#print $biodef->organism_id()->{ucfirst $eg_species};

my %dbparam = (
                  'dbname'                     => 'PomBase',
                  'organism_id'                => $biodef->organism_id()->{ucfirst $eg_species},
                  'isoforms'                   => '1',
                  'includeobsolete'            => 0,
                  'includeproteinfeatures'     => 1,
                  'transcripts_with_gene_name' => 1,
                  'biodef'                     => $biodef,
              );

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
  $chr_slice_hash{$slice->seq_region_name} = $slice;
}



my %logicname2caption = (
  'dg_repeat'             => 'dg Repeat',
  'dh_repeat'             => 'dh Repeat',
  'intron'                => 'ConfirmedIntron',
  'long_terminal_repeat'  => 'LTR',
  'low_complexity_region' => 'Low complexity gene free region',
  'LTR_retrotransposon'   => 'LTR retrotransposon',
  'mating_type_region'    => 'MTR',
  'nuclear_mt_pseudogene' => 'NuMT',
  'origin_of_replication' => 'Origin of Replication',
  'polyA_signal_sequence' => 'polyA Signal Sequence',
  'polyA_site'            => 'polyA Site',
  'promoter'              => 'Promoter',
  'regional_centromere'   => 'Centromere',
  'regional_centromere_central_core'        => 'Centromere Core',
  'regional_centromere_inner_repeat_region' => 'Centromere RR',
  'repeat_region'         => 'Repeat Region',
  'TR_box'                => 'TR Box'
);

my %logicname2name = (
  'dg_repeat'             => 'PomBase Annotated dg Repeat',
  'dh_repeat'             => 'PomBase Annotated dh Repeat',
  'intron'                => 'PomBase Annotated Intron',
  'long_terminal_repeat'  => 'PomBase Annotated Long Terminal Repeat',
  'low_complexity_region' => 'PomBase Annotated Low complexity gene free region',
  'LTR_retrotransposon'   => 'PomBase Annotated LTR retrotransposon',
  'mating_type_region'    => 'PomBase Annotated Mating Type Region',
  'nuclear_mt_pseudogene' => 'PomBase Annotated Nuclear MT Pseudogene',
  'origin_of_replication' => 'PomBase Annotated Origin of Replication',
  'polyA_signal_sequence' => 'PomBase Annotated polyA Signal Sequence',
  'polyA_site'            => 'PomBase Annotated polyA Site',
  'promoter'              => 'PomBase Annotated Promoter',
  'regional_centromere'   => 'PomBase Annotated Centromere',
  'regional_centromere_central_core'        => 'PomBase Annotated Centromeric Core',
  'regional_centromere_inner_repeat_region' => 'PomBase Annotated Centromeic Inner Repeat Region',
  'repeat_region'         => 'PomBase Annotated Repeat Region',
  'TR_box'                => 'PomBase Annotated TR Box'
);

my %logicname2so = (
  'dg_repeat'             => {'id' => 'SO:0001898', 'description' => 'A repeat region which is part of the regional centromere outer repeat region'},
  'dh_repeat'             => {'id' => 'SO:0001899', 'description' => 'A repeat region which is part of the regional centromere outer repeat region'},
  'intron'                => {'id' => 'SO:0000188', 'description' => 'A region of a primary transcript that is transcribed, but removed from within the transcript by splicing together the sequences (exons) on either side of it'},
  'long_terminal_repeat'  => {'id' => 'SO:0000286', 'description' => 'A sequence directly repeated at both ends of a defined sequence, of the sort typically found in retroviruses'},
  'low_complexity_region' => {'id' => 'SO:0001005', 'description' => 'low complexity region'},
  'LTR_retrotransposon'   => {'id' => 'SO:0000186', 'description' => 'A retrotransposon flanked by long terminal repeat sequences'},
  'mating_type_region'    => {'id' => 'SO:0001789', 'description' => 'A specialized region in the genomes of some yeast and fungi, the genes of which regulate mating type'},
  'nuclear_mt_pseudogene' => {'id' => 'SO:0001044', 'description' => 'A nuclear pseudogene of either coding or non-coding mitochondria derived sequence'},
  'origin_of_replication' => {'id' => 'SO:0000296', 'description' => 'The origin of replication; starting site for duplication of a nucleic acid molecule to give two identical copies'},
  'polyA_signal_sequence' => {'id' => 'SO:0000551', 'description' => 'The recognition sequence necessary for endonuclease cleavage of an RNA transcript that is followed by polyadenylation; consensus=AATAAA'},
  'polyA_site'            => {'id' => 'SO:0000553', 'description' => 'The site on an RNA transcript to which will be added adenine residues by post-transcriptional polyadenylation. The boundary between the UTR and the polyA sequence'},
  'promoter'              => {'id' => 'SO:0000167', 'description' => 'A regulatory_region composed of the TSS(s) and binding sites for TF_complexes of the basal transcription machinery'},
  'regional_centromere'   => {'id' => 'SO:0001795', 'description' => 'A regional centromere is a large modular centromere found in fission yeast and higher eukaryotes. It consist of a central core region flanked by inverted inner and outer repeat regions'},
  'regional_centromere_central_core'        => {'id' => 'SO:0001796', 'description' => 'A conserved region within the central region of a modular centromere, where the kinetochore is formed'},
  'regional_centromere_inner_repeat_region' => {'id' => 'SO:0001798', 'description' => 'The inner inverted repeat region of a modular centromere and part of the central core surrounding a non-conserved central region. This region is adjacent to the central core, on each chromosome arm'},
  'repeat_region'         => {'id' => 'SO:0000657', 'description' => 'A region of sequence containing one or more repeat units'},
  'TR_box'                => {'id' => 'SO:0001858', 'description' => 'A promoter element with consensus sequence TTCTTTGTTY, bound an HMG-box transcription factor such as S. pombe Ste11, and found in promoters of genes up-regulated early in meiosis'},
);

my %is_a_repeat = (
  'dg_repeat' => 1,
  'dh_repeat' => 1,
  'long_terminal_repeat' => 1,
  'regional_centromere_inner_repeat_region' => 1,
  'repeat_region' => 1,
  'LTR_retrotransposon' => 1,
  'low_complexity_region' => 1
);



# Get all genes for a given organism
#print Dumper $biodef->biotype_id();
my $rs = $chado->resultset('Sequence::Feature')
               ->search(
                   {'me.organism_id' => $dbparam{'organism_id'},
                    'me.type_id' => [$biodef->biotype_id()->{'dg_repeat'},
                                     $biodef->biotype_id()->{'dh_repeat'},
                                     $biodef->biotype_id()->{'intron'},
                                     $biodef->biotype_id()->{'long_terminal_repeat'},
                                     $biodef->biotype_id()->{'low_complexity_region'},
                                     $biodef->biotype_id()->{'LTR_retrotransposon'},
                                     $biodef->biotype_id()->{'mating_type_region'},
                                     $biodef->biotype_id()->{'nuclear_mt_pseudogene'},
                                     $biodef->biotype_id()->{'origin_of_replication'},
                                     $biodef->biotype_id()->{'polyA_signal_sequence'},
                                     $biodef->biotype_id()->{'polyA_site'},
                                     $biodef->biotype_id()->{'promoter'},
                                     $biodef->biotype_id()->{'regional_centromere'},
                                     $biodef->biotype_id()->{'regional_centromere_central_core'},
                                     $biodef->biotype_id()->{'regional_centromere_inner_repeat_region'},
                                     $biodef->biotype_id()->{'repeat_region'},
                                     $biodef->biotype_id()->{'TR_box'},
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
my $simplefeaturecount = 0;
my $repeatfeaturecount = 0;
my $starttime = time;
while( my $rs_sf = $rs->next) {
  #print $rs_sf->get_column('srcfeatureuniquename') + "\n";
  if ($chr_slice_hash{$rs_sf->get_column('srcfeatureuniquename')}) {
    #print lc($biodef->biotype()->{$rs_sf->type_id}) + "\n";
    my $analysis_description = "Simple feature annotated by $dbparam{'dbname'} and imported into Ensembl Genomes";
    if ( exists $is_a_repeat{$biodef->biotype()->{$rs_sf->type_id}} ) {
    	$analysis_description = "Repeat feature annotated by $dbparam{'dbname'} and imported into Ensembl Genomes";
    }
    
    my $analysis = Bio::EnsEMBL::Analysis->new(
      -logic_name      => lc($biodef->biotype()->{$rs_sf->type_id}),
      -db              => $dbparam{'dbname'},
      -db_version      => 1,
      -description     => $analysis_description,
      -display_label   => $logicname2caption{$biodef->biotype()->{$rs_sf->type_id}},
      -displayable     => '1',
      -web_data        => {'caption' => $logicname2caption{$biodef->biotype()->{$rs_sf->type_id}},
                           'label_key'  => '[display_label]',
                           'name'       => $logicname2name{$biodef->biotype()->{$rs_sf->type_id}} 
                                           . " (" . $logicname2so{$biodef->biotype()->{$rs_sf->type_id}}{'description'} . ")",
                           #'key'        => 'pombase_simplefeature',
                           'default'    => {
                                             'contigviewbottom'     => 'display_label',
                                             'contigviewtop'        => 'display_label',
                                             'cytoview'             => 'display_label'
                          }
      }
    );
    
    my $analysis_id = $db->get_AnalysisAdaptor->store($analysis);
    
    if ( exists $is_a_repeat{$biodef->biotype()->{$rs_sf->type_id}} ) {
    	# RepeatFeature also requires a RepeatConsensus object as well as the $analysis.
    	my $repeat_consensus = Bio::EnsEMBL::RepeatConsensus->new(
    	   -NAME         => $rs_sf->uniquename,
    	   -REPEAT_CLASS => 'Manual_Annotation',
    	   -REPEAT_TYPE  => $logicname2caption{$biodef->biotype()->{$rs_sf->type_id}},
    	);
    	
    	# Need to convert to a RepeatFeature
    	my $repeat_feature = Bio::EnsEMBL::RepeatFeature->new(
          -start         => $rs_sf->get_column('featureloc_start'),
          -end           => $rs_sf->get_column('featureloc_end'),
          -strand        => $rs_sf->get_column('featureloc_strand'),
          -slice         => $chr_slice_hash{$rs_sf->get_column('srcfeatureuniquename')},
          -analysis      => $analysis,
          -repeat_consensus => $repeat_consensus,
          -hstart        => 1,
          -hend          => $rs_sf->get_column('featureloc_end')-$rs_sf->get_column('featureloc_start')+1,
          -score         => 1,
        );
        $db->get_RepeatFeatureAdaptor->store($repeat_feature);
        $repeatfeaturecount += 1;
    } else {
	    my $simplefeature = Bio::EnsEMBL::SimpleFeature->new(
	      -start         => $rs_sf->get_column('featureloc_start'),
	      -end           => $rs_sf->get_column('featureloc_end'),
	      -strand        => $rs_sf->get_column('featureloc_strand'),
	      -slice         => $chr_slice_hash{$rs_sf->get_column('srcfeatureuniquename')},
	      -analysis      => $analysis,
	      -score         => 1,
	      -display_label => $rs_sf->uniquename,
	    );
	    $db->get_SimpleFeatureAdaptor->store($simplefeature);
	    $simplefeaturecount += 1;
    }
  }
}

my $endtime = time;
print 'Start: ', $starttime, "\tEnd: ", $endtime, "\tElapsed: ", $endtime-$starttime, "\n" or confess;
print "\n\n\tSummary\n" or next;
print "\t=======\n" or next;
print "\t\tOf which $simplefeaturecount were simple sequence features.\n" or next;
print "\t\tOf which $repeatfeaturecount were repeat sequence features.\n" or next;


__END__

=head1 NAME

SimpleFeatureLoader.pl - Script to load simple features from the Chado database
                         into an EnsEMB database.

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


