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
use Bio::EnsEMBL::OntologyXref;

use PomLoader::Gene;
use PomLoader::BioDefinitions;

# Create a config
#my $config = Config::Tiny->new();

# Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );

# Reading properties
#my $ensembldb = $config->{Spombe};
#my $chadodb   = $config->{postgresegpombe};


my $printfull = 0;

my $obo        = 'PBO';
my $obofile    = 'PBO.obo';
my $pg_host    = 'postgres-eg-pombe';
my $pg_port    = '5432';
my $pg_user    = 'ensrw';
my $pg_pass    = 'xxxxx';
my $pg_dbname  = 'pombase_chado_v41';


my $track_progress = 0;

sub usage {
    print "Usage: $0 [-obo <obo>]\n";
    print "-obo <obo> Default is $obo\n";
    print "-file <obofile> Default is $obofile\n";
    print "-pg_host <postgres-eg-pombe> Default is $pg_host\n";
    print "-pg_port <5432> Default is $pg_port\n";
    print "-pg_user <ensrw> Default is $pg_user\n";
    print "-pg_pass <xxxxx> Default is $pg_pass\n";
    print "-pg_dbname <pombase_chado_v41> Default is $pg_dbname\n";
    print "-help \n";
    exit 1;
};

my $options_okay = GetOptions ("obo=s"        => \$obo,
                               "file=s"      => \$obofile,
                               "pg_host=s"    => \$pg_host,
                               "pg_port=s"    => \$pg_port,
                               "pg_user=s"    => \$pg_user,
                               "pg_pass=s"    => \$pg_pass,
                               "pg_dbname=s"  => \$pg_dbname,
                               "help"    => sub {usage()});

if(!$options_okay) {
    usage();
}

my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$pg_dbname;host=$pg_host;port=$pg_port",
    $pg_user,
    $pg_pass
) or croak();

my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $chado);

my %obos = (
            'name_description' => 'PBO:1000000',
            'complementation' => 'PBO:2000000',
            'sequence_feature' => 'PBO:3000000',
            # 'sequence' => '',
            'DNA_binding_specificity' => 'PBO:4000000',
            'disease_associated' => 'PBO:5000000',
            'subunit_composition' => 'PBO:6000000',
            'ex_tools' => 'PBO:7000000',
            'gene_ex' => 'PBO:8000000',
            'genome_org' => 'PBO:9000000',
            'species_dist' => 'PBO:1100000',
            'misc' => 'PBO:1200000',
            'warning' => 'PBO:1300000',
            'pathway' => 'PBO:1400000',
            'cat_act' => 'PBO:1900000',
            'RILEY' => 'PBO:1000000',
            'protein_family' => 'PBO:1000000',
            'm_f_g' => 'PBO:1800000',
            #'PomBase annotation extension terms' => '',
            'PomBase gene characterisation status' => 'PBO:1500000',
            'PomBase family or domain' => 'PBO:1600000',
            'PomBase interaction types' => 'PBO:1700000',
            'external_link' => 'PBO:0100000',
            'PSI-MOD' => '',
            'biological_process' => '',
            'molecular_function' => '',
            'cellular_component' => '',
            'fission_yeast_phenotype' => '',
            );

my $generation_time = POSIX::strftime("%m:%d:%Y %H:%M:%S\n", localtime);
my $header = "format-version: 1.2\n"
            ."date: ".$generation_time
            ."saved-by: mdm\n"
            ."auto-generated-by: PomLoader, GenerateOBO.pl, v1.0\n"
            ."synonymtypedef: systematic_synonym 'Systematic synonym' EXACT\n"
            ."default-namespace: pombase\n"
            ."ontology: PBO";
#open my ($fh), '>', '/nfs/panda/ensemblgenomes/development/mcdowall/workingdirectory/release18/data/ontology/PomBase_Ontology_chado_v33_Test.obo' or die;
#open my ($fh), '>', '/homes/mcdowall/Documents/ensembl-ontology/ontologies/GO_chado_ng_v11_1.obo' or die;
#open my ($fh), '>', '/nfs/panda/ensemblgenomes/development/mcdowall/workingdirectory/release18/data/ontology/PSI-MOD_chado_v33.obo' or die;
#open my ($fh), '>', '/homes/mcdowall/Documents/ensembl-ontology/ontologies/FYPO_chado_ng_v19.obo' or die;

#sub usage {
#    print "Usage: $0 [-obo <obo>]\n";
#    print "-obo <obo> Default is $obo\n";
#    print "-file <obofile> Default is $obofile\n";
#    print "-help \n";
#    exit 1;
#};
#
#my $options_okay = GetOptions (
#    "obo|h=s"=>\$obo,
#    "file|P=s"=>\$obofile,
#    "help"=>sub {usage()}
#);
#
#if(!$options_okay) {
#    usage();
#}

if ($obo eq 'PBO') {
  %obos = (
              'name_description' => 'PBO:1000000',
              'complementation' => 'PBO:2000000',
              'sequence_feature' => 'PBO:3000000',
              'DNA_binding_specificity' => 'PBO:4000000',
              'disease_associated' => 'PBO:5000000',
              'subunit_composition' => 'PBO:6000000',
              'ex_tools' => 'PBO:7000000',
              'gene_ex' => 'PBO:8000000',
              'genome_org' => 'PBO:9000000',
              'species_dist' => 'PBO:1100000',
              'misc' => 'PBO:1200000',
              'warning' => 'PBO:1300000',
              'pathway' => 'PBO:1400000',
              'cat_act' => 'PBO:1900000',
              'RILEY' => 'PBO:1000000',
              'protein_family' => 'PBO:1000000',
              'm_f_g' => 'PBO:1800000',
              'PomBase gene characterisation status' => 'PBO:1500000',
              'PomBase family or domain' => 'PBO:1600000',
              'PomBase interaction types' => 'PBO:1700000',
              'external_link' => 'PBO:0100000',
            );
  $header = "format-version: 1.2\n"
            ."date: ".$generation_time
            ."saved-by: mdm\n"
            ."auto-generated-by: PomLoader, GenerateOBO.pl, v1.0\n"
            ."synonymtypedef: systematic_synonym 'Systematic synonym' EXACT\n"
            ."default-namespace: pombase\n"
            ."ontology: PBO\n\n";
} elsif ($obo eq 'MOD') {
  $header = "format-version: 1.2\n"
            ."date: ".$generation_time
            ."saved-by: mdm\n"
            ."auto-generated-by: PomLoader, GenerateOBO.pl, v1.0\n"
            ."synonymtypedef: systematic_synonym 'Systematic synonym' EXACT\n"
            ."default-namespace: MOD\n"
            ."ontology: MOD\n\n";
  %obos = (
            'PSI-MOD' => '',
            );
  # $obofile = 'MOD.obo';
}

open my ($fh), '>', $obofile or die;
print $fh $header;
foreach my $obo ( keys %obos ) {
    # Get all genes for a given organism
    # print $obo."\n";
    print $fh "[Term]\nid: ".$obos{$obo}."\nname: ".$obo."\nnamespace: ".$obo."\n\n";
    
    my $rs = $chado->resultset('Cv::Cv')->search(
        { 'me.name'  => $obo },
        {join => [{'cvterms' => [{'dbxref' => 'db'}]},],
          '+select' => ['cvterms.cvterm_id',
                        'cvterms.dbxref_id',
                        'db.name',
                        'dbxref.accession',
                        'cvterms.name',
                        'cvterms.definition',
                        'cvterms.is_obsolete',],
          '+as' => ['cvterm_id', 'dbxref', 'db_name', 'db_accession', 'name', 'definition', 'is_obsolete']
        }
    );
    
    while ( my $rs_term = $rs->next ) {
        my $term = '';
        my $ontology = '';
        if ( $rs_term->get_column('db_name') eq 'PomBase' ) {
            $ontology = 'PBO';
        } else {
            $ontology = $rs_term->get_column('db_name');
        }
        $term .= "[Term]\n";
#        print $rs_term->get_column('cvterm_id');
#        print "\t".$rs_term->get_column('db_name').':';
#        print $rs_term->get_column('db_accession');
#        print "\t".$rs_term->get_column('name')."\n";
        $term .= 'id: '.$ontology.':'.$rs_term->get_column('db_accession')."\n";
        $term .= 'name: '.$rs_term->get_column('name')."\n";
        $term .= 'namespace: '.$obo."\n";
        if ( defined $rs_term->get_column('definition') ) {
            $term .= 'def: "'.$rs_term->get_column('definition').'" []'."\n";
        }
        my $rs_relationships = $chado->resultset('Cv::CvtermRelationship')->search(
            {
                'me.subject_id' => $rs_term->get_column('cvterm_id')
            }, {
                'join' => [{'object' => 'dbxref'},'type'],
                '+select' => ['object.name','dbxref.accession','type.name'],
                '+as' => ['object_name', 'object_accession', 'type_name'],
                #'+where' => {'type.name' => {'in' => ['is_a', 'part_of']}},
            }
        );
        while ( my $rs_relationship = $rs_relationships->next ) {
            if ($rs_relationship->get_column('type_name') eq 'is_a') {
                $term .= $rs_relationship->get_column('type_name').': ';
                $term .= $ontology.':'.$rs_relationship->get_column('object_accession');
                $term .= ' ! '.$rs_relationship->get_column('object_name')."\n";
            } else {
                $term .= 'relationship: '.$rs_relationship->get_column('type_name').' ';
                $term .= $rs_term->get_column('db_name').':'.$rs_relationship->get_column('object_accession');
                $term .= ' ! '.$rs_relationship->get_column('object_name')."\n";
            }
        }
        
        if ( $ontology eq 'PBO' ) {
          $term .= 'is_a: '.$obos{$obo}."\n";
        }
        
        if ( $rs_term->get_column('is_obsolete') == 1 ) {
            $term .= "is_obsolete: true\n";
        }
        $term .= "\n";
        print $fh $term;
    }
    
}

close $fh;




__END__
