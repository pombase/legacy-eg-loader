package PomLoader::Transcript;

use Moose;
use Data::Dumper;

use PomLoader::Translation;
use PomLoader::Exon;
use PomLoader::BioDefinitions;
use PomLoader::FeatureSynonyms;
use PomLoader::FeatureLocation;
use PomLoader::FeatureXrefs;
use PomLoader::OntologyTerms;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::DBEntry;
use Try::Tiny;

has 'dba_ensembl' => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'   => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'gene_id'     => (isa => 'Int', is => 'ro', required => 1);
has 'gene_name'   => (isa => 'Str', is => 'ro', required => 1);
has 'slice'       => (isa => 'Bio::EnsEMBL::Slice', is => 'ro', required => 0);
has 'analysis'    => (isa => 'Bio::EnsEMBL::Analysis', is => 'ro', required => 0);
has 'transcript'  => (isa => 'Bio::EnsEMBL::Transcript', is => 'ro', required => 0);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);
has 'current'     => (isa => 'Int', is => 'ro', required => 1);

has 'transcriptions' => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_transcript' );
has 'update'         => ( isa => 'Int', is => 'ro', lazy => 1, builder => '_update_transcript' );


sub _generate_transcript {
    my $self = shift;
    
    my $test_slice = 1;
    my $test_analysis = 1;
    if (!defined $self->analysis) {
        $test_analysis = 0;
    }
    if (!defined $self->slice) {
        $test_slice = 0;
    }
    
    if ($test_analysis == 0 or $test_slice == 0) {
        my $msg = '';
        if ( $test_analysis == 0 ) {
            $msg = "Bio::EnsEMBL::Analysis is not set.\n";
        }
        if ( $test_slice == 0 ) {
            $msg .= "Bio::EnsEMBL::Slice is not set.\n";
        }
        return {"ERROR" => $msg };
    }
    
    my %transcripts = ();
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

    #
    # Get all the products of the gene.
    #
    my $feature_transcript = PomLoader::FeatureLocation->new(
                              'dba_chado'  => $self->dba_chado,
                              'type_id'    => 'part_of',
                              'feature_id' => $self->gene_id);
    my @featureloc_transcript = @{$feature_transcript->subfeaturelocation()};

    my $trascript_count = 1;
    
    #print Dumper @featureloc_transcript;
    
    my $multiple_transcripts = 0;
    foreach my $transcript_feature (@featureloc_transcript) {
        #
        # Test if the transcript is a valid transcript xxxRNA
        #
        if (
          !$transcript_feature->{'type_id'} ||
          $transcript_feature->{'type_id'} eq 'allele'
        ) {
        	next;
        }
        #print Dumper $transcript_feature->{'type_id'};
        #print Dumper $biodef->chado_type;
        if (
          ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'mRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'tRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'rRNA'})
          #|| ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'scRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'snRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'snoRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'ncRNA'})
          || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'pseudogenic_transcript'})
        ) {
          $multiple_transcripts += 1;
        }
    }
    
    foreach my $transcript_feature (@featureloc_transcript) {

        my %transcript = ();

        #
        # Test if the transcript is a valid transcript xxxRNA
        #
        if ( $transcript_feature->{'type_id'} ) {
	        if (($transcript_feature->{'type_id'} eq $biodef->chado_type->{'mRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'tRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'rRNA'})
	                #|| ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'scRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'snRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'snoRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'ncRNA'})
	                || ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'pseudogenic_transcript'})) {
	            %transcript = %{ $self->_build_transcript($transcript_feature, $trascript_count, $multiple_transcripts) };
	        } elsif ($transcript_feature->{'relationship'} eq 'orthologous_to') {
	            #print "$transcript_feature->{'feature_id'} is an ortholog\n";
        	}
        }
        
        #
        # Need to check for error messages.
        #
        if (exists $transcript{'ERROR'} ) {
            return \%transcript;
        } elsif ( scalar keys %transcript == 0 ) {
            next;
        }

        $transcripts{$transcript_feature->{'feature_id'}} = \%transcript;
        
        $trascript_count = $trascript_count + 1;
    }
    return \%transcripts;
}


sub _build_transcript {
    my ( $self, $transcript_feature, $transcript_count, $multi_transcripts) = @_;

    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

    my %transcript = ();
    my $biotype = q{};


    #
    # Build DBEntry object
    #
    my $dbentry = q{};
    if ($self->dbparams->{'transcripts_with_gene_name'} == 1) {
        if ($multi_transcripts > 1) {
            $dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $transcript_feature->{'uniquename'},
                -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
                #-RELEASE     => 1,
                #-VERSION     => 1,
                -DISPLAY_ID  => $self->gene_name . '-' . $transcript_count,
                -DESCRIPTION => $transcript_feature->{'description'},
                -INFO_TYPE   => 'DIRECT',
            );
        } else {
            $dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $transcript_feature->{'uniquename'},
                -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
                #-RELEASE     => 1,
                #-VERSION     => 1,
                -DISPLAY_ID  => $self->gene_name,
                -DESCRIPTION => $transcript_feature->{'description'},
                -INFO_TYPE   => 'DIRECT',
            );
        }
    } else {
        $dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $transcript_feature->{'uniquename'},
            -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
            #-RELEASE     => 1,
            #-VERSION     => 1,
            -DISPLAY_ID  => $transcript_feature->{'name'},
            -DESCRIPTION => $transcript_feature->{'description'},
            -INFO_TYPE   => 'DIRECT',
        );
    }
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
#    my $feature_xrefs = PomLoader::FeatureXrefs->new(
#                              'dba_chado'   => $self->dba_chado,
#                              'feature_id'  => $transcript_feature->{'feature_id'},
#                              'dbparams'    => $self->dbparams,);
#    my $xrefs = $feature_xrefs->featurexrefs();
    
    
    #
    # Build Transcript Object
    #
    #print "\n=================================================================\n";
    #print "Pre Generate Transcripts:\n";
    #print "\tName:   " . $transcript_feature->{'uniquename'} . "\n";
    #print "\tStart:  " . $transcript_feature->{'start'} . "\n";
    #print "\tEnd:    " . $transcript_feature->{'end'} . "\n";
    my $transcript_ensembl = Bio::EnsEMBL::Transcript -> new(
        -SLICE           => $self->slice,
        -START           => $transcript_feature->{'start'},
        -END             => $transcript_feature->{'end'},
        -STABLE_ID       => $transcript_feature->{'uniquename'},  # e.g. SPAC13G6.05c.1
        #-VERSION         => 1,
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
    #print "\n=================================================================\n";
    #print "Post Generate Transcripts:\n";
    #print "\tName:   " . $transcript_ensembl->stable_id . "\n";
    #print "\tStart:  " . $transcript_ensembl->start . "\n";
    #print "\tEnd:    " . $transcript_ensembl->end . "\n";


    #
    # Get all exons associated with the transcript
    #
    my $exons = PomLoader::Exon->new(
                    'dba_ensembl'   => $self->dba_ensembl,
                    'dba_chado'     => $self->dba_chado,
                    'transcript_id' => $transcript_feature->{'feature_id'},
                    'slice'         => $self->slice,
                    'current'       => $self->current,
                    'dbparams'    => $self->dbparams,);

    my $exon_set = $exons->exons();
    my @exonlist = @{ $exon_set->{'exons'} };
    my @utrlist  = @{ $exon_set->{'utrs'} };
    
    my %warningmessage = ();
        
#        my $exon_overlap = $exons->overlaps();
#        if ( $exon_overlap ) {
#            my $message = "Overlapping Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
#            $warningmessage{'ERROR'} = $message;
#            return \%warningmessage;
#        }

    #print "\n=================================================================\n";
    #print @exonlist;
    foreach my $exon ( @exonlist ) {
        try {
           $transcript_ensembl->add_Exon($exon);
           #print "Add Exons:\n";
           #print "\tName:   " . $exon->stable_id . "\n";
           #print "\tStart:  " . $exon->start . "\n";
           #print "\tEnd:    " . $exon->end . "\n";
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
    # Get all publications linked to a given feature_id
    #
#    my $pubs = PomLoader::FeaturePublications->new(
#                     'dba_chado'  => $self->dba_chado,
#                     'feature_id' => $transcript_feature->{'feature_id'},
#               );
#    my $transcript_pub_dbentries = $pubs->get_all_publications();
    
    #
    # Get all the GO terms of the transcript.
    #
#    my $goterms = PomLoader::GOTerms->new(
#                     'dba_chado'  => $self->dba_chado,
#                     'feature_id' => $transcript_feature->{'feature_id'},
#                     'dbparams'    => $self->dbparams,
#                 );
#    my $goterm_dbentries = $goterms->goterms();
#    foreach my $goterm_dbentry (keys %{$goterm_dbentries}) {
#        $transcript_ensembl->add_DBEntry($goterm_dbentries->{$goterm_dbentry});
#    }
    
    
    #
    # Get all the Ontology terms of the transcript.
    #
#    my $ontologyterms = PomLoader::OntologyTerms->new(
#                     'dba_chado'    => $self->dba_chado,
#                     'feature_id'   => $self->gene_id,
#                     'dbparams'     => $self->dbparams,
#                     'feature_type' => 'Transcript',
#                 );
#    my $ontology_dbentries = $ontologyterms->ontologyterms();
#    foreach my $ontology_dbentry (keys %{$ontology_dbentries}) {
#        $transcript_ensembl->add_DBEntry($ontology_dbentries->{$ontology_dbentry});
#    }
    


    #
    # Create translation objects for the transcript
    #
    my $eUTR5 = 0;
    my $eUTR3 = 0;
    if ( $exon_set->{'utr5'} ) {
    	$eUTR5 = $exon_set->{'utr5'}+0;
    }
    if ( $exon_set->{'utr3'} ) {
        $eUTR3 = $exon_set->{'utr3'}+0;
    }
    #print "eUTR5: $exon_set->{'utr5'} | eUTR3: $exon_set->{'utr3'}\n";
    my $translations = PomLoader::Translation->new(
                           'dba_ensembl'   => $self->dba_ensembl,
                           'dba_chado'     => $self->dba_chado,
                           'transcript_id' => $transcript_feature->{'feature_id'},
                           'slice'         => $self->slice,
                           'startexon'     => $transcript_ensembl->start_Exon,
                           'endexon'       => $transcript_ensembl->end_Exon,
                           'utr5'          => $eUTR5,
                           'utr3'          => $eUTR3,
                           'dbparams'      => $self->dbparams,
                           );

    my %translationlist = %{$translations->get_translations()};


    #
    # Handle the biotype of the transcript.
    #
    if ($transcript_feature->{'type_id'} eq $biodef->chado_type->{'pseudogenic_transcript'} ) {
        $biotype = 'pseudogene';
        if (scalar keys %translationlist > 0) {
            %translationlist = ();
        }
    } else {
        $biotype = $biodef->ensembl_type->{$transcript_feature->{'type_id'}};
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
    # Add UTRs to the transcript
    #
    foreach my $utr ( @utrlist ) {
        try {
           $transcript_ensembl->add_Exon($utr);
        } catch {
            my $message = "Overlapping UTR Exons in Transcript: $transcript_feature->{'feature_id'}  (Gene Skipped)\n";
            $warningmessage{'ERROR'} = $message;
            last;
        };
    }
    
    if (exists $warningmessage{'ERROR'} ) {
        return \%warningmessage;
    }


    #
    # Bundle up the transcript objects and load into the container.
    #
    $transcript{'ensembl'}          = $transcript_ensembl;
    #$transcript{'transcript_xref'}  = $dbentry;
    #$transcript{'feature_xrefs'}    = $xrefs;
    #$transcript{'feature_ontologyterms'}    = $ontology_dbentries;
    #$transcript{'feature_pubs'}     = $transcript_pub_dbentries;
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
        
#        foreach my $ontologyterm_dbentry (values %{ $transcript->{'feature_ontologyterms'} }) {
#            $self->dba_ensembl->get_DBEntryAdaptor->store(
#                    $ontologyterm_dbentry,
#                    $transcript->{'ensembl'}->dbID,
#                    'Transcript'
#            );
#        }
        
        foreach my $pub_dbentry (values %{ $transcript->{'feature_pubs'} }) {
            $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $pub_dbentry,
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


sub _update_transcript {
    my $self = shift;
    my $test_transcript = 1;
    
    if (!defined $self->transcript) {
        $test_transcript = 0;
    }
    
    if ($test_transcript == 0) {
        my $msg .= "Bio::EnsEMBL::Transcript is not set.\n";
        return {"ERROR" => $msg };
    }
    
    # Get transcript feauture_id for a given stable_id
    my $rs_transcript = $self->dba_chado->resultset('Sequence::Feature')
        ->search(
        { 'me.uniquename'  => $self->transcript->stable_id() }
    );
    my $rs_feature = $rs_transcript->next;
    
    
    
    
    
    #my $chado_transcripts = $self->transcriptions();
    #print Dumper $chado_transcripts;
    #my $chado_transcript = $chado_transcripts->{$rs_feature->feature_id};
    
    my $transcript_xref = Bio::EnsEMBL::DBEntry -> new (
        -PRIMARY_ID  => $rs_feature->get_column('uniquename'),
        -DBNAME      => $self->dbparams->{'dbname'}.'_TRANSCRIPT',
        #-RELEASE     => 1,
        #-VERSION     => 1,
        -DISPLAY_ID  => $rs_feature->get_column('name'),
        -DESCRIPTION => '',
        -INFO_TYPE   => 'DIRECT',
    );
    
#    print 'Currect id: ' . $self->transcript->display_id . ' (' . $self->transcript->stable_id . ")\n";
#    print $transcript_xref->display_id . "\n";
#    print Dumper $transcript_xref;
#    print 'Found: ' . $rs_feature->get_column('uniquename') . ' - ' . $rs_feature->get_column('name');
    
    $self->dba_ensembl->get_DBEntryAdaptor->store(
        $transcript_xref,
        $self->transcript->dbID,
        'Transcript'
    );
    
    if ( !defined $self->transcript->display_xref ){
      print 'Updating transcript name for ' . $self->transcript->stable_id . "\n";
      #$self->dba_ensembl->get_DBEntryAdaptor->store($chado_transcript->{'transcript_xref'});
      $self->transcript->display_xref($transcript_xref);
    } elsif ($self->transcript->display_id ne $transcript_xref->display_id) {
      print 'Updating transcript name for ' . $self->transcript->stable_id . "\n";
      #$self->dba_ensembl->get_DBEntryAdaptor->store($chado_transcript->{'transcript_xref'});
      $self->transcript->display_xref($transcript_xref);
    }
    
    $self->dba_ensembl->get_TranscriptAdaptor->update($self->transcript);
    
    
    
    
    
    
    
    
    
    #
    # Create Hash of all Xrefs
    #
    my $feature_xrefs = PomLoader::FeatureXrefs->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $rs_feature->feature_id,
                              'dbparams'   => $self->dbparams,);
    my $xrefs = $feature_xrefs->featurexrefs();
    
    
    #
    # Get all publications linked to a given feature_id
    #
    my $pubs = PomLoader::FeaturePublications->new(
                   'dba_chado'  => $self->dba_chado,
                   'feature_id' => $rs_feature->feature_id,
               );
    my $transcript_pub_dbentries = $pubs->get_all_publications();
    
    
    #
    # Get all the GO terms of the transcript.
    #
    my $goterms = PomLoader::GOTerms->new(
                      'dba_chado'  => $self->dba_chado,
                      'feature_id' => $rs_feature->feature_id,
                      'dbparams'   => $self->dbparams,
                  );
    my $goterm_dbentries = $goterms->goterms();
    
    
    #
    # Get all the Ontology terms of the transscript.
    #
    my $ontologyterms = PomLoader::OntologyTerms->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $rs_feature->feature_id,
                     'dbparams'    => $self->dbparams,
                 );
    my $ontology_dbentries = $ontologyterms->ontologyterms();
    
    
    
    
    
    #
    # Store all of the DBEntries
    #
    foreach my $xref_dbentry (values %{ $xrefs }) {
        if ( 
          $xref_dbentry->dbname eq 'EMBL' or
          $xref_dbentry->dbname eq 'KEGG' or
          $xref_dbentry->dbname eq 'RFAM' or
          $xref_dbentry->dbname eq 'SPD'
        ) {
        	$self->dba_ensembl->get_DBEntryAdaptor->store(
                    $xref_dbentry,
                    $self->transcript->get_Gene->dbID,
                    'Gene'
            );
        } else {
	        $self->dba_ensembl->get_DBEntryAdaptor->store(
	                $xref_dbentry,
	                $self->transcript->dbID,
	                'Transcript'
	        );
        }
    }
    
    #
    # Reload all ontology terms
    #
    foreach my $ontologyterm_dbentry (values %{ $ontology_dbentries }) {
        #print $ontologyterm_dbentry . "\t" . $ontologyterm_dbentry->display_id . "\t" . $self->transcript->stable_id . "\n";
        my $xref_id = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $ontologyterm_dbentry,
                $self->transcript->dbID,
                'Transcript'
        );
        if (!defined $xref_id) {
          print $self->transcript->stable_id . "\n";
          print "\t" . $ontologyterm_dbentry->dbname . ': ' . $ontologyterm_dbentry->primary_id . "\n";
        }
    }
    foreach my $goterm_dbentry (values %{ $goterm_dbentries }) {
        #print 'GOterm: ' . $goterm_dbentry->primary_id . "\t";
        my $xref_id = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $goterm_dbentry,
                $self->transcript->dbID,
                'Transcript'
        );
        if (!defined $xref_id) {
          print $self->transcript->stable_id . "\n";
          print "\tGOterm: " . $goterm_dbentry->primary_id . "\n";
        }
    }
    
    #
    # Update publications, these are attached to the Gene.
    #
    foreach my $pub_dbentry (values %{ $transcript_pub_dbentries }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $pub_dbentry,
                $self->transcript->get_Gene->dbID,
                'Gene'
        );
    }
    $self->dba_ensembl->get_TranscriptAdaptor->update($self->transcript);
    
    return 1;
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
