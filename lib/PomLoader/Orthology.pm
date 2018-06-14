package PomLoader::Orthology;

use Moose;

use Bio::EnsEMBL::DBEntry;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'   => (isa => 'HashRef', is => 'ro', required => 1);

has 'get_orthologues'     => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_orthologues');

sub _generate_orthologues {
    my $self = shift;

    my $rs = $self->dba_chado->resultset('Sequence::FeatureRelationship')
               ->search(
                   {'me.object_id'  => $self->feature_id},
                   {select => [],
                    join => ['type', 'subject'],
                    '+select' => [
                       'subject.uniquename',
                       'subject.name',
                       ],
                    '+as' => ['uniquename', 'name'],
                    'where' => ['type.name' => 'orthologous_to'],
                   }
               );
    my $rs_count = 0;
    my %orthologs;
    while ( my $rs_feature = $rs->next ) {
        #
        # Create a DBEntry for each orthologue
        #
        #print $self->feature_id."\t".$rs_feature->get_column('uniquename') ."\t".$rs_feature->get_column('name')."\n";
        my $orth_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $rs_feature->get_column('uniquename'),
            -DBNAME      => $self->dbparams->{'dbname'}.'_ORTHOLOG',
            #-RELEASE     => 'NULL',
            #-VERSION     => 1,
            -DISPLAY_ID  => $rs_feature->get_column('name'),
            -DESCRIPTION => 'ortholog',
            -INFO_TYPE   => 'SEQUENCE_MATCH',
        );
        $orthologs{$rs_feature->get_column('uniquename')} = $orth_dbentry;
    }
    return \%orthologs;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__