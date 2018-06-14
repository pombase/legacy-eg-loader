package PomLoader::Translation;

use Moose;

use Bio::EnsEMBL::Translation;
use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;

use PomLoader::GOTerms;
use PomLoader::ProteinFeatures;
use PomLoader::MergeHashArray;
use PomLoader::FeatureSynonyms;

has 'dba_ensembl'   => ( isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1 );
has 'dba_chado'     => ( isa => 'Bio::Chado::Schema', is => 'ro', required => 1 );
has 'transcript_id' => ( isa => 'Int', is => 'ro', required => 1 );
has 'dbparams'      => ( isa => 'HashRef', is => 'ro', required => 1 );

has 'slice'         => ( isa => 'Bio::EnsEMBL::Slice', is => 'ro', required => 0 );
has 'translation'   => ( isa => 'Bio::EnsEMBL::Translation', is => 'ro', required => 0 );
has 'startexon'     => ( isa => 'Bio::EnsEMBL::Exon', is => 'ro', required => 0 );
has 'endexon'       => ( isa => 'Bio::EnsEMBL::Exon', is => 'ro', required => 0 );
has 'utr5'          => ( isa => 'Int', is => 'ro', required => 0, lazy => 1, default => -1 );
has 'utr3'          => ( isa => 'Int', is => 'ro', required => 0, lazy => 1, default => -1 );

has '_translations' => ( isa => 'HashRef[HashRef]', is => 'ro', lazy => 1, builder => '_generate_translations' );

has 'update' => ( isa => 'Int', is => 'ro', lazy => 1, builder => '_update_translation' );


sub get_translations {
    my $self = shift;
    my $translationshash = $self->_translations();
    return $translationshash->{translations};
}


sub get_interpromapping {
    my $self = shift;
    my $translationshash = $self->_translations();
    return $translationshash->{iprmapping};
}


sub get_descriptions {
    my $self = shift;
    my $translationshash = $self->_translations();
    return $translationshash->{descriptions};
}


sub number_of_translations {
    my $self = shift;
    return scalar keys %{ $self->get_translations };
}


sub _generate_translations {
    my $self = shift;
    my %translations = ();
    my %interpromapping = ();
    my %translationdesc = ();
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};
    
    my $test_slice = 1;
    my $test_exon_start = 1;
    my $test_exon_end = 1;
    if (!defined $self->slice) {
        $test_slice = 0;
    }
    if (!defined $self->startexon) {
        $test_exon_start = 0;
    }
    if (!defined $self->endexon) {
        $test_exon_end = 0;
    }
    
    if ($test_slice == 0 or $test_exon_start == 0 or $test_exon_end == 0) {
        my $msg = '';
        if ( $test_slice == 0 ) {
            $msg .= "Bio::EnsEMBL::Slice is not set.\n";
        }
        if ( $test_exon_start == 0 ) {
            $msg .= "Bio::EnsEMBL::Exon (start) is not set.\n";
        }
        if ( $test_exon_end == 0 ) {
            $msg .= "Bio::EnsEMBL::Exon (End) is not set.\n";
        }
        return {"ERROR" => $msg };
    }


    #
    # Get all the products of the transcript.
    #
    my $feature_translation = PomLoader::FeatureLocation->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $self->transcript_id,
                              'type_id'    => 'derives_from',
                              'dbparams'   => $self->dbparams);
    my @featureloc_translations = @{$feature_translation->subfeaturelocation()};

    foreach my $translation ( @featureloc_translations ) {
        my %goterms = ();

        $translationdesc{$translation->{'feature_id'}} = $translation->{'description'};

        my $translation_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $translation->{'uniquename'},
            -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSLATION',
            #-RELEASE     => 1,
            #-VERSION     => 1,
            -DISPLAY_ID  => $translation->{'uniquename'},
            -DESCRIPTION => $translation->{'description'},
            -INFO_TYPE   => 'DIRECT',
        );
        my $feature_synonyms = PomLoader::FeatureSynonyms->new(
                                  'dba_chado'   => $self->dba_chado,
                                  'feature_id'  => $translation->{'feature_id'},);
        my $synonyms = $feature_synonyms->get_synonyms();
        foreach my $synonym (@{$synonyms}) {
            $translation_dbentry->add_synonym($synonym);
        }

        my $seq_start = 0;
        my $seq_end   = 0;
        
#        print $translation->{'uniquename'} . "\t";
#        print $self->startexon->start . "\t" . $self->endexon->end . "\t";
#        print $self->utr5 . "\t" . $self->utr3 . "\t";
#        print $translation->{'start'} . "\t" . $translation->{'end'} . "\t";
#        print $translation->{'strand'} . "\n";
        
        if ($translation->{'strand'} == 1) {
            $seq_start = $self->utr5 + 1;
            $seq_end   = $self->endexon->end - $self->endexon->start - $self->utr3 + 1;
        } else {
            $seq_start = $self->utr3 + 1;
            $seq_end   = $self->endexon->end - $self->endexon->start - $self->utr5 + 1;
        }
        
        my $translation_ensembl = Bio::EnsEMBL::Translation->new(
            -START_EXON    => $self->startexon,
            -END_EXON      => $self->endexon,
            -SEQ_START     => $seq_start,
            -SEQ_END       => $seq_end,
            -STABLE_ID     => $translation->{'uniquename'},
            #-VERSION       => 1,
            -CREATED_DATE  => $translation->{'created'},
            -MODIFIED_DATE => $translation->{'modified'},
        );

        $translation_ensembl->add_DBEntry($translation_dbentry);


        #
        # Get all the Xrefs of the translation.
        #
#        my $xrefs = PomLoader::FeatureXrefs->new(
#                         'dba_chado'  => $self->dba_chado,
#                         'feature_id' => $translation->{'feature_id'},
#                         'dbparams'    => $self->dbparams,
#                     );
#        my $xrefs_dbentries = $xrefs->featurexrefs();
#        foreach my $xref_dbentry (keys %{$xrefs_dbentries}) {
#            $translation_ensembl->add_DBEntry($xrefs_dbentries->{$xref_dbentry});
#        }
        
        
        #
        # Get all publications linked to a given feature_id
        #
#        my $pubs = PomLoader::FeaturePublications->new(
#                       'dba_chado'  => $self->dba_chado,
#                       'feature_id' => $translation->{'feature_id'},
#                   );
#        my $translation_pub_dbentries = $pubs->get_publications();
#        foreach my $pub_dbentry (keys %{$translation_pub_dbentries}) {
#            $translation_ensembl->add_DBEntry($translation_pub_dbentries->{$pub_dbentry});
#        }


        #
        # Get all the GO terms of the translation.
        #
#        my $goterms = PomLoader::GOTerms->new(
#                         'dba_chado'  => $self->dba_chado,
#                         'feature_id' => $translation->{'feature_id'},
#                         'dbparams'    => $self->dbparams,
#                     );
#        my $goterm_dbentries = $goterms->goterms();
#        foreach my $goterm_dbentry (keys %{$goterm_dbentries}) {
#            $translation_ensembl->add_DBEntry($goterm_dbentries->{$goterm_dbentry});
#        }
        
        
        #
        # Get all the Ontology terms of the translation.
        #
#        my $ontologyterms = PomLoader::OntologyTerms->new(
#                         'dba_chado'  => $self->dba_chado,
#                         'feature_id' => $translation->{'feature_id'},
#                         'dbparams'    => $self->dbparams,
#                     );
#        my $ontology_dbentries = $ontologyterms->ontologyterms();
#        foreach my $ontologyterm_dbentry (keys %{$ontology_dbentries}) {
#            $translation_ensembl->add_DBEntry($ontology_dbentries->{$ontologyterm_dbentry});
#        }


        #
        # Populate all information about the protein
        #
        if ($self->dbparams->{'includeproteinfeatures'} eq 1) {
            my $proteinfeatures = PomLoader::ProteinFeatures->new(
                             'dba_ensembl'  => $self->dba_ensembl,
                             'dba_chado'  => $self->dba_chado,
                             'srcfeature_id' => $translation->{'feature_id'},,
                             'dbparams'   => $self->dbparams,
                         );
            my $proteinfeatures_dbentries = $proteinfeatures->get_proteinfeatures();
            foreach my $protfeatkeys (keys %{$proteinfeatures_dbentries}) {
                $translation_ensembl->add_ProteinFeature($proteinfeatures_dbentries->{$protfeatkeys});
                my $iprmerger = PomLoader::MergeHashArray->new(
                                 'hash1' => \%interpromapping,
                                 'hash2' => $proteinfeatures->get_interpromapping());
                %interpromapping = %{ $iprmerger->get_new_hash() };
            }
        }

        $translations{$translation->{'feature_id'}} = $translation_ensembl;
    }

    return {translations => \%translations,
            iprmapping   => \%interpromapping,
            descriptions => \%translationdesc,
    };
}

#sub _generate_utr {
#    my ( $self, $transcript_id ) = @_;
#    
#    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
#    my $biodef = $self->dbparams->{'biodef'};
#    
#    my %utrs = ();
#    my $rs_utrs =
#        $self->dba_chado->resultset('Sequence::FeatureRelationship')
#              ->search(
#                       {object_id => $self->transcript_id},
#                       {join => ['type'],
#                        'where' => {'type.name' => 'part_of'},
#                       }
#              )
#              ->search_related('subject',
#                       {},
#                       {join => ['featureloc_features',
#                                 'type'],
#                        '+select' => [
#                           'type_2.name',
#                           {extract => 'EPOCH FROM subject.timeaccessioned'},
#                           {extract => 'EPOCH FROM subject.timelastmodified'},
#                           'featureloc_features.fmin',
#                           'featureloc_features.fmax',
#                           'featureloc_features.strand',
#                           'featureloc_features.phase'],
#                        '+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase'],
#                        'where' => {'type_2.name' => [$biodef->chado_type()->{'five_prime_UTR'},
#                                                    $biodef->chado_type()->{'three_prime_UTR'}]}
#                       });
#
#    while ( my $rs_utr = $rs_utrs->next ) {
#        
#    }
#}

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


sub _update_translation {
    my $self = shift;
    my $test_translation = 1;
    
    if (!defined $self->translation) {
        $test_translation = 0;
    }
    
    if ($test_translation == 0) {
        my $msg .= "Bio::EnsEMBL::Translation is not set.\n";
        # return {"ERROR" => $msg };
        return 0;
    }
    
    # Get translation feautre_id for a given transcript feature_id
    my $rs_translation = $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                       {object_id => $self->transcript_id},
                       {
                           join => ['type'],
                           'where' => {'type.name' => 'derives_from'},
                       }
              )
              ->search_related('subject',
                       {},
                       {
                           join => ['type'],
                           '+select' => ['subject.feature_id'],
                           '+as'     => ['protein_feature_id'],
                           'where'   => {'type_2.name' => 'polypeptide'}
                       }
    );
    my $rs_feature = $rs_translation->next;
    
    
    
    #
    # Create Hash of all Xrefs
    #
    my $feature_xrefs = PomLoader::FeatureXrefs->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $rs_feature->get_column('protein_feature_id'),
                              'dbparams'   => $self->dbparams,);
    my $xrefs = $feature_xrefs->featurexrefs();
    
    
    #
    # Get all publications linked to a given feature_id
    #
    my $pubs = PomLoader::FeaturePublications->new(
                   'dba_chado'  => $self->dba_chado,
                   'feature_id' => $rs_feature->get_column('protein_feature_id'),
               );
    my $pub_dbentries = $pubs->get_publications();
        
    
    #
    # Get all the GO terms of the transcript.
    #
    my $goterms = PomLoader::GOTerms->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $rs_feature->get_column('protein_feature_id'),
                     'dbparams'   => $self->dbparams,);
    my $goterm_dbentries = $goterms->goterms();
    
    
    #
    # Get all the Ontology terms of the translation.
    #
    my $ontologyterms = PomLoader::OntologyTerms->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $rs_feature->get_column('protein_feature_id'),
                     'dbparams'   => $self->dbparams,
                 );
    my $ontology_dbentries = $ontologyterms->ontologyterms();
    
    
    #
    # Store all of the DBEntries
    #
    foreach my $xref_dbentry (values %{ $xrefs }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $xref_dbentry,
                $self->translation->dbID,
                'Translation'
        );
    }
    foreach my $pub_dbentry (values %{ $pub_dbentries }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $pub_dbentry,
                $self->translation->dbID,
                'Translation'
        );
    }
    
    #
    # Reload all ontology terms
    #
    foreach my $goterm_dbentry (values %{ $goterm_dbentries }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $goterm_dbentry,
                $self->translation->transcript->dbID,
                'Transcript'
        );
    }
    foreach my $ontologyterm_dbentry (values %{ $ontology_dbentries }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $ontologyterm_dbentry,
                $self->translation->transcript->dbID,
                'Transcript'
        );
    }
    
    $self->dba_ensembl->get_TranslationAdaptor->update($self->translation);
    
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::Translation - Builds translation objects based on a 
                         transcript feature ID.  Will also decorate
                         the translation with DBEntries for the 
                         translation, GO terms and publications
                         related to the GO term.

=head1 DESCRIPTION

Module to build Bio::EnsEMBL::Translation objects.   It also populates the 
objects with GO terms and their related publications.


=head1 METHODS

=head2 new

 [dba_ensembl]:
     Bio::EnsEMBL::DBSQL::DBAdaptor
 [dba_chado]:
     Bio::Chado::Schema
 [transcript_id]:
     String - Transcript feature_id from the Chado database.
 [slice]:
     Bio::EnsEMBL::Slice
 [startexon]:
     Bio::EnsEMBL::Exon: Transcript start exon
 [endexon]:
     Bio::EnsEMBL::Exon: Transcript end exon
 [dbparams]:
     HashRef: Details required for querying the Chado database and 
     loading of the new EnsEMBL database.

=head2 get_translations

 Getter of a HashRef of all translations associated to the transcript.
 There should only be a single translation for a transcript, but this 
 method will bring back all translations and it is up to the requester
 to determine the fate of multiple translations

=head2 get_interpromapping

 Getter of a HashRef for all the InterPro to Domain References.

=head2 get_descriptions

 Getter for the translation descriptions.   Returns an HashRef.

=head2 number_of_translations

 Returns the number of translations for a given transcript.


=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

=item
EnsEMBL API Release v61+

=back

=head1 EXAMPLE

my $translations = PomLoader::Translation->new(
                       'dba_ensembl'   => $dba_ensembl,
                       'dba_chado'     => $dba_chado,
                       'transcript_id' => $feature_id,
                       'slice'         => $slice,
                       'startexon'     => $transcript->start_Exon,
                       'endexon'       => $transcript->end_Exon
                   );

my %translationlist = %{$translations->translations()};

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut