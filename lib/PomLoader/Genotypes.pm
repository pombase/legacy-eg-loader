package PomLoader::Genotypes;

use PomLoader::Alleles;

use Moose;
use Data::Dumper;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'   => (isa => 'HashRef', is => 'ro', required => 1);

has 'genotypes'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_genotypes');


sub genotype_feature_ids {
  my $self = shift;
  return keys %{$self->genotypes()};
}

sub _generate_genotypes {
    my $self = shift;
    my $biodef = $self->dbparams->{'biodef'};
    
    my $base_alleles = PomLoader::Alleles->new(
                         'dba_chado'    => $self->dba_chado,
                         'feature_id'   => $self->feature_id,
                         'dbparams'     => $self->dbparams,
                       );

#    print "Testing, Testing, Testing\n";
#    print Dumper $base_alleles->feature_ids;
#    print "1 ... 2 ... 3\n";
    
    my %genotypes = ();

    foreach my $base_allele_id ( $base_alleles->feature_ids ) {
      my $rs_genotypes = $self->dba_chado->resultset('Sequence::FeatureRelationship')
				              ->search(
				                   { subject_id => $base_allele_id },
				                   {
				                   	 #join => [{'feature_relationshipprops' => 'type'}],
				                   	 # '+select' => [
				                   	 #   'type.name',
                          			 #   'feature_relationshipprops.value'  
				                   	 # ],
				                   	 # '+as' => [ 'frp_type', 'frp_value' ]
				                   }
				              )
				              ->search_related('object',
				                   {},
				                   {select => ['object.feature_id', 'object.uniquename', 'object.name'],
				                    join => ['type',
				                             {'featureprops' => 'type'},
				                            ],
				                    '+select' => [ 'type_2.name', 'featureprops.value' ],
				                    '+as' => [ 'featureprop_type', 'value' ],
				                    'where' => { 'type.name' => ['genotype'] } },
				              );
      while ( my $rs_genotype = $rs_genotypes->next ) {
      	#print $rs_genotype->feature_id;
      	my $genotype_alleles = PomLoader::Alleles->new(
                                 'dba_chado'    => $self->dba_chado,
                                 'feature_id'   => $rs_genotype->feature_id,
                                 'dbparams'     => $self->dbparams,
                               );
      	#print Dumper $genotype_alleles->alleles; 
      	$genotypes{$rs_genotype->feature_id} = { 
          'uniquename' => $rs_genotype->uniquename,
          'alleles'    => $genotype_alleles->alleles,
        };
      }
    }
    
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};
    return \%genotypes;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;