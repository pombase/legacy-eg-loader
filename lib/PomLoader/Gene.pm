package PomLoader::Gene;

use Moose;
use Data::Dumper;

use PomLoader::Transcript;
use PomLoader::FeaturePublications;
use PomLoader::FeatureLocation;
use PomLoader::FeatureSynonyms;
use PomLoader::FeatureXrefs;
use PomLoader::Orthology;
use PomLoader::Interactions;
use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::DBEntry;

has 'dba_ensembl' => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'   => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'gene_id'     => (isa => 'Int', is => 'ro', required => 1);
has 'analysis'    => (isa => 'Bio::EnsEMBL::Analysis', is => 'ro', required => 0);
has 'slice'       => (isa => 'Bio::EnsEMBL::Slice', is => 'ro', required => 0);
has 'gene'        => (isa => 'Bio::EnsEMBL::Gene', is => 'ro', required => 0);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);
has 'current'     => (isa => 'Int', is => 'ro', required => 1);

has 'genes'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_gene');
has 'update' => ( isa => 'Int', is => 'ro', lazy => 1, builder => '_update_gene');


sub _generate_gene {
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

    #
    # Get all information about the Gene.
    #
    #print "Getting location data\n";
    my $feature_gene = PomLoader::FeatureLocation->new(
                              'dba_chado'   => $self->dba_chado,
                              'feature_id'  => $self->gene_id,);
    my $featureloc_gene = $feature_gene->featurelocation();
    #my $featureloc_gene = +{$feature_gene->featurelocation()};

    #print \$featureloc_gene . "\n";
    #print Dumper $featureloc_gene;
    #print "\t", $featureloc_gene->{'uniquename'}, ' (Feature_ID: ', $self->gene_id, ")\n" or confess;


    #
    # Get all of the transcripts for a gene.
    #
    my $gene_transcripts = PomLoader::Transcript->new(
                          'dba_ensembl' => $self->dba_ensembl,
                          'dba_chado'   => $self->dba_chado,
                          'gene_id'     => $self->gene_id,
                          'gene_name'   => $featureloc_gene->{'name'},
                          'slice'       => $self->slice,
                          'analysis'    => $self->analysis,
                          'dbparams'    => $self->dbparams,
                          'current'     => $self->current,
                      );
    my $transcripts = $gene_transcripts->transcriptions();
    if (exists $transcripts->{'ERROR'}) {
        return $transcripts;
    }


    #
    # Assign Biotype
    #
    my $biotype = q{};
    my $transcript_id = q{};

    if ($gene_transcripts->number_of_transcripts>1 and $self->dbparams->{'isoforms'} == 0) {
        return {"ERROR" => 'WARNING: Multiple transcripts: ', $gene_transcripts->number_of_transcripts, ' transcripts (Gene Not Loaded)' };
    } elsif ($gene_transcripts->number_of_transcripts>1 and $self->dbparams->{'isoforms'} == 1) {
        warn 'WARNING: Multiple transcripts: ', $gene_transcripts->number_of_transcripts, ' transcripts (Gene Loaded)';
    }

    my @transcript_keys = keys %{ $transcripts }; 
    $transcript_id = $transcript_keys[0];
    
    #print Dumper $gene_transcripts;
    
    my %transcripthash = %{ $transcripts->{ $transcript_id } };
    if ($transcripthash{'ensembl'}->biotype eq 'pseudogenic_transcript') {
        $biotype = 'pseudogene';
    } else {
        $biotype = $transcripthash{'ensembl'}->biotype;
    }


    #
    # Create a DBEntry for the gene and fill with data + synonyms.
    #
    my $gene_name = $featureloc_gene->{'name'};
    my $gene_name_dbname = 'PomBase_Gene_Name';
    if ( $gene_name eq '' ) {
        $gene_name = $featureloc_gene->{'name'};
        $gene_name_dbname = 'PomBase_Systematic_ID';
    }
    
#    my $gene_dbentry = Bio::EnsEMBL::DBEntry -> new (
#        -PRIMARY_ID  => $featureloc_gene->{'uniquename'},
#        -DBNAME      => $gene_name_dbname, #$self->dbparams->{'dbname'}.'_GENE',
#        #-RELEASE     => 1,
#        -VERSION     => 0,
#        -DISPLAY_ID  => $gene_name,
#        -DESCRIPTION => $featureloc_gene->{'uniquename'},
#        -INFO_TYPE   => 'DIRECT',
#    );
#    my $feature_synonyms = PomLoader::FeatureSynonyms->new(
#                              'dba_chado'  => $self->dba_chado,
#                              'feature_id' => $self->gene_id,);
#    my $synonyms = $feature_synonyms->get_synonyms();
#    foreach my $synonym (@{$synonyms}) {
#        $gene_dbentry->add_synonym($synonym);
#    }
    
    #
    # Create Hash of all Xrefs
    #
#    my $feature_xrefs = PomLoader::FeatureXrefs->new(
#                              'dba_chado'  => $self->dba_chado,
#                              'feature_id' => $self->gene_id,
#                              'dbparams'   => $self->dbparams,);
#    my $xrefs = $feature_xrefs->featurexrefs();


    #
    # Extract description of the gene, first from the gene, if this is missing,
    # then from the translation, if that fails then use the uniquename.
    #
    my $genedescription = q{};
    if (defined $transcripthash{'ensembl'}->translation()) {
        my @translationdescription = @{$gene_transcripts->get_translation_description()};
        if (scalar @translationdescription > 1) {
            warn 'WARNING: More than one GeneDB description for gene.';
        }
        $genedescription = $translationdescription[0];
    } else {
        if (defined $transcripthash{'ensembl'}->description()) {
            $genedescription = $transcripthash{'ensembl'}->description();
        } else {
            $genedescription = $featureloc_gene->{'description'};
        }
    }


    #
    # Build the Gene object
    #
    #print "\n=================================================================\n";
    #print "Pre Gene Object:\n";
    #print "\tName:   " . $featureloc_gene->{'uniquename'} . "\n";
    #print "\tStrand: " . $featureloc_gene->{'strand'} . "\n";
    #print "\tStart:  " . $featureloc_gene->{'start'} . "\n";
    #print "\tEnd:    " . $featureloc_gene->{'end'} . "\n";
#    my $gene_ensembl = Bio::EnsEMBL::Gene->new(
#        -START           => $featureloc_gene->{'start'},
#        -END             => $featureloc_gene->{'end'},
#        -STRAND          => $featureloc_gene->{'strand'},
#        -SLICE           => $self->slice,
#        -STABLE_ID       => $featureloc_gene->{'uniquename'},
#        -VERSION         => 1,
#        -EXTERNAL_NAME   => $featureloc_gene->{'uniquename'},
#        -EXTERNAL_DB     => $self->dbparams->{'dbname'},
#        #-EXTERNAL_STATUS => 
#        -CREATED_DATE    => $featureloc_gene->{'created'},
#        -MODIFIED_DATE   => $featureloc_gene->{'modified'},
#        -DESCRIPTION     => $genedescription,#.' [Source:'.$self->dbparams->{'dbname'}.';Acc:'.$featureloc_gene->{'uniquename'}.']',
#        -BIOTYPE         =>  $biotype,
#        #-STATUS          => 'KNOWN', #This gets loaded later after the ontologies. 
#        -SOURCE          => $self->dbparams->{'dbname'},
#        -IS_CURRENT      => $self->current==0,
#        -analysis        => $self->analysis);
#    if ( $gene_ensembl->is_current() eq q{} ) {
#        $gene_ensembl->is_current(0);
#    }
    #print "\n=================================================================\n";
    #print "Post Gene Object:\n";
    #print "\tName:   " . $gene_ensembl->stable_id . "\n";
    #print "\tStrand: " . $gene_ensembl->strand . "\n";
    #print "\tStart:  " . $gene_ensembl->start . "\n";
    #print "\tEnd:    " . $gene_ensembl->end . "\n";
    
    
    #
    # Get all publications linked to a given feature_id
    #
#    my $pubs = PomLoader::FeaturePublications->new(
#                     'dba_chado'  => $self->dba_chado,
#                     'feature_id' => $self->gene_id,
#               );
#    my $gene_pub_dbentries = $pubs->get_all_publications();
    
    
    #
    # Get all the GO terms of the gene.
    #
#    my $goterms = PomLoader::GOTerms->new(
#                     'dba_chado'  => $self->dba_chado,
#                     'feature_id' => $self->gene_id,
#                     'dbparams'   => $self->dbparams,
#                 );
#    my $goterm_dbentries = $goterms->goterms();
    
    
    #
    # Get all the Ontology terms of the gene.
    #
#    my $ontologyterms = PomLoader::OntologyTerms->new(
#                     'dba_chado'    => $self->dba_chado,
#                     'feature_id'   => $self->gene_id,
#                     'dbparams'     => $self->dbparams,
#                     'feature_type' => 'Gene',
#                 );
#    my $ontology_dbentries = $ontologyterms->ontologyterms();
    
    
    #
    # Get all ontology terms for associated alleles of the gene.
    #
#    my $alleleontologyterms = PomLoader::OntologyTerms->new(
#                     'dba_chado'    => $self->dba_chado,
#                     'feature_id'   => $self->gene_id,
#                     'dbparams'     => $self->dbparams,
#                     'feature_type' => 'Gene',
#                 );
    
    
    
    my $gene_status = 'UNKNOWN';
    if ($biotype eq 'pseudogene') {
        $gene_status = $biotype;
    }
#    foreach my $ontology_dbentry ( values %{$ontology_dbentries} ) {
#        if (
#            $ontology_dbentry->display_id eq 'PBO:0000001' ||
#            $ontology_dbentry->display_id eq 'PBO:0000002' ||
#            $ontology_dbentry->display_id eq 'PBO:0000003' ||
#            $ontology_dbentry->display_id eq 'PBO:0000004' ||
#            $ontology_dbentry->display_id eq 'PBO:0000005' ||
#            $ontology_dbentry->display_id eq 'PBO:0000006' ||
#            $ontology_dbentry->display_id eq 'PBO:0000007'
#        ) {
#            $gene_status = $ontology_dbentry->description;
#        }
#    }
#    
#    $ontology_dbentries={};
    
    
    #
    # Get all the Orthologues for the gene.
    #
#    my $orthology = PomLoader::Orthology->new(
#                     'dba_chado'  => $self->dba_chado,
#                     'feature_id' => $self->gene_id,
#                     'dbparams'   => $self->dbparams,
#                 );
#    my $orthologs_dbentries = $orthology->get_orthologues();
    
    #
    # Get all the Interactions for the gene.
    #
#    my $interactions = PomLoader::Interactions->new(
#                     'dba_ensembl' => $self->dba_ensembl,
#                     'dba_chado'   => $self->dba_chado,
#                     'feature_id'  => $self->gene_id,
#                     'dbparams'    => $self->dbparams,
#                 );
#    $interactions->get_interactions();
    
    
    #print "\n=================================================================\n";
    #print "Add GO terms:\n";
    #print "\tName:   " . $gene_ensembl->stable_id . "\n";
    #print "\tStrand: " . $gene_ensembl->strand . "\n";
    #print "\tStart:  " . $gene_ensembl->start . "\n";
    #print "\tEnd:    " . $gene_ensembl->end . "\n";


    my $gene_ensembl = Bio::EnsEMBL::Gene->new(
        -START           => $featureloc_gene->{'start'},
        -END             => $featureloc_gene->{'end'},
        -STRAND          => $featureloc_gene->{'strand'},
        -SLICE           => $self->slice,
        -STABLE_ID       => $featureloc_gene->{'uniquename'},
        #-VERSION         => 1,
        -EXTERNAL_NAME   => $featureloc_gene->{'uniquename'},
        -EXTERNAL_DB     => $self->dbparams->{'dbname'},
        #-EXTERNAL_STATUS => 
        -CREATED_DATE    => $featureloc_gene->{'created'},
        -MODIFIED_DATE   => $featureloc_gene->{'modified'},
        -DESCRIPTION     => $genedescription.' [Source:'.$self->dbparams->{'dbname'}.';Acc:'.$featureloc_gene->{'uniquename'}.']',
        -BIOTYPE         =>  $biotype,
        -STATUS          => $gene_status, #'KNOWN', 
        -SOURCE          => $self->dbparams->{'dbname'},
        -IS_CURRENT      => $self->current==0,
        -analysis        => $self->analysis);
    if ( $gene_ensembl->is_current() eq q{} ) {
        $gene_ensembl->is_current(0);
    }
    

    #
    # Attach transcripts to the gene.
    #
    if ($self->dbparams->{'isoforms'} == 1) {
        foreach my $transcript_key ( keys %{ $transcripts } ) {
            $gene_ensembl->add_Transcript($transcripts->{$transcript_key}->{'ensembl'});
        }
    } else {
        $gene_ensembl->add_Transcript($transcripthash{'ensembl'});
    }
    #print "\n=================================================================\n";
    #print "Add Transcripts:\n";
    #print "\tName:   " . $gene_ensembl->stable_id . "\n";
    #print "\tStrand: " . $gene_ensembl->strand . "\n";
    #print "\tStart:  " . $gene_ensembl->start . "\n";
    #print "\tEnd:    " . $gene_ensembl->end . "\n";
    #print "\n=================================================================\n";
    #print "\n=================================================================\n";


    #
    # Create the gene container to pass the gene model around.
    #
    my %gene = (
        'ensembl'       => $gene_ensembl,
        #'gene_pubs'     => $gene_pub_dbentries,
        #'gene_xref'     => $gene_dbentry,
        #'gene_goterms'  => $goterm_dbentries,
        #'gene_ontologyterms' => $ontology_dbentries,
        #'feature_xrefs' => $xrefs,
        #'transcript'    => $gene_transcripts,
        #'orthologs'     => $orthologs_dbentries,
        #'interactions'  => $interactions,
        );
    return \%gene;
}


sub store {
    my $self = shift;
    my $genes = $self->genes();
    my $gene = $genes->{'ensembl'};
#    print "\tName:   " . $gene->stable_id . "\n";
#    print "\tStrand: " . $gene->strand . "\n";
#    print "\tStart:  " . $gene->start . "\n";
#    print "\tEnd:    " . $gene->end . "\n";
    
    my $gene_id = $self->dba_ensembl->get_GeneAdaptor->store($genes->{'ensembl'});
    #print 'Gene ID: ' . $gene_id . "\n";
    #$self->load_xrefs();
    #$self->_update_gene();
    return;
}


sub load_xrefs {
    my $self = shift;
    my $gene = $self->genes();
    $self->dba_ensembl->get_DBEntryAdaptor->store(
            $gene->{'gene_xref'},
            $gene->{'ensembl'}->dbID,
            'Gene'
    );
    $gene->{'ensembl'}->display_xref($gene->{'gene_xref'});
    
    #print $gene->{'gene_xref'}->primary_id . "\t" . $gene->{'gene_xref'}->description . "\n";
    
    #
    # This places all of the ontology terms on the transcript rather than mixing
    # them between the gene and the transcript and translation.
    #
    my @transcripts = @{ $gene->{'ensembl'}->get_all_Transcripts };
    foreach my $transcript ( @transcripts ) {
        foreach my $goterm_dbentry (values %{ $gene->{'gene_goterms'} }) {
            #print "\t|" . $goterm_dbentry->dbname . "|\n";
            #print "|" . $goterm_dbentry->primary_id."|\t|".$goterm_dbentry->description."|\n";
            
            if (!$goterm_dbentry->primary_id) {
                print "We have a problem here\n";
            }
            #print Dumper $goterm_dbentry;
            $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $goterm_dbentry,
                    $transcript->dbID,
                    'Transcript'
            );
        }
        #print "passed\n";
        foreach my $ontologyterm_dbentry (values %{ $gene->{'gene_ontologyterms'} }) {
            #print $ontologyterm_dbentry->dbname . "\t";
            #print $ontologyterm_dbentry->primary_id . "\t";
            #print join( ' ', @{ $ontologyterm_dbentry->get_all_linkage_types() } ) . "\t";
            #print ref $ontologyterm_dbentry;
            #print "\t";
            #print "\t" . $ontologyterm_dbentry . "\t";
            #print "|" . $ontologyterm_dbentry->primary_id."|\t|".$ontologyterm_dbentry->description."|\n";
            #print "\t" . ref $self->dba_ensembl;
            my $ontxref_id = $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $ontologyterm_dbentry,
                    $transcript->dbID,
                    'Transcript'
            );
            #print "\txref_id: " . $ontxref_id . "\n";
        }
    }
    
    foreach my $pub_dbentry (values %{ $gene->{'gene_pubs'} }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $pub_dbentry,
                $gene->{'ensembl'}->dbID,
                'Gene'
        );
    }
    
    foreach my $ortholog_dbentry (values %{ $gene->{'orthologs'} }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $ortholog_dbentry,
                $gene->{'ensembl'}->dbID,
                'Gene'
        );
    }

    foreach my $xref_dbentry (values %{ $gene->{'feature_xrefs'} }) {
        $self->dba_ensembl->get_DBEntryAdaptor->store(
                $xref_dbentry,
                $gene->{'ensembl'}->dbID,
                'Gene'
        );
    }
    $self->dba_ensembl->get_GeneAdaptor->update($gene->{'ensembl'});
    
    $gene->{'interactions'}->upload($gene->{'ensembl'}->dbID);
    
    
    $gene->{'transcript'}->load_xrefs();
    return;
}

sub _update_gene {
    my $self = shift;
    my $test_gene = 1;
    
    if (!defined $self->gene) {
        $test_gene = 0;
    }
    
    if ($test_gene == 0) {
        my $msg .= "Bio::EnsEMBL::Gene is not set.\n";
        return {"ERROR" => $msg };
    }
    
#    my $genes = $self->genes();
#    my $gene = $genes->{'ensembl'};
    my $chado_gene = $self->genes();
    #print Dumper $chado_gene;
    #print Dumper $self->gene;
    
    #my $chado_description = $chado_gene->{'ensembl'}->description . ' [Source:PomBase;Acc:' . $self->gene->stable_id . ']';
#    print 'Currect id: ' . $self->gene->display_id . ' (' . $self->gene->stable_id . ")\n";
#    print $chado_gene->{'gene_xref'}->display_id . "\n";
#    print $chado_description . "\n";
    
    
    
#    if ($self->gene->description ne $chado_description) {
#      print 'Updating description from ' . $self->gene->stable_id . "\n";
#      $self->gene->description($chado_description);
#    }
#    
#    $self->dba_ensembl->get_DBEntryAdaptor->store(
#        $chado_gene->{'gene_xref'},
#        $self->gene->dbID,
#        'Gene'
#    );
    
#    if ( !defined $self->gene->display_xref ){
#      print 'Updating gene name from ' . $self->gene->stable_id . "\n";
##      print "\t" . $chado_gene->{'gene_xref'}->primary_id . "\n";
##      print "\t" . $chado_gene->{'gene_xref'}->display_id . "\n";
#      #$self->dba_ensembl->get_DBEntryAdaptor->store($chado_gene->{'gene_xref'});
##      $self->gene->display_xref($chado_gene->{'gene_xref'});
#    } elsif ($self->gene->display_id ne $chado_gene->{'gene_xref'}->display_id) {
#      print 'Updating gene name from ' . $self->gene->stable_id . "\n";
##      print "\t" . $chado_gene->{'gene_xref'}->primary_id . "\n";
##      print "\t" . $chado_gene->{'gene_xref'}->display_id . "\n";
#      #$self->dba_ensembl->get_DBEntryAdaptor->store($chado_gene->{'gene_xref'});
##      $self->gene->display_xref($chado_gene->{'gene_xref'});
#    }
#    
##    $self->dba_ensembl->get_GeneAdaptor->update($self->gene);
    
#    return 1;
    
    
    #
    # Get all publications linked to a given feature_id
    #
    my $pubs = PomLoader::FeaturePublications->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $self->gene_id,
               );
    my $gene_pub_dbentries = $pubs->get_all_publications();
#    my $gene_pub_dbentries = $chado_gene->{'gene_pubs'};
    
    
    #
    # Create Hash of all Xrefs
    #
    my $feature_xrefs = PomLoader::FeatureXrefs->new(
                              'dba_chado'  => $self->dba_chado,
                              'feature_id' => $self->gene_id,
                              'dbparams'   => $self->dbparams,);
    my $xrefs = $feature_xrefs->featurexrefs();
#    my $xrefs = $chado_gene->{'gene_xref'};
    
    
    #
    # Get all the GO terms of the translation.
    #
    my $goterms = PomLoader::GOTerms->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $self->gene_id,
                     'dbparams'   => $self->dbparams,
                 );
    my $goterm_dbentries = $goterms->goterms();
    
    
    #
    # Get all the Ontology terms of the gene.
    #
    my $ontologyterms = PomLoader::OntologyTerms->new(
                     'dba_chado'    => $self->dba_chado,
                     'feature_id'   => $self->gene_id,
                     'dbparams'     => $self->dbparams,,
                     'feature_type' => 'Gene',
                 );
    my $ontology_dbentries = $ontologyterms->ontologyterms();
    
    
    #
    # Get all the Ortholgous Genes.
    #
    my $orthologyterms = PomLoader::Orthology->new(
                     'dba_chado'  => $self->dba_chado,
                     'feature_id' => $self->gene_id,
                     'dbparams'   => $self->dbparams,
                 );
    my $orthologous_dbentries = $orthologyterms->get_orthologues();
    
    
    #
    # Get all the Interactions for the gene.
    #
    my $interactions = PomLoader::Interactions->new(
                     'dba_ensembl' => $self->dba_ensembl,
                     'dba_chado'   => $self->dba_chado,
                     'feature_id'  => $self->gene_id,
                     'dbparams'    => $self->dbparams,
                 );
    $interactions->get_interactions();
    
    
    #
    # Store all of the DBEntries
    #
    
    # Xref DBEntries
    foreach my $xref_dbentry (values %{ $xrefs }) {
        #print $xref_dbentry->display_id . "\t" . $self->gene->stable_id . "\n";
        my $result = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $xref_dbentry,
                $self->gene->dbID,
                'Gene',
        );
        if (!$result) {
          warn 'WARNING - XREF: Gene: ', $self->gene->primary_id, ' DBEntry not loaded: ', $xref_dbentry->primary_id, ' ', $xref_dbentry->display_id;
        }
    }
    
    # Modify to use associated xrefs
    foreach my $pub_dbentry (values %{ $gene_pub_dbentries } ) {
        my $result = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $pub_dbentry,
                $self->gene->dbID,
                'Gene'
        );
        if (!$result) {
          warn 'WARNING - PUBLICATION: Gene: ', $self->gene->primary_id, ' DBEntry not loaded: ', $pub_dbentry->primary_id, ' ', $pub_dbentry->display_id;
        }
    }
    
    foreach my $ortholog_dbentry (values %{ $orthologous_dbentries }) {
        my $result = $self->dba_ensembl->get_DBEntryAdaptor->store(
                $ortholog_dbentry,
                $self->gene->dbID,
                'Gene'
        );
        if (!$result) {
          warn 'WARNING - ORTHOLOG: Gene: ', $self->gene->primary_id, ' DBEntry not loaded: ', $ortholog_dbentry->primary_id, ' ', $ortholog_dbentry->display_id;
        }
    }
    
    my $transcripts = $self->gene->get_all_Transcripts;
    foreach my $transcript ( @{ $transcripts } ) {
        #
        # Reload all ontology terms 
        #
        
        # Ontology Terms (not GO terms)
        foreach my $ontologyterm_dbentry (values %{ $ontology_dbentries }) {
            #print $ontologyterm_dbentry->primary_id . " - " . $ontologyterm_dbentry->dbname . "\n";
            #print Dumper $ontologyterm_dbentry;
            my $result = $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $ontologyterm_dbentry,
                    $transcript->dbID,
                    'Transcript',
            );
            if (!$result) {
              warn 'WARNING - ONTOLOGY: Gene - ', $transcript->primary_id, ' DBEntry not loaded: ', $ontologyterm_dbentry->primary_id, ' ', $ontologyterm_dbentry->display_id;
            }
        }
        
        # GO Terms
        foreach my $goterm_dbentry (values %{ $goterm_dbentries }) {
            #print $goterm_dbentry->primary_id . " - " . $goterm_dbentry->dbname . "\n";
            my $result = $self->dba_ensembl->get_DBEntryAdaptor->store(
                    $goterm_dbentry,
                    $transcript->dbID,
                    'Transcript',
            );
            if (!$result) {
              warn 'WARNING - GO: Gene - ', $transcript->primary_id, ' DBEntry not loaded: ', $goterm_dbentry->primary_id, ' ', $goterm_dbentry->display_id;
            }
        }
        
    }
    
    # Interactions
    foreach my $dbentry (@{$self->gene->get_all_DBEntries()}) {
        if ($dbentry->dbname eq 'PomBase_Interaction_GENETIC' or $dbentry->dbname eq 'PomBase_Interaction_PHYSICAL') {
            $self->dba_ensembl->get_DBEntryAdaptor->remove_from_object($dbentry, $self->gene, 'Gene');
        }
    }
    
    $interactions->upload($self->gene->dbID);
    
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::Gene - Moose module for handling the construction and 
                  loading of EnsEMBL gene models.

=head1 DESCRIPTION

This is a perl module that handles the loading of gene models from the Chado
database into the EnsEMBL database.

=head1 METHODS

=head2 new

 [dba_ensembl]:
     Bio::EnsEMBL::DBSQL::DBAdaptor
 [dba_chado]:
     Bio::Chado::Schema
 [gene_id]:
     String - Gene feature_id from the Chado database.
 [analysis]:
     Bio::EnsEMBL::Analysis
 [dbparams]:
     HashRef: Details required for querying the Chado database and 
     loading of the new EnsEMBL database.
 [current]:
     is_obsolete from Chado feature table.


=head2 gene

 Builder of the gene model.   Returns a HashRef of HashRefs for the 
 EnsEMBL gene object, DBEntry xrefs and EnsEMBL transcript objects. 


=head2 store

 Loads the gene model into the EnsEMBL database.   This also percollates 
 through the rest of the gene model to load the transcripts, exons, 
 translations and the associated xrefs.

=head2 load_xrefs

 Loads all of the external xrefs for a given gene

=head2 update_gene

 Loads all the new annotations for the gene to the database.
 
 []

=head1 EXAMPLE

my $gene = PomLoader::Gene->new(
               'dba_ensembl' => $db,
               'dba_chado'   => $chado,
               'gene_id'     => $rs_gene->feature_id,
               'analysis'    => $analysis,
               'dbparams'    => \%dbparams,
               'current'     => $rs_gene->is_obsolete);
$gene->genes();
$gene->store();

Where $analysis is a Bio::EnsEMBL::Analysis object.

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
