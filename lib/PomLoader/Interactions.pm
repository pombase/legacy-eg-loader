package PomLoader::Interactions;

use Moose;

use Bio::EnsEMBL::DBEntry;
use Data::Dumper;
use Try::Tiny;

has 'dba_ensembl' => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'   => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id'  => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);

has 'get_interactions'     => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_interactions');

sub _generate_interactions {
    my $self = shift;

    my $biodef = $self->dbparams->{'biodef'};
    
    my $rs = $self->dba_chado->resultset('Sequence::FeatureRelationship')
               ->search(
                   {-or => [{'me.object_id'  => $self->feature_id}, {'me.subject_id' => $self->feature_id}] },
                   {select => [],
                    join => [{ 'type' => [{ 'dbxref' => 'db' }, 'cv' ] }, 
                             'subject', 'object', 
                             {'feature_relationshipprops' => 'type' }, 
                             {'feature_relationship_pubs' => 'pub' } ],
                    '+select' => [
                       'subject.feature_id', 'subject.uniquename', 'subject.name',
                       'object.feature_id', 'object.uniquename', 'object.name',
                       'type_2.name',
                       'feature_relationshipprops.value',
                       'type.name',
                       'db.name',
                       'dbxref.accession',
                       'pub.uniquename',
                       ],
                    '+as' => ['sub_id', 'sub_uniquename', 'sub_name',
                              'ob_id', 'ob_uniquename', 'ob_name',
                              'prop_type', 'prop_value',
                              'interaction_type',
                              'dbname', 'accession', 'pmid',
                             ],
                    'where' => ['cv.name' => 'PomBase interaction types',
                                #'or' => [{'me.object_id' => $self->feature_id}, {'me.subject_id' => $self->feature_id}],
                    ],
                   }
               );
    my $rs_count = 0;
    my %interactions;
    
    #
    # This while loop should construct the interactions hash.   The result
    # should be a hash that is ordered by:
    #
    #  |--> Interaction type (genetic or physical)
    #      |--> Feature Relationship ID (This is unique for each interaction)
    #          |--> feature_id
    #          |--> feature stable id
    #          |--> feature name
    #          |--> evidence (Description of the assay performed)
    #          |--> source database (e.g. BioGRID)
    #
    # Due to the evidence and the source_database not coming out in the same
    # row, this loop does not generate the xref objects.
    #
    while ( my $rs_feature = $rs->next() ) {
        my %partner = (); 
        if ( exists $interactions{$rs_feature->get_column('interaction_type')}{$rs_feature->feature_relationship_id} ) {
            
            #print "\tif\n\t\t" . $rs_feature->get_column('interaction_type') . "\t" . $rs_feature->feature_relationship_id . "\n";
            #print $interactions{ $rs_feature->get_column('interaction_type') }{ $rs_feature->feature_relationship_id }{'pub_db'} . "\n";
            %partner = %{ $interactions{ $rs_feature->get_column('interaction_type') }{ $rs_feature->feature_relationship_id } };
            $partner{$rs_feature->get_column('prop_type')} = $rs_feature->get_column('prop_value');
            $interactions{$rs_feature->get_column('interaction_type')}{$rs_feature->feature_relationship_id} = \%partner;
        } else {
#            print $rs_feature->get_column('sub_id') . "\t";
#            print $rs_feature->get_column('sub_uniquename') . "\t";
#            print $rs_feature->get_column('sub_name') . "\t";
#            print $rs_feature->get_column('ob_id') . "\t";
#            print $rs_feature->get_column('ob_uniquename') . "\t";
#            print $rs_feature->get_column('ob_name') . "\t"; 
            if ( $rs_feature->get_column('sub_id') == $self->feature_id ) {
#                print "Object\n";
                $partner{'feature_id'} = $rs_feature->get_column('ob_id');
                $partner{'stable_id'} = $rs_feature->get_column('ob_uniquename');
                $partner{'name'} = $rs_feature->get_column('ob_name');
                $partner{'directionality'} = 'InteractorB';
            } else {
#                print "Subject\n";
                $partner{'feature_id'} = $rs_feature->get_column('sub_id');
                $partner{'stable_id'} = $rs_feature->get_column('sub_uniquename');
                $partner{'name'} = $rs_feature->get_column('sub_name');
                $partner{'directionality'} = 'InteractorA'; 
            }
            
            $partner{$rs_feature->get_column('prop_type')} = $rs_feature->get_column('prop_value');
            
            $partner{'frid'} = $rs_feature->feature_relationship_id;
            
            my @pub_full = split(/:/, $rs_feature->get_column('pmid'));
            $partner{'pub_db'}  = 'PUBMED';
            $partner{'pub_ref'} = $pub_full[1];
            
            $interactions{$rs_feature->get_column('interaction_type')}{$rs_feature->feature_relationship_id} = \%partner;
        }
    }
    
#    try {
#        my $d = Data::Dumper->new([%interactions]);
#        print $d->Dump();
#    } catch {
#        print @_;
#    };
    
    # 
    # Creation of the xref objects for both the feature and the publication.
    # The two xrefs are grouped in pairs so that the correct dependent xref
    # insertion statements can be generated.   These insertions need to be 
    # performed during the upload of the other xref objects. 
    # 
    
    foreach my $interaction_type (keys %interactions) {
        my $external_db = 'PomBase_Interaction_';
        my $term_acc = '';
        if ( $interaction_type eq 'interacts_genetically' ) {
            $external_db .= 'GENETIC';
            $term_acc = 'PBO:0000037';
        } else {
            $term_acc = 'PBO:0000038';
            $external_db .= 'PHYSICAL';
        }
        foreach my $interaction_id (keys %{ $interactions{$interaction_type} }) {
            my %partner = %{ $interactions{$interaction_type}{$interaction_id} };
            
            #print $interaction_id . "\t" . $partner{'stable_id'} . "\t" . $partner{'name'} . "\n";
            #print $interaction_id . "\t" . $partner{'pub_db'} . ':' . $partner{'pub_ref'} . "\n";
            
            if ( exists $partner{'is_inferred'} ) {
              if ( $partner{'is_inferred'} eq 'yes' or $partner{'is_inferred'} eq 'Yes' ) {
                next;
              }
            }
            
            #
            # Create the Interaction Xref object
            # Composite key is required as the interaction is bi-directional,
            # but Xrefs are unidirectional.   As a result a non-composite key
            # results in the second partner not being recorded in all cases.
            #
            my $evidence_code = $partner{'evidence'};
            if ( $evidence_code eq 'Co-crystal Structure' ) {
            	$evidence_code = 'Co-crystal or NMR structure';
            }
            
            my $evid_accession = $biodef->interaction_evid->{$evidence_code};
            #print $evidence_code . ' | ' .  $evid_accession . "\n";
            my $evidence_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $evid_accession,
                -DBNAME      => 'PBO',
                #-VERSION     => 1,
                -DISPLAY_ID  => $evid_accession,
                -DESCRIPTION => $evidence_code,
                -INFO_TYPE   => 'DIRECT',
            );
            
            my $term_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                -PRIMARY_ID         => $term_acc,
                -DBNAME             => 'PBO',
                #-VERSION            => 1,
                -DISPLAY_ID         => $term_acc,
                -DESCRIPTION        => $interaction_type,
                -INFO_TYPE          => 'INFERRED_PAIR',
                -INFO_TEXT          => $partner{'source_database'},
            );
            
            #
            # Create the Gene Xref Object
            #
            my $gene_dbentry = Bio::EnsEMBL::DBEntry -> new (
                #-PRIMARY_ID  => $partner{'pub_db'} . ':' . $partner{'pub_ref'},
                -PRIMARY_ID  => $partner{'stable_id'},
                -DBNAME      => 'PomBase_Gene_Name',
                #-VERSION     => 1,
                -DISPLAY_ID  => $partner{'name'},
                -DESCRIPTION => q{},
                -INFO_TYPE   => 'DIRECT',
            );
            
            #
            # Create the PubMed Xref Object
            #
            my $pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                #-PRIMARY_ID  => $partner{'pub_db'} . ':' . $partner{'pub_ref'},
                -PRIMARY_ID  => $partner{'pub_ref'},
                -DBNAME      => $partner{'pub_db'},
                #-VERSION     => 1,
                -DISPLAY_ID  => $partner{'pub_ref'},
                -DESCRIPTION => q{},
                -INFO_TYPE   => 'DIRECT',
            );
            
            $term_dbentry->add_linkage_type( 'EXP', $pub_dbentry );
            
            $term_dbentry->add_linked_associated_xref(
                          $gene_dbentry,
                          $pub_dbentry,
                          $partner{'directionality'},
                          $partner{'frid'},
                          0);
            
            $term_dbentry->add_linked_associated_xref(
                          $evidence_dbentry,
                          $pub_dbentry,
                          'evidence',
                          $partner{'frid'},
                          1);
            
            #
            # Save the ensembl objects;
            #
            $interactions{$interaction_type}{$interaction_id}{'ensembl'} = {'term' => $term_dbentry, 'pub' => $pub_dbentry};
        }
    }
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};
    return \%interactions;
}


#
# Load the interactions in relation to the gene rather than the transcript.
# This might change in the future, but Kim will give a heads up if it does.
#
sub upload {
    my ($self, $gene_id) = @_;
    my %interactions = %{ $self->get_interactions() };
    
    #print "I'm in, there are " . scalar %interactions . " interactions\n";
    #print Dumper \%interactions;
    
    foreach my $interaction_type (keys %interactions) {
        #print "I'm in, there are " . $interaction_type . " interactions\n";
        my $external_db = 'PomBase_Interaction_';
        if ( $interaction_type eq 'interacts_genetically' ) {
            $external_db .= 'GENETIC';
        } else {
            $external_db .= 'PHYSICAL';
        }
        
        foreach my $interaction_id (keys %{ $interactions{$interaction_type} }) {
            my %partner = %{ $interactions{$interaction_type}{$interaction_id} };
            #print Dumper \%partner;

            if ( !exists $partner{'ensembl'} ) {
              next;
            }

            my %partner_ensembl = %{ $partner{'ensembl'} };
            
            #print $partner_ensembl{'term'}->primary_id . "\t" . $partner_ensembl{'term'}->display_id . "\n";
            
            my $xref_term_id = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $partner_ensembl{'term'},
                $gene_id,
                'Gene'
            );
            my $xref_pub_id = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $partner_ensembl{'pub'},
                $gene_id,
                'Gene'
            );
            
            #print "\t" . $xref_term_id . "\t";
            
# NOT REQUIRED
# Moved the interavtions onto the associated_xrefs table rather than
# the dependent_xref table. This should make querying the interactions
# easier as they can be handled in the same way as other ontology terms
# 
#            my $ensembl_id = $partner_ensembl{'term'}->ensembl_id;
#            my $ensembl_type = $partner_ensembl{'term'}->ensembl_object_type;
#            
#            my $dbc = $self->dba_ensembl->dbc();
#            my $sql_1 = 'SELECT object_xref_id FROM object_xref WHERE ensembl_id = ? AND ensembl_object_type = ? AND xref_id = ?;';
#            #print 'SELECT object_xref_id FROM object_xref WHERE ensembl_id = ' . $gene_id . ' AND ensembl_object_type = "Gene" AND xref_id = ' . $xref_term_id . ';' . "\n";
#            my $sth_1 = $dbc->prepare($sql_1);
#            $sth_1->bind_param(1, $gene_id);
#            $sth_1->bind_param(2, 'Gene');
#            $sth_1->bind_param(3, $xref_term_id);
#            $sth_1->execute();
#            
#            my @object_xref_id = @{ $sth_1->fetchall_arrayref() };
#            
#            my $sql_2 = 'INSERT IGNORE INTO dependent_xref (object_xref_id, master_xref_id, dependent_xref_id) VALUES (?, ?, ?);';
#            #print 'INSERT INTO dependent_xref (object_xref_id, master_xref_id, dependent_xref_id) VALUES (' . $object_xref_id[0][0] . ', ' . $xref_term_id . ', ' . $xref_pub_id . ');' . "\n";
#            my $sth_2 = $dbc->prepare($sql_2);
#            $sth_2->bind_param(1, $object_xref_id[0][0]);
#            $sth_2->bind_param(2, $xref_term_id);
#            $sth_2->bind_param(3, $xref_pub_id);
#            $sth_2->execute();
            
            #
            # Query to identify the inserted DBEntry and check what was loaded.
            #
#            my $sql_3 = 'SELECT dbprimary_acc, display_label FROM xref WHERE xref_id = ?;';
#            my $sth_3 = $dbc->prepare($sql_3);
#            $sth_3->bind_param(1, $xref_term_id);
#            $sth_3->execute();
#            my @xref = @{ $sth_3->fetchall_arrayref() };
#            
#            print $xref[0][0] . "\t" . $xref[0][1] . "\t";
#            
#            print $object_xref_id[0][0] . "\n";
        }
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
