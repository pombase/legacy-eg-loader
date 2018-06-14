package PomLoader::FeaturePublications;

use Moose;
use Data::Dumper;

use Bio::EnsEMBL::DBEntry;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);

has 'get_publications'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_publications');
has 'get_all_publications'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_all_publications');

sub _generate_publications {
    my $self = shift;
    my %publications = ();

    #
    # Get all the Publications.
    #
    my $rs_pubs =
        $self->dba_chado->resultset('Sequence::FeaturePub')
              ->search(
                  {'me.feature_id' => $self->feature_id},
                  {join => ['pub', { 'feature' => 'type' }],
                      '+select' => ['pub.uniquename', 'type.name'],
                      '+as' => ['pubid', 'feautre_type'],
                      'where' => {'pub.type_id' => {'not in' => ['1']}}
                  });

    while ( my $rs_pub = $rs_pubs->next ) {
        #
        # Create a DBEntry for the publication
        #
        my $pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $rs_pub->get_column('pubid'),
            -DBNAME      => 'PUBMED',
            #-RELEASE     => 'NULL',
            #-VERSION     => 1,
            -DISPLAY_ID  => $rs_pub->get_column('pubid'),
            -DESCRIPTION => q{},
            -INFO_TYPE   => 'DIRECT',
            -INFO_TEXT   => $rs_pub->get_column('feature_type'),
        );
        $publications{$rs_pub->get_column('pubid')} = $pub_dbentry;
    }

    return \%publications;
}


sub _generate_all_publications {
    my $self = shift;
    my %publications = ();

    #
    # Get all the Publications.
    # Modify to use associated xrefs
    #
    my $rs_pubs =
        $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                   {object_id => $self->feature_id},
                   {join => ['type'],
                     'where' => {'type.name' => ['part_of']}
                   }
              )
              ->search_related( 'subject',
                  {},
                  {join => [{'feature_pubs' => 'pub'}, 'type', 'featureloc_features' ],
                   '+select' => ['pub.uniquename', 'type_2.name',
                                 'featureloc_features.fmin',
                                 'featureloc_features.fmax',
                                 'featureloc_features.strand',],
                   '+as' => ['pubid', 'feature_type', 'start', 'end', 'strand'] #,
                   # 'where' => {'db.name' => ['PMID']}
                  });
    
    while ( my $rs_pub = $rs_pubs->next ) {
        #
        # Create a DBEntry for the publication
        #
        my ($featurestart, $featureend) = $self->_feature_range(
                                                  $rs_pub->get_column('start'),
                                                  $rs_pub->get_column('end'),
                                                  $rs_pub->get_column('strand'));
        
        my $primary_id = $self->feature_id . '_' . $featurestart . '-'. $featureend;
        my $db_name = 'PUBMED_POMBASE';
        my $pid = ''; 
        if ( defined $rs_pub->get_column('pubid') ) {
        	$primary_id = $rs_pub->get_column('pubid') . '_'. $primary_id;
        	my @pubid = split(m/:/ms, $rs_pub->get_column('pubid'));
        	$pid = $pubid[1];
        	if ( $pubid[0] eq 'DOI' ) {
	          $db_name = 'DOI_POMBASE';
	        }
        }
        my $pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => 'PMPB:' . $pid . '_' . $self->feature_id . '_' . $featurestart . '-'. $featureend,
            -DBNAME      => $db_name,
            #-RELEASE     => 'NULL',
            #-VERSION     => 1,
            -DISPLAY_ID  => $rs_pub->get_column('pubid'),
            -DESCRIPTION => q{},
            -INFO_TYPE   => 'DIRECT',
            -INFO_TEXT   => $rs_pub->get_column('feature_type') . ' ' . $featurestart . '-'. $featureend,
        );
        $publications{$primary_id} = $pub_dbentry;
    }
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};

    return \%publications;
}

# Converts the Chado feature coordinates into Ensembl feature coordinates.
# Chado counts the gaps between bases and resides, whereas Ensembl counts
# the bases and residues.
#
# When making alterations here make the same alterations in Exon.pm and 
# Translation.pm
sub _feature_range {
    my ( $self, $start, $end, $strand ) = @_;
    
    if ( !defined $strand ) {
        return (q{}, q{});
    }
    
    if ($strand eq '1') {
        $start = $start + 1;
    } elsif ($strand eq '-1'){
        $start = $start + 1;
        #$end = $end + 1;
    }
    return ($start, $end);
    
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::FeaturePublications - Extract all publications in relation to a 
                                 given Feature_ID.

=head1 DESCRIPTION

Gets all publications for a given feature id from the Chado database.

=head1 METHODS

=head2 new

 [dba_chado]:
     Bio::Chado::Schema
 [feature_id]:
     String - feature_id from the Chado database.


=head2 get_publications

 Returns an HashRef of Bio::EnsEMBL::DBEntry objects that is populated with
 publication information that is linked to the given feature_id.



=head1 EXAMPLE

    my $feature_publications = PomLoader::FeaturePublications->new(
                                   'dba_chado'  => $self->dba_chado,
                                   'feature_id' => $self->gene_feature_id,);
    my $publications = $feature_publications->get_publications();
    foreach my $publication (@{$publications}) {
        $gene_dbentry->add_synonym($publication);
    }

 Where $gene_dbentry is a Bio::EnsEMBL::DBEntry object for (in this example)
 a gene.

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

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