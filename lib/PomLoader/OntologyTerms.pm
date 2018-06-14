package PomLoader::OntologyTerms;

use Moose;
use Data::Dumper;

use PomLoader::Genotypes;

use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;

has 'dba_chado'    => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'feature_id'   => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'     => (isa => 'HashRef', is => 'ro', required => 1);
has 'feature_type' => (isa => 'Str', is => 'ro', required => 0);

has 'ontologyterms'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_ontologyterms');


sub _generate_ontologyterms {
    my $self = shift;
    my %terms = ();
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

#    select 
#        f.feature_id, f.uniquename, f.type_id,
#        dbx.accession,
#        c.name,
#        fcp.value as evidence,
#        p.type_id, p.uniquename 
#    from 
#        feature f, 
#        feature_cvterm fc, 
#        feature_cvtermprop fcp, 
#        cvterm c, 
#        dbxref dbx, 
#        pub p 
#    where 
#        f.feature_id=fc.feature_id
#        and fc.cvterm_id=c.cvterm_id
#        and fc.pub_id=p.pub_id
#        and fcp.feature_cvterm_id=fc.feature_cvterm_id
#        and dbx.dbxref_id=c.dbxref_id
#        and c.cv_id in (13, 14, 15)
#        and fcp.type_id=92835 
#    order by f.feature_id limit 10;

    #
    # Get all the GO terms of the translation.
    #
    my @obos = ('name_description',
                'complementation',
                'sequence_feature',
                'DNA_binding_specificity',
                'disease_association',
                'subunit_composition',
                'ex_tools',
                'gene_ex',
                'genome_org',);
    
    my @feature_id_list = ( $self->feature_id );
    
    #
    # Get all allele feature_ids
    # Needs modifying to use the feautre_ids for the genotypes then hooking in at the FYPO section
    #
    my $genotypes = q{};
    if (defined($self->feature_type) and $self->feature_type eq 'Gene') {
        $genotypes = PomLoader::Genotypes->new(
                         'dba_chado'    => $self->dba_chado,
                         'feature_id'   => $self->feature_id,
                         'dbparams'     => $self->dbparams,
                     );
        push @feature_id_list, $genotypes->genotype_feature_ids;
    }
    
    #print join(', ', @feature_id_list) . "\n";
    
    my $rs = $self->dba_chado->resultset('Sequence::FeatureCvterm')
              ->search(
                  {'me.feature_id' => { 'in' => [ @feature_id_list ] } },
                  {join => [{'cvterm' => [{'dbxref' => 'db'}, 'cv']},
                            {'feature_cvtermprops' => 'type'},
                            'pub',
                            'feature'],
                      '+select' => [
                          'feature.name',
                          'feature.uniquename',
                          'cvterm.dbxref_id',
                          'db.name',
                          'dbxref.accession',
                          'cv.name',
                          'cvterm.cvterm_id',
                          'cvterm.name',
                          'cvterm.definition',
                          'feature_cvtermprops.feature_cvtermprop_id',
                          'type.name',
                          'feature_cvtermprops.value',
                          'pub.uniquename'],
                      '+as' => [
                            'feature_name',
                            'feature_uniquename',
                            'dbxref',
                            'db_name',
                            'db_accession',
                            'ontology',
                            'cvterm_id',
                            'name',
                            'definition',
                            'feature_cvtermprop_id',
                            'evidence_type',
                            'evidence',
                            'pubid',],
                      'where' => {'cv.name' => {'in' => ['name_description',
                                                         'complementation',
                                                         'sequence_feature',
                                                         'sequence',
                                                         'DNA_binding_specificity',
                                                         'disease_associated',
                                                         'subunit_composition',
                                                         'ex_tools',
                                                         'gene_ex',
                                                         'pb_quiescence',
                                                         'genome_org',
                                                         'species_dist',
                                                         'PSI-MOD',
                                                         'fission_yeast_phenotype',
                                                         'misc',
                                                         'warning',
                                                         'pathway',
                                                         'RILEY',
                                                         'cat_act',
                                                         'm_f_g',
                                                         'external_link',
                                                         'protein_family',
                                                         'PomBase family or domain',
                                                         'PomBase gene characterisation status',
                                                         'PomBase annotation extension terms']},
                   },
                  });

    while ( my $rs_term = $rs->next ) { 
        
        #
        # Create the OntologyXref object
        #
        my @annot_ext = ();
        my $ontology = '';
        my $accession = '';
        my $description = '';
#        if ( $rs_term->get_column('db_name') . ':' . $rs_term->get_column('db_accession') eq 'FYPO:0000446') {
#          print $rs_term->get_column('ontology') . "\t" . $rs_term->get_column('db_name') . ':' . $rs_term->get_column('db_accession') . "\n";
#          print "\tfeature_cvterm_id: " . $rs_term->feature_cvterm_id . ";\tcvterm_id: " . $rs_term->get_column('cvterm_id') . "\n";
#          print "\tEvidence: " . $rs_term->get_column('evidence_type') . "\t" . $rs_term->get_column('evidence') . "\n";
#        }
        if ( $rs_term->get_column('db_name') eq 'PomBase'  and 
             $rs_term->get_column('ontology') ne 'PomBase annotation extension terms') {
          #print "HERE 00\n";
          $ontology    = 'PBO';
          $accession   = $rs_term->get_column('db_accession');
          $description = $rs_term->get_column('name');
        } elsif ($rs_term->get_column('ontology') eq 'PomBase annotation extension terms') {
          #print "HERE 01: " . $rs_term->get_column('cvterm_id') . "\n";
          my $rs_annot_ext = $self->dba_chado->resultset('Cv::CvtermRelationship')
                      ->search(
                          {'me.subject_id' => $rs_term->get_column('cvterm_id')},
                          {join => [
                              {'object' => [
                                {'dbxref' => 'db'},
                                'cv',
                              ]},
                              'type',
                          ],
                          '+select' => [
                            'db.name',
                            'dbxref.accession',
                            'object.name'],
                          '+as' => ['db_name', 'term_accession', 'term_name'],
                          'where' => { 'type.name' => ['is_a'] }
                          });
          while ( my $annot_ext = $rs_annot_ext->next ) {
            #print "HERE 01_0: " . $annot_ext->get_column('db_name') . "\t" . $annot_ext->get_column('term_accession') . "\n";
            $ontology    = $annot_ext->get_column('db_name');
            $accession   = $annot_ext->get_column('term_accession');
            $description = $annot_ext->get_column('term_name');
            if ( $ontology eq 'PomBase' ) {
              $ontology    = 'PBO';
            }
            #print $ontology . "\t" . $accession . "\n\t" . $description . "\n";
          }
          #print "HERE 01a\n";
          if ($ontology eq 'GO') {
            next;
          }
          #print "HERE 01b: " . $ontology . "\t" . $accession . "\n";
          $rs_annot_ext = $self->dba_chado->resultset('Sequence::FeatureCvterm')
                      ->search(
                          {'me.feature_cvterm_id' => $rs_term->feature_cvterm_id},
                          {join => [
                              {'cvterm' => [
                                  {'dbxref' => 'db'},
                                  'cv',
                                  {'cvterm_relationship_subjects' => [
                                      {'object' => [
                                          {'dbxref' => 'db'},
                                          'cv'
                                      ]},
                                      'type'
                                  ]},
                                  {'cvtermprops' => 'type'}
                              ]},
                              'pub'
                          ],
                              '+select' => [
                                  'db.name',
                                  'dbxref.accession',
                                  'type.name',
                                  'db_2.name',
                                  'dbxref_2.accession',
                                  'object.name',
                                  'type_2.name',
                                  'cvtermprops.value',
                                  'pub.uniquename'],
                              '+as' => ['db_name', 'db_accession', 'annot_ext', 'db_name_ext', 'db_accession_ext', 'term_name', 'cvtermprop_type', 'cvtermprop_value', 'pub_id'],
                          });
          
          my $term_name;
          my $term_id;
          my $term_feature_cvterm_id;
          while ( my $go_annot_ext = $rs_annot_ext->next ) {
              #print "\t" . $go_annot_ext->get_column('pub_id') . "\n\t";
              if ($go_annot_ext->get_column('annot_ext') eq 'is_a') {
#                  print "\t" . $go_annot_ext->get_column('annot_ext') . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext') . "\n\t";
#                  print "\t" . $go_annot_ext->get_column('cvtermprop_type') . "\t" . $go_annot_ext->get_column('cvtermprop_value') . "\n\t";
#                  print "\t" . $go_annot_ext->get_column('db_name') . "\n\t";
#                  print "\t" . $go_annot_ext->get_column('pub_id') . "\n\t";
                  $term_id = $go_annot_ext->get_column('db_name_ext') . ':' . $go_annot_ext->get_column('db_accession_ext');
                  $term_name = $go_annot_ext->get_column('term_name');
                  
#                  print "1\t" . $go_annot_ext->get_column('cvtermprop_value')
#                      . "\t" . $go_annot_ext->get_column('db_name')
#                      . "\t" . $go_annot_ext->get_column('cvtermprop_value')
#                      . "\t" . $go_annot_ext->get_column('term_name') . "\n";
                  
                  #print "WRONG IF STATEMENT\n";
                  
                  if (defined $go_annot_ext->get_column('cvtermprop_value') && $go_annot_ext->get_column('cvtermprop_value') ne 'created') {
                      my @cvtermprop_type = split(m/-/ms, $go_annot_ext->get_column('cvtermprop_type'));
                      
                      my $annot_ext_dbentry = q{};
                      if ($go_annot_ext->get_column('cvtermprop_value') =~ m/SP[ABCMNRS][CINPRT]/ms) {
                        $annot_ext_dbentry = $self->_get_PomBase_Gene_DBEntry(
                                    $go_annot_ext->get_column('cvtermprop_value')
                        );
                      } else {
                        $annot_ext_dbentry = Bio::EnsEMBL::DBEntry -> new (
                            -PRIMARY_ID  => $go_annot_ext->get_column('cvtermprop_value'),
                            -DBNAME      => $go_annot_ext->get_column('db_name'),
                            #-RELEASE     => 1,
                            #-VERSION     => 1,
                            -DISPLAY_ID  => $go_annot_ext->get_column('cvtermprop_value'), #$goterm_id,
                            -DESCRIPTION => $go_annot_ext->get_column('term_name'), #'annot_ext',
                            -INFO_TYPE   => 'DIRECT',
                        );
                      }
#                      print "\textension => " . $cvtermprop_type[1] . "\n";
#                      print "\tdbentry => " . $go_annot_ext->get_column('cvtermprop_value') . "\n";
                      
                      my @publist = split(m/:/ms, $go_annot_ext->get_column('pub_id'));
                      my $pub = $biodef->db_translate->{$publist[0]};
                      my $pub_id = $publist[1];
                      my $annot_ext_pub_dbentry = q{};
                      
                      if (defined $pub) {
                        #print $publist[0] . " : " . $pub . "\n";
                        if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                            $pub_id = $pub . ':' . $pub_id;
                        }
                        #print "\t\t", $pub, "\t", $pub_id, "\n";
                        $annot_ext_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                            -PRIMARY_ID  => $pub_id,
                            -DBNAME      => $pub,
                            #-RELEASE     => 'NULL',
                            #-VERSION     => 1,
                            -DISPLAY_ID  => $pub_id,
                            -DESCRIPTION => q{},
                            -INFO_TYPE   => 'DIRECT',
                        );
                      } else {
                        $annot_ext_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                            -PRIMARY_ID  => 'PMPB:0',
                            -DBNAME      => 'PUBMED_POMBASE',
                            #-RELEASE     => 'NULL',
                            #-VERSION     => 1,
                            -DISPLAY_ID  => 'Null',
                            -DESCRIPTION => q{},
                            -INFO_TYPE   => 'DIRECT',
                        );
                      }
                      
                      push @annot_ext, {'extension' => $cvtermprop_type[1],
                                        'dbentry'   => $annot_ext_dbentry,
                                        'pmid'      => $annot_ext_pub_dbentry,
                                        'group'     => $rs_term->feature_cvterm_id};
                  }
                  #print $goterm_id . "\n";
              } else {
                  #print $go_annot_ext->get_column('annot_ext') . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext') . "\n\t";
                  #print 'GOAE2:' . $self->feature_id.'_'.$rs_goterm->feature_cvterm_id.'_'.$feature_cvterm_count."\n\t";
#                  print "2\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext')
#                      . "\t" . $go_annot_ext->get_column('db_name_ext')
#                      . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext')
#                      . "\t" . $go_annot_ext->get_column('term_name') . "\n";
                  
                  my $annot_ext_dbentry = q{};
                  if ($go_annot_ext->get_column('db_accession_ext') =~ m/SP[ABCMNRS][CINPRT]/ms) {
                    $annot_ext_dbentry = $self->_get_PomBase_Gene_DBEntry(
                                $go_annot_ext->get_column('db_accession_ext')
                    );
                  } else {
                    $annot_ext_dbentry = Bio::EnsEMBL::DBEntry -> new (
                        -PRIMARY_ID  => $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext'),
                        -DBNAME      => $go_annot_ext->get_column('db_name_ext'),
                        #-RELEASE     => 1,
                        #-VERSION     => 1,
                        -DISPLAY_ID  => $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext'), #$goterm_id,
                        -DESCRIPTION => $go_annot_ext->get_column('term_name'), #'annot_ext',
                        -INFO_TYPE   => 'DIRECT',
                    );
                  }
#                  print "\textension2 => " . $go_annot_ext->get_column('annot_ext') . "\n";
#                  print "\tdbentry2 => " . $go_annot_ext->get_column('cvtermprop_value') . "\n";
                  
                  my @publist = split(m/:/ms, $go_annot_ext->get_column('pub_id'));
                  my $pub = $biodef->db_translate->{$publist[0]};
                  my $pub_id = $publist[1];
                  my $annot_ext_pub_dbentry = q{};
                  
                  if (defined $pub) {
                    #print $publist[0] . " : " . $pub . "\n";
                    if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                        $pub_id = $pub . ':' . $pub_id;
                    }
                    #print "\t\t", $pub, "\t", $pub_id, "\n";
                    $annot_ext_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                        -PRIMARY_ID  => $pub_id,
                        -DBNAME      => $pub,
                        #-RELEASE     => 'NULL',
                        #-VERSION     => 1,
                        -DISPLAY_ID  => $pub_id,
                        -DESCRIPTION => q{},
                        -INFO_TYPE   => 'DIRECT',
                    );
                  } else {
                    $annot_ext_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                        -PRIMARY_ID  => 'PMPB:0',
                        -DBNAME      => 'PUBMED_POMBASE',
                        #-RELEASE     => 'NULL',
                        #-VERSION     => 1,
                        -DISPLAY_ID  => 'Null',
                        -DESCRIPTION => q{},
                        -INFO_TYPE   => 'DIRECT',
                    );
                  }
                  push @annot_ext, {'extension' => $go_annot_ext->get_column('annot_ext'),
                                    'dbentry'   => $annot_ext_dbentry,
                                    'pmid'      => $annot_ext_pub_dbentry,
                                    'group'     => $rs_term->feature_cvterm_id};
              }
          }
          
        } else {
          #print "HERE 02\n";
          $ontology    = $rs_term->get_column('db_name');
          $accession   = $rs_term->get_column('db_accession');
          $description = $rs_term->get_column('name');
        }
        my $term_dbentry;
        
        #print $ontology.':'.$accession . "\t" . $rs_term->feature_cvterm_id ."\n";
        
        if ( defined $terms{$ontology.':'.$accession} ) {
            #print 'Got Term: ' . $ontology.':'.$accession . "\n";
            $term_dbentry = $terms{$ontology.':'.$accession};
        } else {
            $term_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                -PRIMARY_ID  => $ontology.':'.$accession,
                -DBNAME      => $ontology,
                #-RELEASE     => 'NULL',
                #-VERSION     => 1,
                #-DISPLAY_ID  => $rs_term->get_column('db_name').':'.$rs_term->get_column('db_accession'),
                -DISPLAY_ID  => $ontology . ':' . $accession,
                -DESCRIPTION => $description,
                -INFO_TYPE   => 'DIRECT',
                #-INFO_TEXT   => $rs_term->get_column('evidence_type') . ' ' . $rs_term->get_column('evidence'),
            );
        }
        #if ( $ontology.':'.$accession eq 'FYPO:0000648' ) {
        #  print Dumper $term_dbentry;
        #}
        
        
        #
        # Specify the evidence for the annotation
        # When the evidence coding has been agreed, the following code needs to
        # be changed as required
        # For the moment the evidence (often a date), is getting placed in the 
        # info_text column of the OntologyXref object.
        #
        my $evid_code = $self->_get_evidence_code($rs_term->get_column('evidence'));
        if (!defined $evid_code) {
            $evid_code = {evidence=>'NAS'};
        }
        
        
        #
        # Create a DBEntry for the publication
        #
        my $pub_dbentry = q{};
        if ( $rs_term->get_column('pubid') ne 'null' ) {
            #print $rs_term->get_column('pubid') . "\n";
            my @publist = split(m/:/ms, $rs_term->get_column('pubid'));
            my $pub = $biodef->db_translate->{$publist[0]};
            my $pub_id = $publist[1];
            # print $publist[0] . " : " . $pub . "\n";
            if (defined $pub) {
                if ($pub_id eq 0) {
                  $pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                      -PRIMARY_ID  => 'PMPB:' . $pub_id,
                      -DBNAME      => 'PUBMED_POMBASE',
                      #-RELEASE     => 'NULL',
                      #-VERSION     => 1,
                      -DISPLAY_ID  => $pub_id,
                      -DESCRIPTION => q{},
                      -INFO_TYPE   => 'DIRECT',
                  );
                } else {
                  if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                      $pub_id = $pub . ':' . $pub_id;
                  }
                  $pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                      -PRIMARY_ID  => $pub_id,
                      -DBNAME      => $pub,
                      #-RELEASE     => 'NULL',
                      #-VERSION     => 1,
                      -DISPLAY_ID  => $pub_id,
                      -DESCRIPTION => q{},
                      -INFO_TYPE   => 'DIRECT',
                  );
                }
            } else {
                warn 'Undefined Publication: ' . $rs_term->get_column('pubid') . "\n";
            }
        }
        
        #
        # Load the feature_cvtermprop as a qualifier with the respective
        # feature_cvterm_id
        #
        my @qualifiers = ();
        my %valid_types = map { $_ => 1 } ('allele', 'genotype', 'assigned_by', 'condition',
                                               'evidence', 'from', 'gene_product_form_id',
                                               'qualifier', 'residue', 'expression',
                                               'allele_type', 'description', 'viable', 'scale');
        if (
          defined $rs_term->get_column('evidence_type') and
          exists($valid_types{$rs_term->get_column('evidence_type')})
        ) {
#          print "\t" . $self->feature_id.'_'.$rs_term->get_column('feature_cvtermprop_id').'_'.$rs_term->feature_cvterm_id . "\t";
#          print "\t" . $rs_term->get_column('evidence_type') . "\t" . $rs_term->get_column('evidence') . "\n";
          my $qualifier_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $self->feature_id.'_'.$rs_term->get_column('feature_cvtermprop_id').'_'.$rs_term->feature_cvterm_id,
            -DBNAME      => $rs_term->get_column('db_name'),
            #-RELEASE     => 1,
            #-VERSION     => 1,
            -DISPLAY_ID  => $rs_term->get_column('evidence'),
            -DESCRIPTION => $rs_term->get_column('evidence_type'),
            -INFO_TYPE   => 'DIRECT',
          );
          push @qualifiers, { 'dbentry'   => $qualifier_dbentry,
                              'extension' => $rs_term->get_column('evidence_type'),
                              'pmid'      => $pub_dbentry,
                              'group'     => $rs_term->feature_cvterm_id};
        }
        
        my %quant_types = map { $_ => 1 } ('quant_gene_ex_avg_copies_per_cell',
                                           'quant_gene_ex_cell_distribution');
        if (
          defined $rs_term->get_column('evidence_type') and
          exists($quant_types{$rs_term->get_column('evidence_type')})
        ) {
          my $pseudoprimary_id = 'PBO:2100001';
          if ( $rs_term->get_column('evidence_type') eq 'quant_gene_ex_cell_distribution' ) {
            $pseudoprimary_id = 'PBO:2100002';
          }
          
          my $qualifier_dbentry = Bio::EnsEMBL::DBEntry -> new (
            -PRIMARY_ID  => $pseudoprimary_id,
            -DBNAME      => $rs_term->get_column('db_name'),
            #-RELEASE     => 1,
            #-VERSION     => 1,
            -DISPLAY_ID  => $pseudoprimary_id,
            -DESCRIPTION => $rs_term->get_column('evidence_type'),
            -INFO_TYPE   => 'DIRECT',
          );
          push @qualifiers, { 'dbentry'   => $qualifier_dbentry,
                              'extension' => $rs_term->get_column('evidence'),
                              'pmid'      => $pub_dbentry,
                              'group'     => $rs_term->feature_cvterm_id};
        }
        
        
        #if ($rs_term->get_column('db_name') eq 'FYPO' ) {
        #my $allele_dbentry = q{};
        if ($ontology eq 'FYPO' ) {
          
#          print $ontology . ':' . $accession . "\t";
#          print "FYPO Genotype: " . $rs_term->feature_cvterm_id . "\t"
#              . $rs_term->get_column('feature_uniquename'). "\t"
#              . $rs_term->get_column('feature_name') . "\n";
#          
#          print "\t Genotypes: | " . ref($genotypes) . "\n";
#          print "\t Allele Count: " . $alleles->number_of_alleles . "\n";
          
          if ( ref($genotypes) eq 'PomLoader::Genotypes' ) {
              my %g = %{$genotypes->genotypes()};
              foreach my $allele_id ( keys $g{$rs_term->get_column('feature_id')}->{'alleles'} ) { 
                  my %a = %{$g{$rs_term->get_column('feature_id')}->{'alleles'}->{$allele_id}};
		          
		          my $allele_uniquename    = $a{'uniquename'};
		          my $allele_name          = $a{'name'};
		          my $allele_description   = $a{'description'};
		          my $allele_type          = $a{'allele_type'};
		          my $allele_expression;
		          if ( defined $a{'expression'} ) {
		          	$allele_expression     = $a{'expression'};
                  } else {
                  	$allele_expression     = '';
                  }
                  if ( defined $allele_type and $allele_type eq 'deletion' ) {
                  	$allele_expression     = 'Null';
                  }
		          my $allele_expression_id = $allele_expression =~ s/\ /_/r; 
		          
		          my $allele_dbentry = Bio::EnsEMBL::DBEntry -> new (
		              -PRIMARY_ID  => $allele_uniquename,
		              #-PRIMARY_ID  => $rs_term->get_column('qualifier'),
		              -DBNAME      => $rs_term->get_column('db_name'),
		              #-RELEASE     => 'NULL',
		              #-VERSION     => 1,
		              -DISPLAY_ID  => $allele_name,
		              -DESCRIPTION => $allele_description,
		              -INFO_TYPE   => 'DIRECT',
		              -INFO_TEXT   => $allele_type,
		          );
		          push @qualifiers, { 'dbentry'   => $allele_dbentry,
		                              'extension' => 'allele',
		                              'pmid'      => $pub_dbentry,
		                              'group'     => $rs_term->feature_cvterm_id};
                  
                  my $qualifier_dbentry = Bio::EnsEMBL::DBEntry -> new (
                    -PRIMARY_ID  => $allele_uniquename . '_' . $allele_expression_id,
                    #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
                    -DBNAME      => $rs_term->get_column('db_name'),
                    #-RELEASE     => 1,
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $allele_expression,
                    -DESCRIPTION => $allele_expression,
                    #-INFO_TEXT   => $info_text,
                    -INFO_TYPE   => 'DIRECT',
                  );
                  push @qualifiers, {
                  	'dbentry'   => $qualifier_dbentry,
                  	'extension' => 'expression',
                  	'pmid'      => $pub_dbentry,
                  	'group'     => $rs_term->feature_cvterm_id
                  };
              }
          }
        }
        #}
        #
        # Get the Ontology term types.
        #
        my $rs_qualifiers = $self->dba_chado->resultset('Sequence::FeatureCvterm')
                  ->search(
                      {'me.feature_cvterm_id' => $rs_term->feature_cvterm_id},
                      {join => [{'cvterm' => [{'dbxref' => 'db'}, 'cv']},
                                {'feature_cvtermprops' => 'type'},
                                'pub',
                                {'feature' => {'featureprops' => 'type'}}],
                          '+select' => [
                              'cvterm.dbxref_id',
                              'db.name',
                              'dbxref.accession',
                              'cvterm.name',
                              'cvterm.definition',
                              'feature_cvtermprops.feature_cvtermprop_id',
                              'feature_cvtermprops.value',
                              'pub.uniquename',
                              'type.name',
                              'feature.feature_id',
                              'feature.uniquename',
                              'feature.name',
                              'type_2.name',
                              'featureprops.value'],
                          '+as' => ['dbxref', 'db_name', 'db_accession','name', 
                                    'definition', 'feature_cvtermprop_id', 
                                    'qualifier', 'pubid', 'cvtermprop_type',
                                    'feature_id', 'feature_uniquename',
                                    'feature_name', 'featureprop_type', 'featureprop_value'],
                          'where' => {'cv.name' => {'in' => ['name_description',
                                                         'complementation',
                                                         'sequence_feature',
                                                         'sequence',
                                                         'DNA_binding_specificity',
                                                         'disease_associated',
                                                         'subunit_composition',
                                                         'ex_tools',
                                                         'gene_ex',
                                                         'genome_org',
                                                         'species_dist',
                                                         'PSI-MOD',
                                                         'fission_yeast_phenotype',
                                                         'misc',
                                                         'warning',
                                                         'pathway',
                                                         'RILEY',
                                                         'external_link',
                                                         'cat_act',
                                                         'm_f_g',
                                                         'protein_family',
                                                         'PomBase family or domain',
                                                         'PomBase gene characterisation status',]},
                               'type.name' => ['genotype', 'assigned_by', 'condition',
                                               'evidence', 'from', 'gene_product_form_id',
                                               'qualifier', 'residue', 'expression']
                       },
                      });
        #my @qualifiers = ();
        #my @qualifiers_extension  = ();
        #print "\t" . $rs_term->feature_cvterm_id . "\n";
        my $first_associated_xref = 1;
        while ( my $rs_qualifier = $rs_qualifiers->next ) {
#            print "Loading Qualifier\n";
            my $info_text = '';
            if ( defined $rs_qualifier->get_column('cvtermprop_type') ) {
              $info_text = $rs_qualifier->get_column('cvtermprop_type') . ' ' . $rs_qualifier->get_column('qualifier');
            } elsif ( defined $rs_qualifier->get_column('featureprop_value') ) {
                $info_text = $rs_qualifier->get_column('featureprop_value');
            }
            
#            if ($ontology.':'.$accession eq 'FYPO:0000124') {
#              print "\tprimary_id: " . $self->feature_id.'_'.$rs_qualifier->get_column('feature_cvtermprop_id').'_'.$rs_term->feature_cvterm_id . "\n";
#              print "\t" . $rs_qualifier->get_column('cvtermprop_type') . "\t". $rs_qualifier->get_column('qualifier') . "\n";
#              print "\t" . $rs_qualifier->get_column('featureprop_type') . "\t". $rs_qualifier->get_column('featureprop_value') . "\n";
#              print "\t" . $info_text . "\n";
#              print "\t" . $rs_term->get_column('evidence') . "\n\n";
#            }
            my $qualifier_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $self->feature_id.'_'.$rs_qualifier->get_column('feature_cvtermprop_id').'_'.$rs_term->feature_cvterm_id,
                #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
                -DBNAME      => $rs_qualifier->get_column('db_name'),
                #-RELEASE     => 1,
                #-VERSION     => 1,
                -DISPLAY_ID  => $rs_qualifier->get_column('qualifier'),
                -DESCRIPTION => $rs_qualifier->get_column('cvtermprop_type'),
                -INFO_TEXT   => $info_text,
                -INFO_TYPE   => 'DIRECT',
            );
            
            my @publist = split(m/:/ms, $rs_qualifier->get_column('pubid'));
            my $pub = $biodef->db_translate->{$publist[0]};
            my $pub_id = $publist[1];
            my $qualifier_pub_dbentry = q{};
            
            if (defined $pub) {
              #print $publist[0] . " : " . $pub . "\n";
              
              if ($pub_id eq 0) {
                $qualifier_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                    -PRIMARY_ID  => 'PMPB:' . $pub_id,
                    -DBNAME      => 'PUBMED_POMBASE',
                    #-RELEASE     => 'NULL',
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $pub_id,
                    -DESCRIPTION => q{},
                    -INFO_TYPE   => 'DIRECT',
                );
              } else {
                if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                    $pub_id = $pub . ':' . $pub_id;
                }
                #print "\t\t", $pub, "\t", $pub_id, "\n";
                $qualifier_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                    -PRIMARY_ID  => $pub_id,
                    -DBNAME      => $pub,
                    #-RELEASE     => 'NULL',
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $pub_id,
                    -DESCRIPTION => q{},
                    -INFO_TYPE   => 'DIRECT',
                );
              }
              
              if ($rs_qualifier->get_column('db_name') eq 'FYPO' and $first_associated_xref) {
              #if ($ontology eq 'FYPO' and $first_associated_xref) {
                
                if ( ref($genotypes) eq 'PomLoader::Genotypes' ) {
                  my %g = %{$genotypes->genotypes()};
               
                  foreach my $allele_id ( keys $g{$rs_qualifier->get_column('feature_id')}->{'alleles'} ) { 
                    my %a = %{$g{$rs_qualifier->get_column('feature_id')}->{'alleles'}->{$allele_id}};
                    my $allele_dbentry = Bio::EnsEMBL::DBEntry -> new (
	                    -PRIMARY_ID  => $a{'uniquename'},
	                    #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
	                    -DBNAME      => $rs_qualifier->get_column('db_name'),
	                    #-RELEASE     => 1,
	                    #-VERSION     => 1,
	                    -DISPLAY_ID  => $a{'name'},
	                    -DESCRIPTION => $a{'description'},
	                    -INFO_TYPE   => 'DIRECT',
	                    -INFO_TEXT   => $a{'allele_type'}
	                );
	                push @qualifiers, { 'dbentry'   => $allele_dbentry,
	                                    'extension' => 'allele',
	                                    'pmid'      => $qualifier_pub_dbentry,
	                                    'group'     => $rs_term->feature_cvterm_id};
                  }
                }
              }
                
#                my $allele_description = '';
#                if (ref($alleles) eq 'PomBase::Alleles') {
#                  my %a = %{$alleles->alleles()};
#                  $allele_description = $a{$rs_term->get_column('feature_id')}->{'allele_type'} . ' '
#                                      . $a{$rs_term->get_column('feature_id')}->{'value'};
#                }
#                print $allele_description;
##                print $ontology . ':' . $accession . "\t";
##                print "FYPO Allele 1: " . $rs_qualifier->get_column('feature_uniquename') . $a{$rs_qualifier->get_column('feature_id')}->{'value'} . "\n";
#                my $allele_dbentry = Bio::EnsEMBL::DBEntry -> new (
#                    -PRIMARY_ID  => $rs_qualifier->get_column('feature_uniquename'),
#                    #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
#                    -DBNAME      => $rs_qualifier->get_column('db_name'),
#                    #-RELEASE     => 1,
#                    -VERSION     => 1,
#                    -DISPLAY_ID  => $rs_qualifier->get_column('feature_name') || $rs_qualifier->get_column('feature_uniquename'),
#                    -DESCRIPTION => $allele_description,
#                    -INFO_TYPE   => 'DIRECT',
#                );
#                push @qualifiers, { 'dbentry'   => $allele_dbentry,
#                                    'extension' => 'allele',
#                                    'pmid'      => $qualifier_pub_dbentry,
#                                    'group'     => $rs_term->feature_cvterm_id};
#              }
#            
#              push @qualifiers, { 'dbentry'   => $qualifier_dbentry,
#                                  'extension' => $rs_qualifier->get_column('cvtermprop_type'),
#                                  'pmid'      => $qualifier_pub_dbentry,
#                                  'group'     => $rs_term->feature_cvterm_id};
            } else {
              #print "In Here\n";
              $qualifier_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                  -PRIMARY_ID  => 'PMPB:0',
                  -DBNAME      => 'PUBMED_POMBASE',
                  #-RELEASE     => 'NULL',
                  #-VERSION     => 1,
                  -DISPLAY_ID  => 'PMPB:0',
                  -DESCRIPTION => q{},
                  -INFO_TYPE   => 'DIRECT',
              );
#              if ($rs_qualifier->get_column('db_name') eq 'FYPO' and $first_associated_xref) {
#              #if ($ontology eq 'FYPO' and $first_associated_xref) {
#                my %a = %{$alleles->alleles()};
#                #print "FYPO Allele 2: " . $a{$rs_qualifier->get_column('feature_id')}->{'value'} . "\n";
#                my $allele_dbentry = Bio::EnsEMBL::DBEntry -> new (
#                    -PRIMARY_ID  => $rs_qualifier->get_column('feature_uniquename'),
#                    #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
#                    -DBNAME      => $rs_qualifier->get_column('db_name'),
#                    #-RELEASE     => 1,
#                    -VERSION     => 1,
#                    -DISPLAY_ID  => $rs_qualifier->get_column('feature_name') || $rs_qualifier->get_column('feature_uniquename'),
#                    -DESCRIPTION => $a{$rs_qualifier->get_column('feature_id')}->{'value'},
#                    -INFO_TYPE   => 'DIRECT',
#                );
#                
#                push @qualifiers, { 'dbentry'   => $allele_dbentry,
#                                    'extension' => 'allele',
#                                    'pmid'      => $qualifier_pub_dbentry,
#                                    'group'     => $rs_term->feature_cvterm_id};
#              }
              
              if ( $rs_qualifier->get_column('db_name') eq 'FYPO' and $first_associated_xref ) {
                  my %g = %{$genotypes->genotypes()};
               
                  foreach my $allele_id ( keys $g{$rs_qualifier->get_column('feature_id')}->{'alleles'} ) { 
                    my %a = %{$g{$rs_qualifier->get_column('feature_id')}->{'alleles'}->{$allele_id}};
                    my $allele_dbentry = Bio::EnsEMBL::DBEntry -> new (
	                    -PRIMARY_ID  => $a{'uniquename'},
	                    #-PRIMARY_ID  => $rs_qualifier->get_column('qualifier'),
	                    -DBNAME      => $rs_qualifier->get_column('db_name'),
	                    #-RELEASE     => 1,
	                    #-VERSION     => 1,
	                    -DISPLAY_ID  => $a{'name'},
	                    -DESCRIPTION => $a{'description'},
	                    -INFO_TYPE   => 'DIRECT',
	                    -INFO_TEXT   => $a{'allele_type'}
	                );
	                push @qualifiers, { 'dbentry'   => $allele_dbentry,
	                                    'extension' => 'allele',
	                                    'pmid'      => $qualifier_pub_dbentry,
	                                    'group'     => $rs_term->feature_cvterm_id};
                  }
                }
              
              push @qualifiers, { 'dbentry'   => $qualifier_dbentry,
                                  'extension' => $rs_qualifier->get_column('cvtermprop_type'),
                                  'pmid'      => $qualifier_pub_dbentry,
                                  'group'     => $rs_term->feature_cvterm_id};
              #print $qualifier_pub_dbentry->primary_id . "\n";
            }
            $first_associated_xref = 0;
        }
        #print "\n";
        undef($rs_qualifiers);
        
        
        #
        # Link the Pub DBEntry term to the Ontology Term
        #
        #print "\t" . $evid_code->{'evidence'} . "\n";
        if ( defined $evid_code) {
            #print "\tAdding Evidence Code\n";
            if ( $pub_dbentry eq q{} ) {
                $term_dbentry->add_linkage_type(
                    $evid_code->{'evidence'});
            } else {
                $term_dbentry->add_linkage_type(
                    $evid_code->{'evidence'},
                    $pub_dbentry);
            }
            
#            foreach my $qualifier ( @qualifiers ) {
#                if ($qualifier ne q{}) {
#                    #print "Added Qualifier\n";
#                    #print "\t" . $qualifier->primary_id . "\t" . $qualifier->description . "\t";
#                    $term_dbentry->add_linkage_type(
#                        $evid_code->{'evidence'},
#                        $qualifier);
#                }
#            }
            #print Data::Dumper->Dump([$pub_dbentry]) . "\n";
            
            my $rank = 0;
            foreach my $qualifier ( @qualifiers ) {
                if ($qualifier ne q{}) {
#                	if ($term_dbentry->primary_id eq 'FYPO:0000650') {
#                      print "Added Qualifier\n";
#                      print "\tDBEntry:   " . $qualifier->{'dbentry'}->primary_id . "\t" . $qualifier->{'dbentry'}->display_id . "\t" . $qualifier->{'dbentry'}->dbname . "\n";
#                      print "\tCondition: " . $qualifier->{'extension'} . "\n";
#                      #print Data::Dumper->Dump([$qualifier->{'pmid'}]);
#                      print "\tSource:    " . $qualifier->{'pmid'}->primary_id . "\t" . $qualifier->{'pmid'}->description . "\n";
#                      print "\tGroup:     " . $qualifier->{'group'} . " : " . $rank . "\n";
#                    }
                    my $pmid = $qualifier->{'pmid'};
                    if ($pmid ne '') {
                      $term_dbentry->add_linked_associated_xref(
                          $qualifier->{'dbentry'},
                          $pmid,
                          $qualifier->{'extension'},
                          $qualifier->{'group'},
                          $rank);
                    } else {
                      $pmid = Bio::EnsEMBL::DBEntry -> new (
                          -PRIMARY_ID  => 'PMPB:0',
                          -DBNAME      => 'PUBMED_POMBASE',
                          #-RELEASE     => 'NULL',
                          #-VERSION     => 1,
                          -DISPLAY_ID  => 'PMPB:0',
                          -DESCRIPTION => q{},
                          -INFO_TYPE   => 'DIRECT',
                      );
                      $term_dbentry->add_linked_associated_xref(
                          $qualifier->{'dbentry'},
                          $pmid,
                          $qualifier->{'extension'},
                          $qualifier->{'group'},
                          $rank);
                    }
                }
                $rank++;
            }
            
            $rank = 0;
            foreach my $ax ( @annot_ext ) {
                if ($ax ne q{}) {
#                    if ($term_dbentry->primary_id eq 'FYPO:0000255') {
#                      print 'Added Qualifier to ' . $term_dbentry->primary_id . "\n";
#                      print "\tDBEntry:   " . $ax->{'dbentry'}->primary_id . "\t" . $ax->{'dbentry'}->display_id . "\n";
#                      print "\tCondition: " . $ax->{'extension'} . "\n";
#                      #print Data::Dumper->Dump([$ax->{'pmid'}]);
#                      print "\tSource:    " . $ax->{'pmid'}->primary_id . "\t" . $ax->{'pmid'}->description . "\n";
#                      print "\tGroup:     " . $ax->{'group'} . " : " . $rank . "\n";
#                    }
                    $term_dbentry->add_linked_associated_xref(
                        $ax->{'dbentry'},
                        $ax->{'pmid'},
                        $ax->{'extension'},
                        $ax->{'group'},
                        $rank);
                }
                $rank++;
            }
        }
        
        
        #print "Adding term: " . $term_dbentry->primary_id . "\n";
        $terms{$ontology.':'.$accession} = $term_dbentry;
        #print "Done\n\n";
    }
    undef($rs);
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};

    return \%terms;
}


sub _get_evidence_code {
    my ( $self, $evid ) = @_;

    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    #print 'evidence: ' . $evid . "\n";
    if ( !defined $evid ) {
    	return undef;
    }
    my $biodef = $self->dbparams->{'biodef'};
    $evid = lc $evid;
    my $valid = 0;
    my %evidence = ();
    #foreach my $x ( keys %{ $biodef->go } ) {
    #    print "\t$x";
    #}
    #print "\n";
    my $finalfullid = q{};
    #print "\t$evid\n";
    foreach my $fullid ( keys %{ $biodef->go } ) {
        #print "\t\t$fullid: ";
        if ( index($evid, $fullid) >= 0 ) {
            $evidence{'evidence'} = $biodef->go->{$fullid};
            $valid = 1;
            $finalfullid = $fullid;
            #print "MATCH\n";
            last;
        } elsif ( index($biodef->go->{$fullid}, uc $evid) >= 0 ) {
            $evidence{'evidence'} = $biodef->go->{$fullid};
            $valid = 1;
            $finalfullid = $fullid;
            #print "MATCH\n";
            last;
        }
        #print "FAILED\n";
    }
    #print length($evidence{'evidence'}), "\t", $evidence{'evidence'}, "\n";
    if ( (index($evid, 'with', length($finalfullid) ) >= 0 or index($evid, 'from', length($finalfullid)) >= 0) and $valid==1 ) {
        my @evidlist = q{};
        if (index($evid, 'with', length($evidence{'evidence'})) >= 0) {
            $evidence{'association'} = 'with';
            @evidlist = split(m/with/ms, $evid);
        } else {
            $evidence{'association'} = 'from';
            @evidlist = split(m/from/ms, $evid);
        }
        #foreach my $e (@evidlist) {
        #    print "\t", $e;
        #}
        #print "\n";
        my @source = split(m/:/ms, $evidlist[-1]);
        $evidence{'source'} = $source[0];
        $evidence{'source_id'} = $source[1];
        #print "\t" . $source[0] . ':' . $source[1] . "\n";
        
        return \%evidence;
    } elsif ($valid == 1) {
        return \%evidence;
    }
    return undef;
}


#
# Get the DBEntry for a PomBase gene when loading the annotation extensions so 
# that it is identical the normal gene name making it easier for db population 
#
sub _get_PomBase_Gene_DBEntry {
    my ( $self, $uniquename ) = @_;
    #print "_get_PomBase_Gene_DBEntry for: " . $uniquename . "\n";
    my $rs = $self->dba_chado->resultset('Sequence::Feature')
                  ->search(
                    {'me.uniquename' => $uniquename},
                    {select => ['me.name', 'me.uniquename'],
                     join => ['type'],
                      'where' => {'type.name' => ['gene']}
                    }
                  );
    #print "----------\n";
    my $gene_dbentry = q{};
    #while ( my $rs_gene = $rs->next ) {
      my $rs_gene = $rs->next;
#      my $d = Data::Dumper->new([$rs_gene]);
#      print $d->Dump();
      my $gene_name = $rs_gene->{'name'};
      my $gene_name_dbname = 'PomBase_Gene_Name';
      if ( !defined($gene_name) or $gene_name eq '' ) {
          $gene_name = $uniquename;
          $gene_name_dbname = 'PomBase_Systematic_ID';
      }
      #print "\t" . $uniquename . " | " . $rs_gene->{'uniquename'} . "\n";
      $gene_dbentry = Bio::EnsEMBL::DBEntry -> new (
          -PRIMARY_ID  => $uniquename,
          -DBNAME      => $gene_name_dbname, #$self->dbparams->{'dbname'}.'_GENE',
          #-RELEASE     => 1,
          #-VERSION     => 1,
          -DISPLAY_ID  => $gene_name,
          -DESCRIPTION => $uniquename,
          -INFO_TYPE   => 'DIRECT',
      );
    #}
    undef($rs);
    #print "\tGene: " . $gene_dbentry->display_id . " (" . $gene_dbentry->primary_id . ")\n";
    return $gene_dbentry;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::OntologyTerms - Builds ontology term objects with their associated
                           publications.

=head1 DESCRIPTION

Module to build Bio::EnsEMBL::OntologyXref objects.   It also populates the 
Ontology term objects with their related publications.

=head1 REQUIREMENTS

=over 12

=item
Perl 5.10

=item
Moose

=item
EnsEMBL API Release v61

=item
Bio::Chado::Schema

=back

=head1 EXAMPLE

my $terms = PomLoader::OntologyTerms->new(
                       'dba_chado'     => $dba_chado,
                       'feature_id' => $feature_id,
                   );

my %termlist = %{$terms->ontologyterms()};

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut
