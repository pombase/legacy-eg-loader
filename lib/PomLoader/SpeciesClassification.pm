package PomLoader::SpeciesClassification;

use Moose;


has 'dba_chado'   => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);

has '_classification'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_classification');

sub get_organism_taxonomy {
    my $self = shift;
    my $classification = $self->_classification();
    return $classification;
}


sub _generate_classification {
    my $self = shift;

#   select 
#       parent.label 
#   from 
#       phylonode as node,
#       phylonode as parent 
#   where 
#       node.left_idx between parent.left_idx and parent.right_idx and 
#       node.label like 'Lmajor' 
#   order by parent.left_idx;
#
#   The query can not be done like this in DBIx, so has so be split into a
#   subquery that is then run against the database.   There might be a way to do
#   it, but I am not sure how and this works for now.

    my $rs_left_idx = $self->dba_chado->resultset('Phylogeny::PhylonodeOrganism')
               ->search({'organism_id' => $self->dbparams->{'organism_id'} })
               ->search_related('phylonode');

    my $rs = $self->dba_chado->resultset('Phylogeny::Phylonode')
               ->search(
                   {
                    'me.left_idx' => { '<=' => $rs_left_idx->get_column('left_idx')->as_query },
                    'me.right_idx' => { '>=' => $rs_left_idx->get_column('left_idx')->as_query },
                   },
                   {order_by => 'left_idx'}
               );
    my @fulltaxon = q{};
    while (my $rs_phylo = $rs->next) {
        push @fulltaxon, $rs_phylo->label;
    }

    my $rs_organism = $self->dba_chado->resultset('Organism::Organism')
               ->search({'organism_id' => $self->dbparams->{'organism_id'} });
    my $organism = $rs_organism->next;
    my @specieslist = split(' ', $organism->species);

    if (defined $organism) {
        return {'taxon'       => \@fulltaxon,
                'genus'       => $organism->genus,
                'species'     => $specieslist[0],
                'strain'      => join( ' ', @specieslist[1..scalar @specieslist -1] ),
                'common_name' => $organism->common_name,
        }
    } else {
        warn "WARNING: No organism data available.   Will use data from table phylonode.\n" or next;
    }

    return {'taxon' => \@fulltaxon};
}


1;

__END__

=head1 NAME

PomLoader::SpeciesClassifcation - Moose module for handling the construction 
                                  of the species classification object.

=head1 DESCRIPTION



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
Bio::Chado::Schema

=back

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut