package PomLoader::FeatureXrefs;

use Moose;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);

has 'featurexrefs'     => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_xrefs');

sub _generate_xrefs {
    my $self = shift;
    
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

    my $rs = $self->dba_chado->resultset('Sequence::FeatureDbxref')
               ->search(
                   {'me.feature_id'  => $self->feature_id},
                   {select => ['me.feature_dbxref_id', 'me.feature_id'],
                    join => [{'dbxref' => 'db'}],
                    '+select' => [
                       'dbxref.accession',
                       'dbxref.db_id',
                       'dbxref.description',
                       'db.name',
                       'db.urlprefix'],
                    '+as' => ['accession', 'db_id', 'description', 'db_name', 'db_urlprefix']
                   }
               );
    my $rs_count = 0;
    
    my %featurexrefs = ();
    while ( my $rs_feature = $rs->next ) {
        my $dbname = $rs_feature->get_column('db_name') || q{};
        if (!defined $biodef->db_translate->{$rs_feature->get_column('db_name')}) {
            next;
        }
        #
        # Create a DBEntry for the feature_id
        #
        #print 'Xref: '.$rs_feature->get_column('accession').' ('.$rs_feature->feature_dbxref_id.")\n";
        my $feature_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $rs_feature->get_column('accession'),
            -DBNAME      => $biodef->db_translate->{$rs_feature->get_column('db_name')},
            #-RELEASE     => 1,
            #-VERSION     => 1,
            -DISPLAY_ID  => $rs_feature->get_column('accession'),
            -DESCRIPTION => $rs_feature->get_column('description'),
            -INFO_TYPE   => 'DIRECT',
        );

        $featurexrefs{$rs_feature->feature_dbxref_id} = $feature_dbentry;
    }
    undef($rs);
    
    
    $rs = $self->dba_chado->resultset('Sequence::FeatureCvterm')
              ->search(
                  {'me.feature_id' => $self->feature_id},
                  {select => ['me.feature_cvterm_id', 'me.feature_id'],
                   join => [{'cvterm' => 'cv'},],
                      '+select' => [
                          'cvterm.dbxref_id',
                          'cv.name',
                          'cvterm.name',],
                      '+as' => [
                            'dbxref',
                            'ontology',
                            'name',],
                      'where' => {'cv.name' => 'EC numbers'},
                  });
    while ( my $rs_feature = $rs->next ) {
        #
        # Create a DBEntry for the feature_id
        #
        my $feature_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => 'EC:'.$rs_feature->get_column('name'),
            -DBNAME      => 'EC_NUMBER',
            #-RELEASE     => 1,
            #-VERSION     => 0,
            -DISPLAY_ID  => 'EC:'.$rs_feature->get_column('name'),
            -DESCRIPTION => '',
            -INFO_TYPE   => 'DIRECT',
        );

        $featurexrefs{$rs_feature->feature_cvterm_id} = $feature_dbentry;
    }
    undef($rs);
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};

    return \%featurexrefs;
}

1;