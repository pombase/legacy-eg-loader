package PomLoader::FeatureLocation;

use Moose;
use Data::Dumper;
#use Test::Memory::Cycle;

has 'dba_chado'  => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1, weak_ref => 1);
has 'feature_id' => (isa => 'Int', is => 'ro', required => 1, weak_ref => 1);
has 'type_id' => (isa => 'Str', is => 'ro', required => 0, weak_ref => 1);

has 'featurelocation'     => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_feature');
has 'subfeaturelocation'  => ( isa => 'ArrayRef', is => 'ro', lazy => 1, builder => '_generate_subfeature');

sub _generate_feature {
    my $self = shift;

    my $rs = $self->dba_chado->resultset('Sequence::Feature')
               ->search(
                   {'featureloc_features.locgroup' => 0 ,
                    'featureloc_features.rank' => 0,
                    'me.feature_id'  => $self->feature_id},
                   {select => ['me.feature_id', 'me.name', 'me.uniquename', 'me.type_id'],
                    join => ['type',
                             'featureloc_features',
                             #{'feature_dbxrefs' => {'dbxref' => 'db'}},
                             {'feature_cvterms' => { 'cvterm' => 'cv' } }],
                    '+select' => [
                       'type.name',
                       {extract => 'EPOCH FROM timeaccessioned'},
                       {extract => 'EPOCH FROM timelastmodified'},
                       'featureloc_features.fmin',
                       'featureloc_features.fmax',
                       'featureloc_features.strand',
                       'featureloc_features.phase',
                       #'dbxref.accession',
                       #'dbxref.db_id',
                       #'db.name',
                       'cvterm.cv_id',
                       'cv.name',
                       'cvterm.name'],
                    #'+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase', 'accession', 'db_id', 'db_name', 'cv_id', 'cv_name', 'cvterm_name']
                    '+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase', 'cv_id', 'cv_name', 'cvterm_name']
                   }
               );
    my $rs_count = 0;
    my %cvterm_names = ();
    my $featurelocation = {};
    while ( my $rs_feature = $rs->next ) {
        if ($rs_count == 0) {
            my ($featurestart, $featureend) = $self->_feature_range(
                                                  $rs_feature->get_column('fmin'),
                                                  $rs_feature->get_column('fmax'),
                                                  $rs_feature->get_column('strand'));

            my $featurename = $self->_feature_name($rs_feature->uniquename, $rs_feature->name);

            #my $dbname = $rs_feature->get_column('db_name') || q{};
            
            $featurelocation = {'feature_id'  => $rs_feature->feature_id,
                                'uniquename' => $rs_feature->uniquename,
                                'name'       => $featurename,
                                #'accession'  => $rs_feature->get_column('accession') || q{},
                                #'dbsource'   => $dbname,
                                'type_id'    => $rs_feature->get_column('type_name') || q{},
                                'start'      => $featurestart,
                                'end'        => $featureend,
                                'strand'     => $rs_feature->get_column('strand') || q{},
                                'phase'      => $rs_feature->get_column('phase') || q{},
                                'created'    => $rs_feature->get_column('epochcreated'),
                                'modified'   => $rs_feature->get_column('epochmodified'),
            };
            $rs_count = 1;
        }

        if (defined $rs_feature->get_column('cv_name') and exists $cvterm_names{$rs_feature->get_column('cv_name')}) {
            my @cvterms = @{ $cvterm_names{$rs_feature->get_column('cv_name')} };
            push @cvterms, $rs_feature->get_column('cvterm_name');
            $cvterm_names{$rs_feature->get_column('cv_name')} = \@cvterms;
        } elsif ( defined $rs_feature->get_column('cv_name') )  {
            my @cvterms = ($rs_feature->get_column('cvterm_name'));
            $cvterm_names{$rs_feature->get_column('cv_name')} = \@cvterms;
        }
    }

    if (exists $cvterm_names{'genedb_products'}) {
        my @cvterms = @{ $cvterm_names{'genedb_products'} };
        if (scalar @cvterms > 1) {
            warn 'WARNING: More than one GeneDB description for Feature ', $self->feature_id;
        }
        $featurelocation->{'description'} = $cvterms[0];
    } elsif (exists $cvterm_names{'PomBase gene products'}) {
        my @cvterms = @{ $cvterm_names{'PomBase gene products'} };
        if (scalar @cvterms > 1) {
            warn 'WARNING: More than one PomBase description for Feature ', $self->feature_id;
        }
        $featurelocation->{'description'} = $cvterms[0];
    } else {
        $featurelocation->{'description'} = $featurelocation->{'uniquename'};
    }
    my $fl = $featurelocation;
    #print Dumper $fl;
    #print $fl . "\n";
    return $fl;
    #return \%featurelocation;
}

sub _generate_subfeature {
    my $self = shift;
    my @featurelist = ();

    my $rs =
        $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                   {object_id => $self->feature_id},
                   {join => ['type']}
              )
              ->search_related('subject',
                   {},
                   {select => ['subject.feature_id', 'subject.name', 'subject.uniquename', 'subject.type_id'],
                    join => ['type',
                             'featureloc_features',
                             #{'feature_dbxrefs' => {'dbxref' => 'db'}},
                             {'feature_cvterms' => { 'cvterm' => 'cv' }  } ],
                    '+select' => [
                       'type_2.name',
                       {extract => 'EPOCH FROM timeaccessioned'},
                       {extract => 'EPOCH FROM timelastmodified'},
                       'featureloc_features.fmin',
                       'featureloc_features.fmax',
                       'featureloc_features.strand',
                       'featureloc_features.phase',
                       #'dbxref.accession',
                       #'dbxref.db_id',
                       #'db.name',
                       'cvterm.cv_id',
                       'cv.name',
                       'cvterm.name',
                       'me.type_id',
                       'type.name'],
                    #'+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase', 'accession', 'db_id', 'db_name', 'cv_id', 'cv_name', 'cvterm_name', 'relationship_id', 'relationship_name']
                    '+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase', 'cv_id', 'cv_name', 'cvterm_name', 'relationship_id', 'relationship_name']
                   }
               );


    my $dbname_previous = q{};
    my %featureloclist = ();
    while( my $rs_feature = $rs->next ) {
        if ((defined $self->type_id and $rs_feature->get_column('relationship_name') eq $self->type_id)
                 or defined $self->type_id eq q{}) {
            #print "Subfeature of ".$self->feature_id."\t" . $rs_feature->get_column('cv_name') . "\t" . $rs_feature->get_column('cvterm_name') . "\n";
            if ( exists $featureloclist{$rs_feature->feature_id} ) {
                my %featurelocation =  %{ $featureloclist{$rs_feature->feature_id} };
                my %cvterm_names = %{ $featurelocation{'cvterms'} };
    
                if (defined $rs_feature->get_column('cv_name') and exists $cvterm_names{$rs_feature->get_column('cv_name')}) {
                    my @cvterms = @{ $cvterm_names{$rs_feature->get_column('cv_name')} };
                    push @cvterms, $rs_feature->get_column('cvterm_name');
                    $cvterm_names{$rs_feature->get_column('cv_name')} = \@cvterms;
                } else {
                    my @cvterms = ($rs_feature->get_column('cvterm_name'));
                    $cvterm_names{$rs_feature->get_column('cv_name')} = \@cvterms;
                }
    
                $featurelocation{'cvterms'} = \%cvterm_names;
    
                $featureloclist{$rs_feature->feature_id} = \%featurelocation;
            } else {
                my ($featurestart, $featureend) = $self->_feature_range(
                                                      $rs_feature->get_column('fmin'),
                                                      $rs_feature->get_column('fmax'),
                                                      $rs_feature->get_column('strand'));
    
                my $featurename = $self->_feature_name($rs_feature->uniquename, $rs_feature->name);
    
                #my $dbname = $rs_feature->get_column('db_name') || q{};
    
                my @cvterms = q{};
                my %cvterm_names = ();
                if (defined $rs_feature->get_column('cvterm_name')) {
                    @cvterms = ($rs_feature->get_column('cvterm_name'));
                    %cvterm_names = ($rs_feature->get_column('cv_name') => \@cvterms);
                }
    
                my %featurelocation = ('feature_id'    => $rs_feature->feature_id,
                                        'uniquename'   => $rs_feature->uniquename,
                                        'name'         => $featurename,
                                        #'accession'    => $rs_feature->get_column('accession') || q{},
                                        'obsolete'     => $rs_feature->is_obsolete,
                                        'relationship' => $rs_feature->get_column('relationship_name') || q{},
                                        #'dbsource'     => $dbname,
                                        'type_id'      => $rs_feature->get_column('type_name') || q{},
                                        'start'        => $featurestart,
                                        'end'          => $featureend,
                                        'strand'       => $rs_feature->get_column('strand') || q{},
                                        'phase'        => $rs_feature->get_column('phase') || q{},
                                        'created'      => $rs_feature->get_column('epochcreated'),
                                        'modified'     => $rs_feature->get_column('epochmodified'),
                                        'cvterms'      => \%cvterm_names,
                );
    
                $featureloclist{$rs_feature->feature_id} = \%featurelocation;
            }
        }
    }
    undef($rs);

    foreach my $featurelocationkey ( keys %featureloclist ) {
        my %featurelocation =  %{ $featureloclist{$featurelocationkey} };
        if (exists $featurelocation{'cvterms'}) {
            my %cvterm_names = %{ $featurelocation{'cvterms'} };
            if (exists $cvterm_names{'genedb_products'}) {
                my @cvterms = @{ $cvterm_names{'genedb_products'} };
                if (scalar @cvterms > 1) {
                    warn 'WARNING: More than one GeneDB description for Feature ', $featurelocationkey;
                }
                $featurelocation{'description'} = $cvterms[0];
            } elsif (exists $cvterm_names{'PomBase gene products'}) {
                my @cvterms = @{ $cvterm_names{'PomBase gene products'} };
                if (scalar @cvterms > 1) {
                    warn 'WARNING: More than one PomBase description for Feature ', $self->feature_id;
                }
                $featurelocation{'description'} = $cvterms[0];
            } else {
                $featurelocation{'description'} = $featurelocation{'uniquename'};
            }
        } else {
            $featurelocation{'description'} = $featurelocation{'uniquename'};
        }
        push @featurelist, \%featurelocation;
    }

    return \@featurelist;
}


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


# Determines if the $name contains a values that can be used in Ensembl as 
# the short name, if not it uses the $uniquename.   In Chado the $uniquename
# can not be Null or empty.
sub _feature_name {
    my ( $self, $uniquename, $name) = @_;
    if (!defined $name) {
        return $uniquename;
    }
    return $name;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::FeatureLocation - Moose module for handling the construction 
                             biological features attached to the chromosome

=head1 DESCRIPTION

This is a perl module that handles the extraction of feature attributes 
including the location and accessions of features that are located within the
chromosome.   This includes everything from the genes through to exons, 
transcripts and proteins.   Domains and other features that are hung off of the
protein check out the ProteinFeature.pm module.


=head1 

=head2 new

 [dba_chado]:
     Bio::Chado::Schema
 [feature_id]:
     String - Feature_id from the Chado database.

=head2 featurelocation

 Getter of all feature location and information about a feature given
 the supplied feature_id.   Returns a HashRef of all of the information

=head2 subfeaturelocation

 Getter of all feature location and information about features 
 associated with a given the supplied feature_id.   Returns a
 HashRef of all of the information.

=head1 SYNOPSIS

#
# Get all information about the Gene.
#
my $feature_gene = PomLoader::FeatureLocation->new(
                          'dba_chado'   => $self->dba_chado,
                          'feature_id'  => $self->gene_id,);
my $featureloc_gene = $feature_gene->featurelocation();

#
# Get all the products of the gene.
#
my $feature_transcript = PomLoader::FeatureLocation->new(
                          'dba_chado'  => $self->dba_chado,
                          'feature_id' => $self->gene_id);
my @featureloc_transcript = @{$feature_transcript->subfeaturelocation()};

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

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut