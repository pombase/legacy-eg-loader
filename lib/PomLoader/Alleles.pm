package PomLoader::Alleles;

use Moose;
use Data::Dumper;

has 'dba_chado'     => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);

has 'alleles'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_alleles');


sub number_of_alleles {
    my $self = shift;
    return scalar keys %{ $self->alleles() };
}

sub feature_ids {
  my $self = shift;
  return keys %{$self->alleles()};
}

sub _generate_alleles {
    my $self = shift;
    my $biodef = $self->dbparams->{'biodef'};

    my %alleles = ();
    
    #print $self->feature_id . "\n";
    
    my $rs_alleles = $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                   { 'me.object_id' => $self->feature_id },
                   {}
              )
              ->search_related('subject',
                   {},
                   {select => ['subject.feature_id', 'subject.uniquename', 'subject.name'],
                    join => ['type',
                             {'featureprops' => 'type'},
                             {'feature_relationship_subjects' => ['feature_relationshipprops' => 'type']}
                            ],
                    '+select' => [ 'type_2.name', 'featureprops.value',
                                   'type_3.name', 'feature_relationshipprops.value'
                                 ],
                    '+as' => [ 'featureprop_type', 'value',
                               'frp_type', 'frp_value'
                             ],
                    'where' => { 'type.name' => ['allele'], 'feature_relationship_subjects.object_id' => [$self->feature_id] } },
              );
    
    #print Dumper $rs_alleles;
    while ( my $rs_allele = $rs_alleles->next ) {
      #print Dumper $rs_allele . "\n";
      if (exists $alleles{$rs_allele->feature_id} ) {
#        print "2\t" . $rs_allele->get_column('featureprop_type') . "\t"
#          . $rs_allele->get_column('value') . "\n";
        my %allele = %{$alleles{$rs_allele->feature_id}};
        $allele{$rs_allele->get_column('featureprop_type')} = $rs_allele->get_column('value');
        $rs_allele->get_column('frp_type') => $rs_allele->get_column('frp_value'),
        $alleles{$rs_allele->feature_id} = \%allele;
      } else {
#        print "1\t" . $rs_allele->get_column('featureprop_type') . "\t"
#          . $rs_allele->get_column('value') . "\n";
        $alleles{$rs_allele->feature_id} = { 
          'uniquename' => $rs_allele->uniquename,
          'name'       => $rs_allele->name,
          #$rs_allele->frp_type   => $rs_allele->frp_value,
          $rs_allele->get_column('featureprop_type') => $rs_allele->get_column('value'),
          $rs_allele->get_column('frp_type') => $rs_allele->get_column('frp_value'),
        };
      }
#      $alleles{$rs_allele->feature_id} = { 
#        'uniquename' => $rs_allele->uniquename,
#        'name'       => $rs_allele->name,
#        'value'      => $rs_allele->get_column('value'),
#      };
    }
    
    foreach my $allele_id ( keys %alleles ) {
      #print $allele_id;
      my $rs_alleles_expression = $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                  {
                    'me.object_id'  => $self->feature_id,
                    'me.subject_id' => $allele_id
	              },
                  {
                    join => [{'feature_relationshipprops' => 'type'}],
				    '+select' => [
				      'type.name', 'feature_relationshipprops.value' 
                    ],
                    '+as' => [ 'frp_type', 'frp_value' ]
                }
              );
      
      while ( my $rs_allele_expression = $rs_alleles_expression->next ) {
        if ( defined $rs_allele_expression->get_column('frp_value') ) {
          my %allele = %{$alleles{$allele_id}};
          $allele{$rs_allele_expression->get_column('frp_type')} = $rs_allele_expression->get_column('frp_value');
          $alleles{$allele_id} = \%allele;
        }
      }
    }
    #print "\n";
    #print Dumper %alleles;
    
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};
    return \%alleles;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;