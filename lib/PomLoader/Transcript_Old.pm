package PomLoader::Transcript;

use feature ':5.10';
use Moose;
use PomLoader::Translation;
use PomLoader::Exon;
use PomLoader::BioDefinitions;
use PomLoader::FeatureSynonyms;
use PomLoader::FeatureLocation;
use PomLoader::FeatureXrefs;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::DBEntry;
use Try::Tiny;

has 'dba_ensembl'   => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'     => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'gene_id'       => (isa => 'Int', is => 'ro', required => 1);
has 'slice'         => (isa => 'Bio::EnsEMBL::Slice', is => 'ro', required => 1);
has 'analysis'      => (isa => 'Bio::EnsEMBL::Analysis', is => 'ro', required => 1);
has 'dbparams'      => (isa => 'HashRef', is => 'ro', required => 1);
has 'current'       => (isa => 'Int', is => 'ro', required => 1);

has 'transcriptions'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_transcript');


sub _generate_transcript {
    my $self = shift;
    my %transcripts = ();
    my $biodef = PomLoader::BioDefinitions->new();

    #
    # Get all the products of the gene.
    #
    my $feature_transcript = PomLoader::FeatureLocation->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $self->gene_id);
    my @featureloc_transcript = @{$feature_transcript->subfeaturelocation()};

    foreach my $transcript_feature (@featureloc_transcript) {

        #
        # Test if the transcript is a valid transcript xxxRNA
        #
        if (($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'mRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'tRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'rRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'snRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'snoRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'ncRNA'})
                && ($transcript_feature->{'type_id'} ne $biodef->biotype_id->{'psuedogenic_transcript'})) {
            print "Skipped Transcript\n" or next;
            print "\tBiotype: ", $transcript_feature->{'type_id'}, "\n" or next;
            next;
        }


        my %transcript = ();
        my $biotype = q{};


        #
        # Build DBEntry object
        #
        my $dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $transcript_feature->{'uniquename'},
            -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
            #-RELEASE     => 1,
            -VERSION     => 1,
            -DISPLAY_ID  => $transcript_feature->{'name'},
            -DESCRIPTION => $transcript_feature->{'uniquename'},
            -INFO_TYPE   => 'DIRECT',
        );
        my $feature_synonyms = PomLoader::FeatureSynonyms->new(
                                  'dba_chado'  => $self->dba_chado,
                                  'feature_id' => $transcript_feature->{'feature_id'});
        my $synonyms = $feature_synonyms->get_synonyms();
        foreach my $synonym (@{$synonyms}) {
            $dbentry->add_synonym($synonym);
        }
        
        #
        # Create Hash of all Xrefs
        #
        my $feature_xrefs = PomLoader::FeatureXrefs->new(
                                  'dba_chado'   => $self->dba_chado,
                                  'feature_id'  => $transcript_feature->{'feature_id'},);
        my $xrefs = $feature_xrefs->featurexrefs();


        #
        # Build Transcript Object
        #
        my $transcript_ensembl = Bio::EnsEMBL::Transcript -> new(
            -SLICE           => $self->slice,
            -START           => $transcript_feature->{'start'},
            -END             => $transcript_feature->{'end'},
            -STABLE_ID       => $transcript_feature->{'uniquename'},  # e.g. SPAC13G6.05c.1
            -VERSION         => 1,
            -EXTERNAL_NAME   => $transcript_feature->{'uniquename'},  # e.g. SPAC13G6.05c.1
            -EXTERNAL_DB     => $self->dbparams->{'dbname'}.'_Transcript',
            -CREATED_DATE    => $transcript_feature->{'created'},
            -MODIFIED_DATE   => $transcript_feature->{'modified'},
            #-BIOTYPE         => $biodef->biotype()->{$transcript_feature->{'type_id'}},
            -STATUS          => 'KNOWN',
            # Current comes from the Chado db where it is a representation of if
            # the feature is obsolete, hence it is current if == 0.  This can 
            # lead to the healthchecks getting cranky.
            -IS_CURRENT      => $self->current==0,
            -ANALYSIS        => $self->analysis
        );
        if ( $transcript_ensembl->is_current() eq q{} ) {
            $transcript_ensembl->is_current(0)
        }


        #
        # Get all exons associated with the transcript
        #
        my $exons = PomLoader::Exon->new(
                        'dba_ensembl'   => $self->dba_ensembl,
                        'dba_chado'     => $self->dba_chado,
                        'transcript_id' => $transcript_feature->{'feature_id'},
                        'slice'         => $self->slice,
                        'current'       => $self->current,);

        my @exonlist = @{$exons->exons()};
        
        my %warningmessage = ();
        
#        my $exon_overlap = $exons->overlaps();
#        if ( $exon_overlap ) {
#            my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
#            $warningmessage{'ERROR'} = $message;
#            return \%warningmessage;
#        }

        foreach my $exon (@exonlist) {
            try {
               $transcript_ensembl->add_Exon($exon);
            } catch {
                #my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n\t$_\n\t";
                my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
                $warningmessage{'ERROR'} = $message;
                last;
            };
        }
        if ( exists $warningmessage{'ERROR'} ) {
            return \%warningmessage;
        }


        #
        # Create translation objects for the transcript
        #
        my $translations = PomLoader::Translation->new(
                               'dba_ensembl'   => $self->dba_ensembl,
                               'dba_chado'     => $self->dba_chado,
                               'transcript_id' => $transcript_feature->{'feature_id'},
                               'slice'         => $self->slice,
                               'startexon'     => $transcript_ensembl->start_Exon,
                               'endexon'       => $transcript_ensembl->end_Exon,
                               'dbparams'      => $self->dbparams,
                               );

        my %translationlist = %{$translations->get_translations()};


        #
        # Handle the biotype of the transcript.
        #
        if ($transcript_feature->{'type_id'} eq $biodef->biotype_id->{'psuedogenic_transcript'} ) {
            $biotype = 'pseudogene';
            if (scalar keys %translationlist > 0) {
                %translationlist = ();
            }
        } else {
            $biotype = $biodef->biotype()->{$transcript_feature->{'type_id'}};
        }
        $transcript_ensembl->biotype($biotype);


        #
        # Get the description of the transcript.
        #
        $transcript_ensembl->description($transcript_feature->{'description'});


        #
        # Check how many translations there are per transcript.
        #
        if ($translations->number_of_translations==0 or $biotype eq 'pseudogene') {
            #print "No Translation\n" or confess;
        } elsif ($translations->number_of_translations>1) {
            my $message = "Too many translations per transcripts (Feature_ID: $transcript_feature->{'feature_id'}) (Gene Skipped)\n\t";
            $warningmessage{'ERROR'} = $message;
        } else {
            my @translation_keys = keys %translationlist;
            $transcript_ensembl->translation($translationlist{$translation_keys[0]});
        }
        if (exists $warningmessage{'ERROR'} ) {
            return \%warningmessage;
        }


        #
        # Bundle up the transcript objects and load into the container.
        #
        $transcript{'ensembl'}          = $transcript_ensembl;
        $transcript{'transcript_xref'}  = $dbentry;
        $transcript{'feature_xrefs'}    = $xrefs;
        $transcript{'translation'}      = $translations;

        $transcripts{$transcript_feature->{'feature_id'}} = \%transcript;
    }
    return \%transcripts;
}


sub _build_transcript {
    my ( $self, $transcript_feature) = @_;
    my %transcript = ();
    my $biotype = q{};
    my $biodef = PomLoader::BioDefinitions->new();


    #
    # Build DBEntry object
    #
    my $dbentry = Bio::EnsEMBL::DBEntry -> new (
        -PRIMARY_ID  => $transcript_feature->{'uniquename'},
        -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
        #-RELEASE     => 1,
        -VERSION     => 1,
        -DISPLAY_ID  => $transcript_feature->{'name'},
        -DESCRIPTION => $transcript_feature->{'uniquename'},
        -INFO_TYPE   => 'DIRECT',
    );
    my $feature_synonyms = PomLoader::FeatureSynonyms->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $transcript_feature->{'feature_id'});
    my $synonyms = $feature_synonyms->get_synonyms();
    foreach my $synonym (@{$synonyms}) {
        $dbentry->add_synonym($synonym);
    }
    
    #
    # Create Hash of all Xrefs
    #
    my $feature_xrefs = PomLoader::FeatureXrefs->new(
                              'dba_chado'   => $self->dba_chado,
                              'feature_id'  => $transcript_feature->{'feature_id'},);
    my $xrefs = $feature_xrefs->featurexrefs();


    #
    # Build Transcript Object
    #
    my $transcript_ensembl = Bio::EnsEMBL::Transcript -> new(
        -SLICE           => $self->slice,
        -START           => $transcript_feature->{'start'},
        -END             => $transcript_feature->{'end'},
        -STABLE_ID       => $transcript_feature->{'uniquename'},  # e.g. SPAC13G6.05c.1
        -VERSION         => 1,
        -EXTERNAL_NAME   => $transcript_feature->{'uniquename'},  # e.g. SPAC13G6.05c.1
        -EXTERNAL_DB     => $self->dbparams->{'dbname'}.'_Transcript',
        -CREATED_DATE    => $transcript_feature->{'created'},
        -MODIFIED_DATE   => $transcript_feature->{'modified'},
        #-BIOTYPE         => $biodef->biotype()->{$transcript_feature->{'type_id'}},
        -STATUS          => 'KNOWN',
        # Current comes from the Chado db where it is a representation of if
        # the feature is obsolete, hence it is current if == 0.  This can 
        # lead to the healthchecks getting cranky.
        -IS_CURRENT      => $self->current==0,
        -ANALYSIS        => $self->analysis
    );
    if ( $transcript_ensembl->is_current() eq q{} ) {
        $transcript_ensembl->is_current(0)
    }


    #
    # Get all exons associated with the transcript
    #
    my $exons = PomLoader::Exon->new(
                    'dba_ensembl'   => $self->dba_ensembl,
                    'dba_chado'     => $self->dba_chado,
                    'transcript_id' => $transcript_feature->{'feature_id'},
                    'slice'         => $self->slice,
                    'current'       => $self->current,);

    my @exonlist = @{$exons->exons()};
    
    my %warningmessage = ();
        
#        my $exon_overlap = $exons->overlaps();
#        if ( $exon_overlap ) {
#            my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
#            $warningmessage{'ERROR'} = $message;
#            return \%warningmessage;
#        }

    foreach my $exon (@exonlist) {
        try {
           $transcript_ensembl->add_Exon($exon);
        } catch {
            #my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n\t$_\n\t";
            my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
            $warningmessage{'ERROR'} = $message;
            last;
        };
    }
    if ( exists $warningmessage{'ERROR'} ) {
        return \%warningmessage;
    }


    #
    # Create translation objects for the transcript
    #
    my $translations = PomLoader::Translation->new(
                           'dba_ensembl'   => $self->dba_ensembl,
                           'dba_chado'     => $self->dba_chado,
                           'transcript_id' => $transcript_feature->{'feature_id'},
                           'slice'         => $self->slice,
                           'startexon'     => $transcript_ensembl->start_Exon,
                           'endexon'       => $transcript_ensembl->end_Exon,
                           'dbparams'      => $self->dbparams,
                           );

    my %translationlist = %{$translations->get_translations()};


    #
    # Handle the biotype of the transcript.
    #
    if ($transcript_feature->{'type_id'} eq $biodef->biotype_id->{'psuedogenic_transcript'} ) {
        $biotype = 'pseudogene';
        if (scalar keys %translationlist > 0) {
            %translationlist = ();
        }
    } else {
        $biotype = $biodef->biotype()->{$transcript_feature->{'type_id'}};
    }
    $transcript_ensembl->biotype($biotype);


    #
    # Get the description of the transcript.
    #
    $transcript_ensembl->description($transcript_feature->{'description'});


    #
    # Check how many translations there are per transcript.
    #
    if ($translations->number_of_translations==0 or $biotype eq 'pseudogene') {
        #print "No Translation\n" or confess;
    } elsif ($translations->number_of_translations>1) {
        my $message = "Too many translations per transcripts (Feature_ID: $transcript_feature->{'feature_id'}) (Gene Skipped)\n\t";
        $warningmessage{'ERROR'} = $message;
    } else {
        my @translation_keys = keys %translationlist;
        $transcript_ensembl->translation($translationlist{$translation_keys[0]});
    }
    if (exists $warningmessage{'ERROR'} ) {
        return \%warningmessage;
    }


    #
    # Bundle up the transcript objects and load into the container.
    #
    $transcript{'ensembl'}          = $transcript_ensembl;
    $transcript{'transcript_xref'}  = $dbentry;
    $transcript{'feature_xrefs'}    = $xrefs;
    $transcript{'translation'}      = $translations;
    
    return \%transcript;
}


sub number_of_transcripts {
    my $self = shift;
    return scalar keys %{ $self->transcriptions() };
}


sub get_translation_description {
    my $self = shift;
    my $transcriptions = $self->transcriptions();
    my @descriptions = ();
    foreach my $transcription_key (keys %{$transcriptions}) {
        my $translations = $transcriptions->{$transcription_key}->{'translation'}->get_descriptions();
        foreach my $translation_key (keys %{ $translations }) {
            push @descriptions,  $translations->{$translation_key};
        }
    }
    return \@descriptions;
}


sub load_xrefs {
    my $self = shift;
    my $transcriptions = $self->transcriptions();
    for my $transcript_id (keys %{$transcriptions}) {
        my $transcript = $transcriptions->{$transcript_id};
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $transcript->{'transcript_xref'},
                $transcript->{'ensembl'}->dbID,
                'Transcript'
        );
        $transcript->{'ensembl'}->display_xref($transcript->{'transcript_xref'});
        
        foreach my $xref_dbentry (values %{ $transcriptions->{'feature_xrefs'} }) {
            $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $xref_dbentry,
                    $transcript->{'ensembl'}->dbID,
                    'Transcript'
            );
        }
        
        $self->dba_ensembl->get_TranscriptAdaptor->update($transcript->{'ensembl'});

        my $iprmappings = $transcript->{'translation'}->get_interpromapping();
        my $dbc = $self->dba_ensembl->dbc();
        my $check = $dbc->prepare('SELECT COUNT(interpro_ac) AS present FROM interpro WHERE interpro_ac = ? AND id = ?;');
        my $load  = $dbc->prepare('INSERT INTO interpro VALUES (?, ?);');
        foreach my $iprkey ( keys %{ $iprmappings } ) {
            $check->bind_param(1, $iprkey);
            $load->bind_param(1, $iprkey);
            foreach my $acc ( @{ $iprmappings->{$iprkey} } ) {
                $check->bind_param(2, $acc);
                $check->execute();
                my @row = $check->fetchrow_array();
                if ($row[0] == 0) {
                    $load->bind_param(2, $acc);
                    $load->execute or confess;
                }
            }
        }
    }
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::Transcript - Handles the extraction of gene transcripts
                        and the collection of translation and exon
                        information.

=head1 DESCRIPTION

Handles the construction and annotation of the transcript.   Will also retrieve
all exon and translations.


=head1 METHODS

=head2 new

 [dba_ensembl]:
     Bio::EnsEMBL::DBSQL::DBAdaptor
 [dba_chado]:
     Bio::Chado::Schema
 [gene_id]:
     String - Gene feature_id from the Chado database.
 [slice]:
     Bio::EnsEMBL::Slice
 [analysis]:
     Bio::EnsEMBL::Analysis
 [dbparams]:
     HashRef: Details required for querying the Chado database and
     loading of the new EnsEMBL database.
 [current]:
     is_obsolete from Chado feature table.


=head2 transcriptions

 Builder of Transcripts.   Returns a HashRef of a transcript HashRef.
 The transcript HashRef contains the Bio::EnsEMBL::Transcript object, a 
 HashRef of DBEntries and a HashRef of Translations.


=head2 number_of_transcripts

 Getter for the number of transcripts associated with a gene


=head2 get_translation_description

 Getter for the description of each of the translation objects associted 
 with a given transcript.

=head2 load_xrefs

 Loader of the transcript xrefs.


=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

=item
EnsEMBL API Release v61

=back

=head1 EXAMPLE

my $gene_transcripts = PomLoader::Transcript->new(
                      'dba_ensembl' => $self->dba_ensembl,
                      'dba_chado'   => $self->dba_chado,
                      'gene_id'     => $self->gene_id,
                      'slice'       => $slice,
                      'analysis'    => $self->analysis,
                  );

my $transcripts = $gene_transcripts->transcriptions();

print 'Number of translations: ', $gene_transcripts->number_of_transcripts,
    "\n" or next;

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut
