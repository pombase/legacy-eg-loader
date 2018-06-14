package PomLoader::ProteinFeatures;

use Moose;
use Bio::EnsEMBL::Analysis;
use Bio::EnsEMBL::ProteinFeature;

has 'dba_ensembl'   => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'     => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'srcfeature_id' => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'      => ( isa => 'HashRef', is => 'ro', required => 1 );

has '_proteinfeatures'    => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_proteinfeatures');

sub get_proteinfeatures {
    my $self = shift;
    my $protfeathash = $self->_proteinfeatures();
    return $protfeathash->{protfeat};
}


sub get_interpromapping {
    my $self = shift;
    my $protfeathash = $self->_proteinfeatures();
    return $protfeathash->{iprmapping};
}



# type_id |                name                | cv_id 
#---------+------------------------------------+-------
#      87 | region                             |    10
#     191 | polypeptide                        |    10
#     234 | exon                               |    10
#     236 | contig                             |    10
#     291 | five_prime_UTR                     |    10
#     321 | mRNA                               |    10
#     339 | rRNA                               |    10
#     340 | tRNA                               |    10
#     361 | snRNA                              |    10
#     362 | snoRNA                             |    10
#     401 | direct_repeat                      |    10
#     423 | pseudogene                         |    10
#     427 | chromosome                         |    10

#     595 | pseudogenic_exon                   |    10
#     604 | pseudogenic_transcript             |    10
#     743 | ncRNA                              |    10
#     745 | repeat_region                      |    10
#     792 | gene                               |    10
#     814 | repeat_unit                        |    10
#     818 | gap                                |    10

#     436 | protein_match                      |    10    Orthologous match

#     504 | polypeptide_domain                 |    10
#     506 | signal_peptide                     |    10
#    1158 | membrane_structure                 |    10
#    1160 | cytoplasmic_polypeptide_region     |    10
#    1161 | non_cytoplasmic_polypeptide_region |    10
#    1164 | transmembrane_polypeptide_region   |    10
#  168350 | GPI_anchor_cleavage_site           |    28

sub _generate_proteinfeatures {
    my $self = shift;
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};
    my %proteinfeatures = ();
    my %interpromapping = ();

    # Get all the protein features.
    my $rs_proteinfeatures =
        $self->dba_chado->resultset('Sequence::Featureloc')
              ->search({'me.srcfeature_id' => $self->srcfeature_id})
              ->search_related('feature',
                       {}, # 'feature.type_id' => ['504', '506', '1158', '1160', '1161', '1164', '168350']},
                       {join => ['featureloc_features',
                                 'type',
                                 {'dbxref' => 'db'},
                                 'analysisfeatures',
                                 {'feature_dbxrefs' => 'dbxref'}],
                        '+select' => [
                           {extract => 'EPOCH FROM feature.timeaccessioned'},
                           {extract => 'EPOCH FROM feature.timelastmodified'},
                           'featureloc_features.fmin',
                           'featureloc_features.fmax',
                           'featureloc_features.strand',
                           'featureloc_features.phase',
                           'type.name',
                           'type.definition',
                           'dbxref.accession',
                           'dbxref.description',
                           'dbxref.db_id',
                           'db.name',
                           'db.description',
                           'analysisfeatures.rawscore',
                           'dbxref_2.accession',
                           'dbxref_2.db_id',
                           'dbxref_2.description',
                           'db.name',],
                        '+as' => ['epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase', 'type_name', 'type_definition', 'accession', 'description', 'db_id', 'db_name', 'db_description', 'score', 'interpro_acc', 'interpro_db_id', 'interpro_description', 'interpro_db_name'],
                        'where' => { 'type.name' => { 'in' => [
                                'polypeptide_domain',
                                'signal_peptide',
                                'membrane_structure',
                                'cytoplasmic_polypeptide_region',
                                'non_cytoplasmic_polypeptide_region',
                                'transmembrane_polypeptide_region',
                                'GPI_anchor_cleavage_site',
                            ]}}
                       });
    while ( my $rs_proteinfeature = $rs_proteinfeatures->next ) {

        #print $rs_proteinfeature->feature_id, "\t" or confess;
        #print $rs_proteinfeature->uniquename, "\t" or confess;
        #print $rs_proteinfeature->get_column('strand'), "\t" or confess;
        #print $rs_proteinfeature->get_column('phase'), "\t" or confess;
        #print $rs_proteinfeature->get_column('accession'), "\n" or confess;
        #print $rs_proteinfeature->get_column('description'), "\t" or confess;
        #print $rs_proteinfeature->get_column('db_name'), "\t" or confess;
        #print $rs_proteinfeature->get_column('interpro_description'), "\t" or confess;
        #print $rs_proteinfeature->get_column('interpro_acc'), "\t" or confess;
        #print $rs_proteinfeature->get_column('interpro_db_id'), "\n" or confess;

        my ($featurestart, $featureend) = $self->_feature_range(
                                          $rs_proteinfeature->get_column('fmin'),
                                          $rs_proteinfeature->get_column('fmax'),
                                          $rs_proteinfeature->get_column('strand'));

        my $dbname = q{};
        if ($rs_proteinfeature->get_column('type_name') eq 'polypeptide_domain') {
            $dbname = $rs_proteinfeature->get_column('db_name');
        } else {
            $dbname = $self->dbparams->{'dbname'};
        }


        my $analysis = Bio::EnsEMBL::Analysis->new(
            -id              => 1,
            -logic_name      => $dbname,
            -db              => $dbname,
            -db_version      => 1,
            -description     => $rs_proteinfeature->get_column('type_definition'),
            -display_label   => $dbname,
            -displayable     => '1',
            -web_data        => {'type' => 'domain'}
        );
        my $feat = Bio::EnsEMBL::ProteinFeature->new(
                       -start      => $featurestart,
                       -end        => $featureend,
                       -strand     => $rs_proteinfeature->get_column('strand'),
                       #-slice      => $slice,
                       -hstart     => 0,
                       -hend       => 0,
                       -hstrand    => 1,
                       -score      => $rs_proteinfeature->get_column('score') || 0,
                       -percent_id => 0,
                       -hseqname   => $rs_proteinfeature->get_column('accession') || $rs_proteinfeature->uniquename,
                       -analysis   => $analysis
        );

        if (defined $rs_proteinfeature->get_column('interpro_acc') &&
                    $rs_proteinfeature->get_column('interpro_db_name') eq 'InterPro') {
            my $accession = $rs_proteinfeature->get_column('interpro_acc');

            my $ipr_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $accession,
                -DBNAME      => 'Interpro',
                #-RELEASE     => 'NULL',
                #-VERSION     => 1,
                -DISPLAY_ID  => $accession,
                -DESCRIPTION => $rs_proteinfeature->get_column('interpro_description'),
                -INFO_TYPE   => 'MISC',
            );
            $self->dba_ensembl->get_DBEntryAdaptor->store($ipr_dbentry);

            if ( exists $interpromapping{ $accession } ) {
                my @a = @{$interpromapping{ $accession }};
                my %a1 = map { $_ => 1 } @a;                                    # Create map of values in @a1
                if (!$a1{$accession}) {
                    push @a, $rs_proteinfeature->get_column('accession');
                }
                $interpromapping{ $accession } = \@a;
            } else {
                my @a = ($rs_proteinfeature->get_column('accession'));
                $interpromapping{ $accession } = \@a;
            }
        }
        $proteinfeatures{$rs_proteinfeature->feature_id} = $feat;
    }
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};
    
    return {protfeat   => \%proteinfeatures,
            iprmapping => \%interpromapping};
}


sub _feature_range {
    my ( $self, $start, $end, $strand ) = @_;
    if ($strand eq '1' or $strand eq '0') {
        if ($start ne $end) {
            $start = $start + 1;
        }
    } elsif ($strand eq '-1'){
        $start = $start + 1;
        #$end = $end - 1;
    }
    return ($start, $end);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::ProteinFeatures - Moose module for handling the construction and 
                             loading of EnsEMBL Protein Features.

=head1 DESCRIPTION

This is a perl module that handles the extraction of protein features from the 
Chado database.   The module handles the polypeptide domains and any associated
InterPro annotations.

The module now works as a single SQL query, which has resulted in a slight 
increase in the speed of loading as orginally it required Number of features 
+ 1 number of queries to the database as it ran via a loop then got the 
InterPro accessions.

The module is also able to annotate GPI anchors, membrane regions and regions 
of peptides that are cytoplasmic and non-cytoplasmic.   The analysis
descriptions and definitions and names for the database that they originate
from are assigned based on the type of feature that they are as they are all
derived from the Chado database. 


=head1 METHODS

=head2 new

 [dba_ensembl]:
     Bio::EnsEMBL::DBSQL::DBAdaptor
 [dba_chado]:
     Bio::Chado::Schema
 [feature_id]:
     String - Translation feature_id from the Chado database.

=head2 get_proteinfeatures

 Getter of a HashRef of all the protein features for a given translation

=head2 get_interpromapping

 Getter of a HashRef of all the InterPro annotations for a given
 translation


=head1 SYNOPSIS

#
# Populate all information about the protein
#
my $proteinfeatures = PomLoader::ProteinFeatures->new(
                 'dba_ensembl'   => $self->dba_ensembl,
                 'dba_chado'     => $self->dba_chado,
                 'srcfeature_id' => $rs_translation->feature_id,
             );
my $proteinfeatures_dbentries = $proteinfeatures->get_proteinfeatures();

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

=item
EnsEMBL API Release v61

=item
Bio::Chado::Schema

=back

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut

