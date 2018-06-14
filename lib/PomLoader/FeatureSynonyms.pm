package PomLoader::FeatureSynonyms;

use Moose;

use Bio::EnsEMBL::DBEntry;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);

has 'get_synonyms'  => ( isa     => 'ArrayRef',
                         is      => 'ro',
                         lazy    => 1, 
                         builder => '_generate_synonyms');

sub _generate_synonyms {
    my $self = shift;
    my @synonyms = ();

    #
    # Get all the synonyms.
    #
    my $rs_synonyms =
        $self->dba_chado->resultset('Sequence::FeatureSynonym')
              ->search(
                  {'me.feature_id' => $self->feature_id},
                  {join => 'synonym',
                      '+select' => ['synonym.name'],
                      '+as' => ['name'],});
    while ( my $rs_synonym = $rs_synonyms->next ) {
        push @synonyms, $rs_synonym->get_column('name');
    }
    return \@synonyms;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::FeatureSynonyms - Extract all synonyms for a given Chado 
                             Feature_ID

=head1 DESCRIPTION

Gets all synonyms for a given feature id from the Chado database.

=head1 METHODS

=head2 new

 [dba_chado]:
     Bio::Chado::Schema
 [feature_id]:
     String - feature_id from the Chado database.


=head2 get_synonyms

 Returns an ArrayRef of synonyms for the given feature_id.



=head1 EXAMPLE

    my $feature_synonyms = PomLoader::FeatureSynonyms->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $self->gene_feature_id,);
    my $synonyms = $feature_synonyms->get_synonyms();
    foreach my $synonym (@{$synonyms}) {
        $gene_dbentry->add_synonym($synonym);
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