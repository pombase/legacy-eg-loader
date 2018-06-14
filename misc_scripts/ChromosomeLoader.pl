#!/usr/bin/env perl

use strict;
use warnings;
use Readonly;
use Carp;
use IO::File;
#use Config::Tiny;
use Getopt::Long;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::Chado::Schema;
use Bio::EnsEMBL::Attribute;

use PomLoader::BioDefinitions;


## Create a config
#my $config = Config::Tiny->new();
#
## Open the config
#$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );
#
## Reading properties
#my $ensembldb = $config->{Spombe_3};
#my $chadodb   = $config->{postgresegpombe};

# Reading properties
#my $ensembldb = $config->{Lmajor};
#my $chadodb   = $config->{GeneDB};
#my %dbparam = (
#                  'dbname'      => 'GeneDB',
#                  'organism_id' => '15',
#              );


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


my $coord_adaptor = $db->get_adaptor('CoordSystem');

my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $chado);

my %dbparam = (
                  'dbname'      => 'PomBase',
                  'organism_id' => $biodef->organism_id()->{ucfirst $eg_species},
              );

my $cs_chr = Bio::EnsEMBL::CoordSystem->new(
    -NAME           => 'chromosome',
    -VERSION        => 'ASM294v2',
    -RANK           => 1,
    #-DBID           => 1,
    #-ADAPTOR        => $coord_adaptor,
    -DEFAULT        => 1,
    -SEQUENCE_LEVEL => 0);

my $cs_contig = Bio::EnsEMBL::CoordSystem->new(
    -NAME           => 'contig',
    -VERSION        => undef,
    -RANK           => 3,
    #-DBID           => 1,
    #-ADAPTOR        => $coord_adaptor,
    -DEFAULT        => 1,
    -SEQUENCE_LEVEL => 1);

$coord_adaptor->store($cs_contig);
$coord_adaptor->store($cs_chr);
$coord_adaptor->store_mapping_path($cs_chr,$cs_contig);

print "Loaded coord_system ...\n" or next;

#
# Generate the coord system and the chromosomes
#
my $rs = $chado->resultset('Sequence::Feature')->search({
    organism_id => $dbparam{'organism_id'},
    type_id => {'in' => [$biodef->biotype_id()->{'chromosome'}, $biodef->biotype_id()->{'mitochondrial_chromosome'}]}
});
my $sliceadaptor = $db->get_adaptor('Slice');
my $contig_count = 1;
while( my $org = $rs->next ) {
    print $org->uniquename,"\n" or croak;
    my $slice_chr = Bio::EnsEMBL::Slice->new(
        -coord_system      => $cs_chr,                    # Coord System
        -start             => 1,                          # Chromosome Start
        -end               => $org->seqlen,               # Chromosome End
        -strand            => 1,              # Strand?
        -seq_region_name   => $org->uniquename,           # Chromosome Name
        -seq_region_length => $org->seqlen,               # Chromosome Length
    #    -adaptor           => $db->get_adaptor('Slice')
    );
    my $slice_contig = Bio::EnsEMBL::Slice->new(
        -coord_system      => $cs_contig,                 # Coord System
        -start             => 1,                          # Contig Start
        -end               => $org->seqlen,               # Contig End
        -strand            => 1,              # Strand?
        -seq_region_name   => "contig_$contig_count",     # Contig Name
        -seq_region_length => $org->seqlen,               # Contig Length
    #    -adaptor           => $db->get_adaptor('Slice')
    );

    print $slice_chr, "\n" or next;
    print $slice_contig, "\n" or next;
    print length($org->residues), "\n" or next;

    # Add seq_region attributes.
    my @attributes;
    my $attribute;

    $attribute =
        Bio::EnsEMBL::Attribute->new(-CODE        => 'name',
                                 -NAME        => 'Name',
                                 -DESCRIPTION => 'User-friendly name',
                                 -VALUE       => 'Chromosome '.$contig_count);
    push @attributes, $attribute;

    # Add 'Top Level' sequence attribute to top-level seq_region.
    $attribute =
        Bio::EnsEMBL::Attribute->new(
                             -CODE        => 'toplevel',
                             -NAME        => 'Top Level',
                             -DESCRIPTION => 'Top Level Non-Redundant Sequence',
                             -VALUE       => '1');
    push @attributes, $attribute;

    # Add codon_table attribute to top-level seq_region.
    if ($org->type_id eq  $biodef->biotype_id()->{'mitochondrial_chromosome'}) {
        $attribute =
             Bio::EnsEMBL::Attribute->new(-CODE        => 'codon_table',
                                     -NAME        => 'Codon table ID',
                                     -DESCRIPTION => 'Codon table ID',
                                     -VALUE       => '4');
        push @attributes, $attribute;
    } else {
        $attribute =
             Bio::EnsEMBL::Attribute->new(-CODE        => 'codon_table',
                                     -NAME        => 'Codon table ID',
                                     -DESCRIPTION => 'Codon table ID',
                                     -VALUE       => '1');
        push @attributes, $attribute;
    }


    $sliceadaptor->store($slice_chr);
    $sliceadaptor->store($slice_contig, \$org->residues);
    $db->get_AttributeAdaptor()->store_on_Slice($slice_chr, \@attributes);
    $sliceadaptor->store_assembly($slice_chr, $slice_contig);

    $contig_count++;

    #$chr{$org->feature_id} = $slice_chr;
    #$contig{$org->feature_id} = $slice_contig;
}

print 'Complete!', "\n" or next;

__END__

=head1 NAME

