package PomLoader::GOTerms;

use Moose;

use Bio::EnsEMBL::DBEntry;
use Bio::EnsEMBL::OntologyXref;
use Data::Dumper;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1, weak_ref => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1, weak_ref => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1, weak_ref => 1);

has 'goterms'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_goterms');


sub _generate_goterms {
    my $self = shift;
    my %goterms = ();
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

    #
    # Get all the GO terms of the translation.
    #
    my $rs = $self->dba_chado->resultset('Sequence::FeatureCvterm')
              ->search(
                  {'me.feature_id' => $self->feature_id},
                  {join => [{'cvterm' => [{'dbxref' => 'db'}, 'cv']},
                            {'feature_cvtermprops' => 'type'},
                            'pub'],
                      '+select' => [
                          'me.is_not',
                          'cvterm.dbxref_id',
                          'db.name',
                          'dbxref.accession',
                          'cvterm.name',
                          'cvterm.definition',
                          'feature_cvtermprops.value',
                          'pub.uniquename'],
                      '+as' => ['not', 'dbxref', 'db_name', 'db_accession', 'name', 'definition', 'evidence', 'pubid'],
                      'where' => {'cv.name' => {'in' => ['biological_process',
                                                         'molecular_function',
                                                         'cellular_component',
                                                         'PomBase annotation extension terms']},
                           'type.name' => ['evidence'],
                           # 'pub.type_id' => {'not in' => ['1']}
                   },
                  });
    while ( my $rs_goterm = $rs->next ) {
        
        #print $rs_goterm->get_column('db_name') . "\t" . $rs_goterm->get_column('name') . "\t" . $rs_goterm->feature_cvterm_id . "\n";
        
        #
        # Required to identify whether this is a GO annotation extension term
        # or a normal GO term.   If it is an annotation extension then the name
        # has to be handled differently, otherwise everything is the same.
        #
        my $annotation_extension = 0;
        my @annot_ext = ();
        my $goterm_name;
        my $goterm_id;
        my $goterm_feature_cvterm_id;
        #print $rs_goterm->get_column('db_name') . "\n";
        if ( $rs_goterm->get_column('db_name') eq 'PBO' ) {
            $annotation_extension = 1;
            my @extensions = split m/\s*\[\w*\]\s*/ms, $rs_goterm->get_column('name');
            #my $d = Data::Dumper->new(\@extensions);
            #print $d->Dump();
            #print "I'm in - " . $rs_goterm->feature_cvterm_id . "\n\t";
            $goterm_feature_cvterm_id = $rs_goterm->feature_cvterm_id;

            my $rs_annot_ext = $self->dba_chado->resultset('Sequence::FeatureCvterm')
                      ->search(
                          {'me.feature_cvterm_id' => $rs_goterm->feature_cvterm_id},
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
                              #'where' => {'cv_2.name' => {'in' => ['biological_process',
                              #                                     'molecular_function',
                              #                                     'cellular_component']
                              #                           }
                              #},
                          });

            my $feature_cvterm_count = 0;
            my $current_cvterm_id = 0;
            while ( my $go_annot_ext = $rs_annot_ext->next ) {
                #print "\t" . $go_annot_ext->get_column('pub_id') . "\n\t";
                if ( $go_annot_ext->get_column('annot_ext') eq 'is_a' and $go_annot_ext->get_column('db_name_ext') eq 'GO' ) {
                    #print "\t" . $go_annot_ext->get_column('annot_ext') . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext') . "\n\t";
                    #print "\t" . $go_annot_ext->get_column('cvtermprop_type') . "\t" . $go_annot_ext->get_column('cvtermprop_value') . "\n\t";
                    #print "\t" . $go_annot_ext->get_column('db_name') . "\n\t";
                    #print "\t" . $go_annot_ext->get_column('pub_id') . "\n\t";
                    $current_cvterm_id = $go_annot_ext->get_column('db_name') . ':' . $go_annot_ext->get_column('db_accession');
                    $goterm_id = $go_annot_ext->get_column('db_name_ext') . ':' . $go_annot_ext->get_column('db_accession_ext');
                    $goterm_name = $go_annot_ext->get_column('term_name');
                    
#                    print "1\t" . $go_annot_ext->get_column('cvtermprop_value')
#                        . "\t" . $go_annot_ext->get_column('db_name')
#                        . "\t" . $go_annot_ext->get_column('cvtermprop_value')
#                        . "\t" . $go_annot_ext->get_column('term_name') . "\n";
                    
                    #print "WRONG IF STATEMENT\n";
                    
                    if (defined $go_annot_ext->get_column('cvtermprop_value')) {
                        my @cvtermprop_type = split(m/-/ms, $go_annot_ext->get_column('cvtermprop_type'));
                        
                        my @cvtermprop_value = split(m/:/ms, $go_annot_ext->get_column('cvtermprop_value'));
                        
                        my $annot_ext_dbentry = q{};
                        if (
                          $go_annot_ext->get_column('db_name') eq 'PBO' and
                          $go_annot_ext->get_column('cvtermprop_value') =~ m/SP[ABCMNRS][CINPRT]/ms
                        ) {
                          $annot_ext_dbentry = $self->_get_PomBase_Gene_DBEntry(
                                      $go_annot_ext->get_column('cvtermprop_value')
                          );
                        } elsif ( scalar(@cvtermprop_value) == 2 ) {
                          $annot_ext_dbentry = Bio::EnsEMBL::DBEntry -> new (
                              -PRIMARY_ID  => $cvtermprop_value[1],
                              -DBNAME      => $cvtermprop_value[0],
                              #-RELEASE     => 1,
                              #-VERSION     => 1,
                              -DISPLAY_ID  => $go_annot_ext->get_column('cvtermprop_value'), #$goterm_id,
                              -DESCRIPTION => $go_annot_ext->get_column('term_name'), #'annot_ext',
                              -INFO_TYPE   => 'DIRECT',
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
                        $feature_cvterm_count += 1;
                        #print "\textension => " . $cvtermprop_type[1] . "\n\t";
                        #print "\tdbentry => " . $go_annot_ext->get_column('cvtermprop_value') . "\n\t";
                        if ( $go_annot_ext->get_column('cvtermprop_value') =~ m/\^/ms ) {
                          print "========== Extension Not Loaded ==========\n";
                          print "feature_cvterm_id: " . $rs_goterm->feature_cvterm_id . "\n";
                          print "GO Term:           " . $goterm_id . "\n";
                          print "Extension:         " . $cvtermprop_type[1] . "\n";
                          print "DBEntry:           " . $go_annot_ext->get_column('cvtermprop_value') . "\n";
                          print "==========================================\n";
                        } else {
                          push @annot_ext, {'extension' => $cvtermprop_type[1],
                                            'dbentry'   => $annot_ext_dbentry,
                                            'pmid'      => $rs_goterm->get_column('pubid'),
                                            'group'     => $rs_goterm->feature_cvterm_id};
                        }
                    }
                    #print $goterm_id . "\n";
                } else {
                    #print $go_annot_ext->get_column('annot_ext') . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext') . "\n\t";
                    #print 'GOAE2:' . $self->feature_id.'_'.$rs_goterm->feature_cvterm_id.'_'.$feature_cvterm_count."\n\t";
#                    print "2\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext')
#                        . "\t" . $go_annot_ext->get_column('db_name_ext')
#                        . "\t" . $go_annot_ext->get_column('db_name_ext').':'.$go_annot_ext->get_column('db_accession_ext')
#                        . "\t" . $go_annot_ext->get_column('term_name') . "\n";
                    my $row_cvterm_id = $go_annot_ext->get_column('db_name').':'.$go_annot_ext->get_column('db_accession');
                    if ( $current_cvterm_id eq $row_cvterm_id ) {
	                    my $annot_ext_dbentry = q{};
	                    if (
	                      $go_annot_ext->get_column('db_name_ext') eq 'PomBase' ||
	                      $go_annot_ext->get_column('db_accession_ext') =~ m/SP[ABCMNRS][CINPRT]/ms
	                    ) {
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
	                    $feature_cvterm_count += 1;
	                    #print "\textension2 => " . $go_annot_ext->get_column('annot_ext') . "\n\t";
	                    #print "\tdbentry2 => " . $go_annot_ext->get_column('cvtermprop_value') . "\n\t";
	                    push @annot_ext, {'extension' => $go_annot_ext->get_column('annot_ext'),
	                                      'dbentry'   => $annot_ext_dbentry,
	                                      'pmid'      => $rs_goterm->get_column('pubid'),
	                                      'group'     => $rs_goterm->feature_cvterm_id};
                    }
                }
            }
            undef($rs_annot_ext);
            #print "Done\n";
            
#            my $go_annot_ext = $rs_annot_ext->next();
#            if ( defined $go_annot_ext->get_column('db_name') ) {
#                $goterm_id = $go_annot_ext->get_column('db_name') . ':' . $go_annot_ext->get_column('db_accession');
#            }
#            $goterm_name = $extensions[0];
        } else {
            $goterm_id = $rs_goterm->get_column('db_name') . ':' . $rs_goterm->get_column('db_accession');
            $goterm_name = $rs_goterm->get_column('name');
            $goterm_feature_cvterm_id = $rs_goterm->feature_cvterm_id;
        }
        #print $goterm_id . "\t" . $goterm_name . "\n";
        #print $annotation_extension . "\t";
        #print "\t" . $rs_goterm->get_column('db_name') . ':' . $rs_goterm->get_column('db_accession') . "\t" . $rs_goterm->get_column('pubid') . "\t" . $rs_goterm->get_column('evidence') . "\n";
        
        
        #
        # Create the OntologyXref object
        #
#        foreach my $key (keys %goterms) {
#            print $key . "\t";
#        }
#        print "\n";
        my $goterm_dbentry = q{};
        if ( (%goterms) and ($goterm_id) and ($goterms{$goterm_id}) ) {
            #print 'GO:' . $rs_goterm->get_column('db_accession') . "\n";
            #print "Already Have GO term!\n";
            #print 'GO:' . $rs_goterm->get_column('db_accession') . "\t" . $rs_goterm->get_column('not') . "\n";
            $goterm_dbentry = $goterms{$goterm_id};
        } else {
            #print 'GO:' . $rs_goterm->get_column('db_accession') . "\t" . $rs_goterm->get_column('not') . "\n";
            if ($rs_goterm->get_column('not') == 1) {
                $goterm_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                    -PRIMARY_ID  => $goterm_id,
                    -DBNAME      => 'GO',
                    #-RELEASE     => 'NULL',
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $goterm_id,
                    -DESCRIPTION => $goterm_name,
                    -LINKAGE_ANNOTATION => 'NOT',
                    -INFO_TYPE   => 'DIRECT',
                );
            } else {
                $goterm_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                    -PRIMARY_ID  => $goterm_id,
                    -DBNAME      => 'GO',
                    #-RELEASE     => 'NULL',
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $goterm_id,
                    -DESCRIPTION => $goterm_name,
                    -INFO_TYPE   => 'DIRECT',
                );
            }
        }
        
        #print $goterm_name . "\n";
        
        
        #
        # Specify the evidence for the annotation
        #
        my $evid_code = $self->_get_evidence_code($rs_goterm->get_column('evidence'));
#        my $evid_code_dbentry = Bio::EnsEMBL::DBEntry -> new (
#            -PRIMARY_ID  => $self->feature_id.'_'.$goterm_dbentry->get_column('feature_cvtermprop_id').'_'.$rs_goterm->feature_cvterm_id,
#            -DBNAME      => $go_annot_ext->get_column('db_name'),
#            #-RELEASE     => 1,
#            -VERSION     => 1,
#            -DISPLAY_ID  => $go_annot_ext->get_column('cvtermprop_value'), #$goterm_id,
#            -DESCRIPTION => $go_annot_ext->get_column('term_name'), #'annot_ext',
#            -INFO_TYPE   => 'DIRECT',
#        );
        
        #print "\t" . $evid_code->{'evidence'} . "\n";
        #print (Dumper $evid_code) . "\n";
        
        
        #
        # Create a DBEntry for the publication
        #
        my $pub_dbentry = q{};
        if ( $rs_goterm->get_column('pubid') ne 'null' ) {
            my @publist = split(m/:/ms, $rs_goterm->get_column('pubid'));
            my $pub = $biodef->db_translate->{$publist[0]};
            my $pub_id = $publist[1];
            #print $publist[0] . " : " . $pub . "\n";
            if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                $pub_id = $pub . ':' . $pub_id;
            }
            #print "\t\t", $pub, "\t", $pub_id, "\n";
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
        
        #
        # Get the GO term qualifier.
        #
        my $rs_qualifiers = $self->dba_chado->resultset('Sequence::FeatureCvterm')
                  ->search(
                      {'me.feature_cvterm_id' => $rs_goterm->feature_cvterm_id},
                      {join => [{'cvterm' => [{'dbxref' => 'db'}, 'cv']},
                                {'feature_cvtermprops' => 'type'},
                                'pub'],
                          '+select' => [
                              'cvterm.dbxref_id',
                              'db.name',
                              'dbxref.accession',
                              'cvterm.name',
                              'cvterm.definition',
                              'feature_cvtermprops.feature_cvtermprop_id',
                              'type.name',
                              'feature_cvtermprops.value',
                              'pub.uniquename'],
                          '+as' => ['dbxref', 'db_name', 'db_accession', 'name', 'definition', 'feature_cvtermprop_id', 'type', 'qualifier', 'pubid'],
                          'where' => {'cv.name' => {'in' => ['biological_process',
                                                             'molecular_function',
                                                             'cellular_component',
                                                             'PomBase annotation extension terms']},
                               'type.name' => ['allele', 'condition',
                                               'qualifier', 'from', 'gene_product_form_id',
                                               'residue', 'evidence',
                                               # 'assigned_by' 
                                              ],
                               # 'pub.type_id' => {'not in' => ['1']}
                       },
                      });
        my $qualifier_dbentry = q{};
        my @qualifiers;
        while ( my $rs_qualifier = $rs_qualifiers->next ) {
            my $display_label = $rs_qualifier->get_column('qualifier');
            if ($rs_qualifier->get_column('type') eq 'evidence') {
              my $ec = $self->_get_evidence_code($rs_qualifier->get_column('qualifier'));
              $display_label = $ec->{'evidence'};
            }
            #print $display_label . "\n";
            $qualifier_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $self->feature_id.'_'.$rs_qualifier->get_column('feature_cvtermprop_id').'_'.$rs_goterm->feature_cvterm_id,
                -DBNAME      => 'PomBase_GO_AnnotationExtensions', # $rs_goterm->get_column('db_name'),
                #-RELEASE     => 1,
                #-VERSION     => 1,
                -DISPLAY_ID  => $display_label,
                -DESCRIPTION => $rs_qualifier->get_column('type').' '.$rs_goterm->get_column('pubid').' '.$rs_goterm->feature_cvterm_id,
                -INFO_TYPE   => 'DIRECT',
            );
            
            my @publist = split(m/:/ms, $rs_qualifiers->get_column('pubid'));
            my $pub = $biodef->db_translate->{$publist[0]};
            my $pub_id = $publist[1];
            #print $publist[0] . " : " . $pub . "\n";
            if ( ($pub) and ($pub =~ m/GO/ms or $pub =~ m/SO/ms) ) {
                $pub_id = $pub . ':' . $pub_id;
            }
            #print "\t\t", $pub, "\t", $pub_id, "\n";
            my $with_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                -PRIMARY_ID  => $pub_id,
                -DBNAME      => $pub,
                #-RELEASE     => 'NULL',
                #-VERSION     => 1,
                -DISPLAY_ID  => $pub_id,
                -DESCRIPTION => q{},
                -INFO_TYPE   => 'DIRECT',
            );
            
            if ( $pub_id ne '' ) { 
              push @qualifiers, {
                'dbentry'   => $qualifier_dbentry,
                'extension' => $rs_qualifier->get_column('type'),
                'pmid'      => $with_pub_dbentry,
                'group'     => $rs_goterm->feature_cvterm_id              
              };
            } else {
              push @qualifiers, {
                'dbentry'   => $qualifier_dbentry,
                'extension' => $rs_qualifier->get_column('type'),
                'pmid'      => $pub_dbentry,
                'group'     => $rs_goterm->feature_cvterm_id              
              };
            }
        }
        undef($rs_qualifiers);
        
        
        #
        # Get the GO term with/from.
        #
        my $rs_withfroms = $self->dba_chado->resultset('Sequence::FeatureCvterm')
                  ->search(
                      {'me.feature_cvterm_id' => $rs_goterm->feature_cvterm_id},
                      {join => [{'cvterm' => [{'dbxref' => 'db'}, 'cv']},
                                {'feature_cvtermprops' => 'type'},
                                'pub'],
                          '+select' => [
                              'cvterm.dbxref_id',
                              'db.name',
                              'dbxref.accession',
                              'cvterm.name',
                              'cvterm.definition',
                              'feature_cvtermprops.feature_cvtermprop_id',
                              'feature_cvtermprops.value',
                              'pub.uniquename',
                              'type.name'],
                          '+as' => ['dbxref', 'db_name', 'db_accession', 'name', 'definition', 'feature_cvtermprop_id', 'qualifier', 'pubid', 'type'],
                          'where' => {'cv.name' => {'in' => ['biological_process',
                                                             'molecular_function',
                                                             'cellular_component',
                                                             'PomBase annotation extension terms']},
                               'type.name' => ['from', 'with'],
                               # 'pub.type_id' => {'not in' => ['1']}
                       },
                      });
        my @withfrom_dbentries;
        while ( my $rs_withfrom = $rs_withfroms->next ) {
            my @sources = split(m/\|/ms, $rs_withfrom->get_column('qualifier'));
            #print $rs_withfrom->get_column('type') . "\t" . $rs_withfrom->get_column('qualifier') . "\n";
            foreach my $withfrom ( @sources ) {
                my @db_name = split(m/:/ms, $withfrom);
                my $db = $biodef->db_translate->{$db_name[0]};
                if (!defined $db) {
                    $db = $db_name[0];
                }
                if ($db eq 'PomBase_GENE') {
                  $db = 'PomBase_TRANSCRIPT';
                } elsif ($db =~ m/SP[ABCMNRS][CINPRT]/ms) {
                  @db_name = ('PomBase', $db);
                  $db = 'PomBase';
                }
                
#                print "\t\t" . $self->feature_id . "\t" . $db . "\t" . $withfrom . "\n";
#                print "\t\t" . $self->feature_id.'_'.$rs_withfrom->get_column('feature_cvtermprop_id').'_'.$rs_goterm->feature_cvterm_id;
#                print "\t\t|" . $db . "\t" . $db_name[1] . "\n\t"; 
                
                my @publist = split(m/:/ms, $rs_withfrom->get_column('pubid'));
                my $pub = $biodef->db_translate->{$publist[0]};
                my $pub_id = $publist[1];
                #print $publist[0] . " : " . $pub . "\n";
                if ($pub =~ m/GO/ms or $pub =~ m/SO/ms) {
                    $pub_id = $pub . ':' . $pub_id;
                }
                #print "\t\t", $pub, "\t", $pub_id, "\n";
                my $with_pub_dbentry = Bio::EnsEMBL::DBEntry -> new (
                    -PRIMARY_ID  => $pub_id,
                    -DBNAME      => $pub,
                    #-RELEASE     => 'NULL',
                    #-VERSION     => 1,
                    -DISPLAY_ID  => $pub_id,
                    -DESCRIPTION => q{},
                    -INFO_TYPE   => 'DIRECT',
                );
                
                my $withfrom_dbentry = ();
                
                if ( $db eq 'PomBase' ) {
                  my @withfroms = split(m/,/ms, $withfrom);
                  foreach my $withfrom (@withfroms) {
                    my @wf = split(m/:/ms, $withfrom);
                    $withfrom_dbentry = $self->_get_PomBase_Gene_DBEntry($wf[1]);
                    push @withfrom_dbentries, {'extension' => $rs_withfrom->get_column('type'),
                                               'dbentry'   => $withfrom_dbentry,
                                               'pmid'      => $with_pub_dbentry,
                                               'group'     => $rs_goterm->feature_cvterm_id
                    };
                  }
                } else {
                  $withfrom_dbentry = Bio::EnsEMBL::DBEntry -> new (
                      -PRIMARY_ID  => $db_name[1],
                      -DBNAME      => $db,
                      #-RELEASE     => 1,
                      #-VERSION     => 1,
                      -DISPLAY_ID  => $db . ':' . $db_name[1],
                      -DESCRIPTION => $rs_withfrom->get_column('type'),
                      -INFO_TYPE   => 'DIRECT',
                  );
                  
                  push @withfrom_dbentries, {'extension' => $rs_withfrom->get_column('type'),
	                                         'dbentry'   => $withfrom_dbentry,
	                                         'pmid'      => $with_pub_dbentry,
	                                         'group'     => $rs_goterm->feature_cvterm_id
                  };
                }
            }
        }
        undef($rs_withfroms);
        #print "\n" . scalar @withfrom_dbentries;
        #print "\n\n";
        
        
        #
        # Link the GO term to the Gene/Protein
        #
        if ( defined $evid_code) {
#            if ($qualifier_dbentry ne q{}) {
#                $goterm_dbentry->add_linkage_type(
#                    'NAS',
#                    $qualifier_dbentry);
#            }
            
            if ( $pub_dbentry eq q{} ) {
                #print "WRONG PLACE TO BE!\n";
                $goterm_dbentry->add_linkage_type(
                    $evid_code->{'evidence'});
            } else {
                #print "Added Publication\n";
                #print "\n\t" . $pub_dbentry->primary_id . "\t" . $pub_dbentry->description . "\n";
                $goterm_dbentry->add_linkage_type(
                    $evid_code->{'evidence'},
                    $pub_dbentry);
                
                
#                foreach my $qualifier ( @qualifiers ) {
#                    if ($qualifier ne q{}) {
#                        #print "Added Qualifier\n";
#                        #print "\t" . $qualifier_dbentry->primary_id . "\t" . $qualifier_dbentry->description . "\t";
#                        $goterm_dbentry->add_associated_xref(
#                            $qualifier,
#                            $pub_dbentry,
#                            'qualifier');
#                    }
#                }
#                
#                foreach my $withfrom_dbentry ( @withfrom_dbentries ) {
#                    if ($withfrom_dbentry ne q{}) {
#                        my %aed = %{$withfrom_dbentry};
#                        #print "Added WithFrom\n";
#                        #print "\t" . $goterm_dbentry->primary_id . "\t" . $withfrom_dbentry->description . "\t";
#                        #print "\t" . $aed{'extension'};
#                        #print "\t" . $aed{'dbentry'}->primary_id . "\n";
#                        my $db_id = $goterm_dbentry->add_associated_xref(
#                            $aed{'dbentry'},
#                            $aed{'pmid'},
#                            $aed{'extension'});
#                        #print $db_id . "\n"; 
#                    }
#                }
#                
#                my @aed_dbentry_array = ();
#                my @aed_condition_array = ();
##                foreach my $annot_ext_dbentry ( @annot_ext ) {
##                    my %aed = %{$annot_ext_dbentry};
##                    push @aed_dbentry_array, $aed{'dbentry'};
##                    push @aed_condition_array, $aed{'extension'};
##                } 
#                if ( @annot_ext > 0 ) {
#                    #print "----------\n";
#                    #print "\tAdded Annot Ext\n\t\tSize: " . @annot_ext . "\n";
#                     
#                    my $rank = 0;
#                    foreach my $annot_ext_dbentry ( @annot_ext ) {
#                      my %aed = %{$annot_ext_dbentry};
#                      #print "\t\t" . $aed{'extension'};
#                      #print "\t" . $aed{'dbentry'}->primary_id . "\n";
#                      #print "\t\t" . $goterm_dbentry->primary_id . "\n";
#                      #print "\t" . $annot_ext_dbentry->info_text . "\n";
#                      $goterm_dbentry->add_associated_xref(
#                        $aed{'dbentry'},
#                        $pub_dbentry,
#                        $aed{'extension'},
#                        $aed{'group'},
#                        $rank);
#                      $rank++;
#                    }
#                    #print "==========\n";
#                }
                
                my %associated_xrefs;
                my $rank = 0;
                if ( @annot_ext > 0 ) {
                    foreach my $annot_ext_dbentry ( @annot_ext ) {
                      my %aed = %{$annot_ext_dbentry};
                      if ( ( $aed{'extension'} and $aed{'extension'} eq 'created' ) or  
                           ( $aed{'dbentry'} and $aed{'dbentry'}->primary_id eq 'created' )
                      ) {
                      	next;
                      }
                      if ( !defined $associated_xrefs{$aed{'group'}}{$rank} ) {
                        $associated_xrefs{$aed{'group'}}{$rank} = {
                          'dbentry'        => $aed{'dbentry'},
                          'source'         => $pub_dbentry,
                          'condition_type' => $aed{'extension'}
                        };
                      } else {
                        $rank = scalar keys %{ $associated_xrefs{$aed{'group'}} };
                        $associated_xrefs{$aed{'group'}}{$rank+1} = {
                          'dbentry'        => $aed{'dbentry'},
                          'source'         => $pub_dbentry,
                          'condition_type' => $aed{'extension'}
                        };
                      }
                      $rank++;
                    }
                }
                
                $rank = 0;
                foreach my $qualifier ( @qualifiers ) {
                  if ($qualifier ne q{}) {
                    if ( $qualifier->{'extension'} eq 'created' 
                         || $qualifier->{'dbentry'}->primary_id eq 'created'
                    ) {
                        next;
                      }
                    if ( defined $associated_xrefs{$qualifier->{'group'}} ) {
                      $rank = scalar keys %{ $associated_xrefs{$qualifier->{'group'}} };
                      $associated_xrefs{$qualifier->{'group'}}{$rank} = {
                        'dbentry'        => $qualifier->{'dbentry'},
                        'source'         => $qualifier->{'pmid'},
                        'condition_type' => $qualifier->{'extension'}
                      };
                    } else {
                      $associated_xrefs{$qualifier->{'group'}}{$rank} = {
                        'dbentry'        => $qualifier->{'dbentry'},
                        'source'         => $qualifier->{'pmid'},
                        'condition_type' => $qualifier->{'extension'}
                      };
                    }
                  }
                  $rank++;
                }
                
                $rank = 0;
                foreach my $withfrom_dbentry ( @withfrom_dbentries ) {
                  if ($withfrom_dbentry ne q{}) {
                    if ( $withfrom_dbentry->{'extension'} eq 'created' 
                         || $withfrom_dbentry->{'dbentry'}->primary_id eq 'created'
                    ) {
                        next;
                      }
                    if ( defined $associated_xrefs{$withfrom_dbentry->{'group'}} ) {
                      $rank = scalar keys %{ $associated_xrefs{$withfrom_dbentry->{'group'}} };
                      $associated_xrefs{$withfrom_dbentry->{'group'}}{$rank} = {
                        'dbentry'        => $withfrom_dbentry->{'dbentry'},
                        'source'         => $withfrom_dbentry->{'pmid'},
                        'condition_type' => $withfrom_dbentry->{'extension'}
                      };
                    } else {
                      $associated_xrefs{$withfrom_dbentry->{'group'}}{$rank} = {
                        'dbentry'        => $withfrom_dbentry->{'dbentry'},
                        'source'         => $withfrom_dbentry->{'pmid'},
                        'condition_type' => $withfrom_dbentry->{'extension'}
                      };
                    }
                  }
                  $rank++;
                }
                
                foreach my $group ( keys %associated_xrefs ) {
                  foreach my $rank ( keys %{ $associated_xrefs{$group} } ) {
#                    print $associated_xrefs{$group}{$rank}{'dbentry'}->primary_id;
#                    print "\t" . $associated_xrefs{$group}{$rank}{'condition_type'} . "\n";
                    $goterm_dbentry->add_associated_xref(
                        $associated_xrefs{$group}{$rank}{'dbentry'},
                        $associated_xrefs{$group}{$rank}{'source'},
                        $associated_xrefs{$group}{$rank}{'condition_type'},
                        $group,
                        $rank);
                  }
                }
                
                
                #my @publist = split(m/:/ms, $rs_goterm->get_column('pubid'));
                #my $pub = $biodef->db_translate->{$publist[0]};
                
                # Below is to handle if the annotation is based on another entry, 
                # such as a GO term.   The with/from field. 
                my %evidencehash = %{ $evid_code };
#                if ( exists $evidencehash{'source'} and defined $evidencehash{'source'} ) {
#                    $goterm_dbentry->linkage_annotation = $evidencehash{'source'}; 
#                }
                if ( exists $evidencehash{'source'} and defined $evidencehash{'source'} ) {
                    #print '|', $evidencehash{'source'}, '|';
                    #my $dbevidsrc = $evidencehash{'source'};
                    my $db = $biodef->db_translate->{$evidencehash{'source'}};
                    my $db_id = $evidencehash{'source_id'};
                    #print Dumper $evidencehash{'source'};
                    #print $biodef->db_translate->{$evidencehash{'source'}}, '|', $db, "|\n";
                    #print "\t\t\t", $rs_goterm->get_column('pubid'), "\n";
                    
                    my $db_dbentry = q{};
                    if ( index($db, 'GO') >= 0 or index($db, 'SO') >= 0 ) {
                        $db_id = $db . ':' . $db_id;
                        $db_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                            -PRIMARY_ID  => $self->feature_id.'_'.$db_id.'_'.$rs_goterm->get_column('pubid'),
                            -DBNAME      => $db,
                            #-RELEASE     => 'NULL',
                            #-VERSION     => 1,
                            -DISPLAY_ID  => $db_id,
                            -DESCRIPTION => $evidencehash{'association'}.' '.$rs_goterm->get_column('pubid'),
                            -INFO_TYPE   => 'DIRECT',
                        );
                        $db_dbentry->add_linkage_type('ND');
                    } else {
                       my @db_name = split(m/:/ms, $db_id);
                       $db_dbentry = Bio::EnsEMBL::DBEntry -> new (
                            -PRIMARY_ID  => $self->feature_id.'_'.$db_id.'_'.$rs_goterm->get_column('pubid'),
                            -DBNAME      => $db_name[0],
                            #-RELEASE     => 'NULL',
                            #-VERSION     => 1,
                            -DISPLAY_ID  => $db_id,
                            -DESCRIPTION => $evidencehash{'association'}.' '.$rs_goterm->get_column('pubid'),
                            -INFO_TYPE   => 'DIRECT',
                        ); 
                    }
                    
                    $goterm_dbentry->add_linkage_type(
                        $evid_code->{'evidence'},
                        $db_dbentry);
                } elsif ( exists $evidencehash{'source_set'} and defined $evidencehash{'source_set'} ) {
                    foreach my $source_evid ( @{ $evidencehash{'source_set'} } ) {
                        my %evid_source = %{ $source_evid };
                        #print Dumper %evid_source;
                        #print "\t\t\t", $rs_goterm->get_column('pubid'), "\n";
                        my $db = $biodef->db_translate->{$evid_source{'source'}};
                        my $db_id = $evid_source{'source_id'};
                        
                        my $db_dbentry = q{};
                        if ( index($db, 'GO') >= 0 or index($db, 'SO') >= 0 ) {
                            $db_id = $db . ':' . $db_id;
                            $db_dbentry = Bio::EnsEMBL::OntologyXref -> new (
                                -PRIMARY_ID  => $db_id.'_'.$rs_goterm->get_column('pubid'),
                                -DBNAME      => $db,
                                #-RELEASE     => 'NULL',
                                #-VERSION     => 1,
                                -DISPLAY_ID  => $db_id,
                                -DESCRIPTION => $evidencehash{'association'}.' '.$rs_goterm->get_column('pubid'),
                                -INFO_TYPE   => 'DIRECT',
                            );
                            $db_dbentry->add_linkage_type('ND');
                        } else {
                           my @db_name = split(m/:/ms, $db_id);
                           $db_dbentry = Bio::EnsEMBL::DBEntry -> new (
                                -PRIMARY_ID  => $db_id.'_'.$rs_goterm->get_column('pubid'),
                                -DBNAME      => $db_name[0],
                                #-RELEASE     => 'NULL',
                                #-VERSION     => 1,
                                -DISPLAY_ID  => $db_id,
                                -DESCRIPTION => $evidencehash{'association'}.' '.$rs_goterm->get_column('pubid'),
                                -INFO_TYPE   => 'DIRECT',
                            ); 
                        }
                        
                        $goterm_dbentry->add_linkage_type(
                            $evid_code->{'evidence'},
                            $db_dbentry);
                    }
                }
            }
        }
#        print $self->feature_id . "\t" . $goterm_id . "\t" . $goterm_dbentry->description . "\t" . $goterm_dbentry->info_text . "\n";
#        print Dumper $goterm_dbentry;
#        print "\n==========\n";
        if (($goterm_id) and ($goterm_id ne '')) {
            $goterms{$goterm_id} = $goterm_dbentry;
        }# else {
        #    warn "WARNING: feature_id " . $self->feature_id . " for feature_cvterm_id " . $goterm_feature_cvterm_id . " has an undefined GO term. Check the cvterm_relationship\n";
        #}
    }
    undef($rs);
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};

    return \%goterms;
}


sub _get_evidence_code {
    my ( $self, $evid ) = @_;

    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
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
        if ( $evid eq $fullid ) {
            $evidence{'evidence'} = $biodef->go->{$fullid};
            $valid = 1;
            $finalfullid = $fullid;
            #print "MATCH\n";
            last;
        } elsif ( $biodef->go->{$fullid} eq uc $evid ) {
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
        my @evidlist;
        my @evidence_source;
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
        
        $evidlist[-1] =~ s/^\s+//; #remove leading spaces
        $evidlist[-1] =~ s/\s+$//; #remove trailing spaces
        #my @sources = split(m/|/ms, $evidlist[-1]);
        
        #print $evidlist[-1] . "\n";
        
        #$evidence{'source'} = $evidlist[-1];
        #return \%evidence;
        
        my @sources = split(m/\|/ms, $evidlist[-1]);
        if ( scalar @sources == 1 ) {
            my @source = split(m/:/ms, $evidlist[-1]);
            if ( $source[1] eq q{} ) {
                return \%evidence;
            }
            $evidence{'source'} = $source[0];
            $evidence{'source_id'} = $source[1];
            return \%evidence;
        } elsif ( scalar @sources > 1 ) {
            my @source_set;
            foreach my $source_string (@sources) {
                my @source = split(m/:/ms, $source_string);
                push @source_set, {'source' => $source[0], 'source_id' => $source[1]};
            }
            $evidence{'source_set'} = \@source_set;
        }
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
      if ( ($gene_name) and ($gene_name eq '') ) {
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

PomLoader::GOTerms - Builds GO term objects with their associated
                     publications.

=head1 DESCRIPTION

Module to build Bio::EnsEMBL::OntologyXref objects.   It also populates the 
GO term objects with their related publications.   The conversion of the GO
decriptions from those used in the Chado database (full) to what is used in ]
the ensembl database (3 letter code) is handled via the BioDefinitions module.
If there is a mismatch then the script exits detailing the go description that
is not included in the BioDefinitions.

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

my $goterms = PomLoader::GOTerms->new(
                       'dba_chado'     => $dba_chado,
                       'feature_id' => $feature_id,
                   );

my %gotermlist = %{$goterms->goterms()};

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut