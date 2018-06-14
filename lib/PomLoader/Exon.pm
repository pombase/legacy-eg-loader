package PomLoader::Exon;

use Moose;

use Bio::EnsEMBL::Exon;

has 'dba_ensembl'   => (isa => 'Bio::EnsEMBL::DBSQL::DBAdaptor', is => 'ro', required => 1);
has 'dba_chado'     => (isa => 'Bio::Chado::Schema', is => 'ro', required => 1);
has 'transcript_id' => (isa => 'Int', is => 'ro', required => 1);
has 'slice'         => (isa => 'Bio::EnsEMBL::Slice', is => 'ro', required => 1);
has 'current'     => (isa => 'Int', is => 'ro', required => 1);
has 'dbparams'    => (isa => 'HashRef', is => 'ro', required => 1);

has 'exons'  => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_generate_exons');

sub number_of_exons {
    my $self = shift;
    return scalar @{$self->exons()};
}


sub overlaps {
    my $self = shift;
    my @exonlist = @{$self->exons()};
    my $overlap = 0;
    my %exonhash = ();
    my $countid = 0;
    if (scalar(@exonlist) == 1) {
        return $overlap;
    }
    my @alist = map $_->start(), @exonlist;

    my @exonid = sort { $alist[$a] <=> $alist[$b] } 0..scalar(@alist)-1;
    for ( my $i=1; $i<scalar(@exonid); $i++ ) {
        if ($exonlist[$i]->start()<=$exonlist[$i-1]->end()) {
            $overlap = 1;
        }
    }
    return $overlap;
}


sub _generate_exons {
    my $self = shift;
    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $self->dbparams->{'biodef'};

    my @exons = ();
    my @utrs = ();

    my $rs_exons =
        $self->dba_chado->resultset('Sequence::FeatureRelationship')
              ->search(
                       {object_id => $self->transcript_id},
                       {join => ['type'],
                        'where' => {'type.name' => 'part_of'},
                       }
              )
              ->search_related('subject',
                       {},
                       {join => ['featureloc_features',
                                 'type'],
                        '+select' => [
                           'type_2.name',
                           {extract => 'EPOCH FROM subject.timeaccessioned'},
                           {extract => 'EPOCH FROM subject.timelastmodified'},
                           'featureloc_features.fmin',
                           'featureloc_features.fmax',
                           'featureloc_features.strand',
                           'featureloc_features.phase'],
                        '+as' => ['type_name', 'epochcreated', 'epochmodified', 'fmin', 'fmax', 'strand', 'phase'],
                        'where' => {'type_2.name' => [$biodef->chado_type()->{'exon'},
                                                    $biodef->chado_type()->{'pseudogenic_exon'},
                                                    $biodef->chado_type()->{'five_prime_UTR'},
                                                    $biodef->chado_type()->{'three_prime_UTR'},]}
                       });

    while ( my $rs_exon = $rs_exons->next ) {
        my $exon_length = $rs_exon->get_column('fmax') - $rs_exon->get_column('fmin');
        my $exon_phase = 0;
        if (defined($rs_exon->get_column('phase'))) {
            $exon_phase = $rs_exon->get_column('phase') or 0;
        }
        my $exon_phase_end = (($exon_length + $exon_phase) % 3);

        my $exonstart = $rs_exon->get_column('fmin');
        my $exonend = $rs_exon->get_column('fmax');
        if ($rs_exon->get_column('strand') eq '1') {
            $exonstart = $exonstart + 1;
        } elsif ($rs_exon->get_column('strand') eq '-1'){
            $exonstart = $exonstart + 1;
        }

        my $exon =  Bio::EnsEMBL::Exon -> new(
            -SLICE         => $self->slice,
            -START         => $exonstart,
            -END           => $exonend,
            -STRAND        => $rs_exon->get_column('strand'),
            -PHASE         => $exon_phase,
            -END_PHASE     => $exon_phase_end,
            -STABLE_ID     => $rs_exon->uniquename,
            #-VERSION       => 1,
            -IS_CURRENT    => $self->current==0,
            -CREATED_DATE  => $rs_exon->get_column('epochcreated'),
            -MODIFIED_DATE => $rs_exon->get_column('epochmodified')
        );
        if ( $exon->is_current() eq q{} ) {
            $exon->is_current(0);
        }
        if ($rs_exon->get_column('type_name') eq 'exon' or
            $rs_exon->get_column('type_name') eq 'pseudogenic_exon') {
            push @exons, $exon;
        } elsif (index $rs_exon->get_column('type_name'), 'five_prime_UTR' or
            index $rs_exon->get_column('type_name'), 'three_prime_UTR') {
            push @utrs, $exon;
        }
    }
    my %joined_exons = %{ $self->_join_exons(\@exons, \@utrs) };
    
    my $kids = $self->dba_chado->storage->dbh->{CachedKids};
    delete @{$kids}{keys %$kids};
    
    return {'exons' => $joined_exons{'exons'},
            'utrs'  => $joined_exons{'utrs'},
            'utr5'  => $joined_exons{'utr5'},
            'utr3'  => $joined_exons{'utr3'}};
}


sub _join_exons {
    my ( $self, $e, $u ) = @_;
    my @exons = @{ $e };
    my @utrs  = @{ $u };
    
    # If there is nothing to be joined, drop out now.   This should be the 
    # majority of cases
    if (scalar @utrs == 0) {
        return {'exons' => $e,
                'utrs'  => $u};
    }
    
    my @exons_new = ();
    my @utrs_new  = ();
    
    my %joined_utr = ();
    my @join_exons = ();
    my $utr5 = 0;
    my $utr3 = 0;
    
    # Need to return the join exon/utr along with the offset for the join 
    # position and whether the utr is at the start or the end.
    for (my $i=0; $i<scalar @exons; $i++) {
        my $exon = $exons[$i];
        #print "\tExon: Start - ".$exon->start()."\tEnd - ".$exon->end()."\n";
        for (my $j=0; $j<scalar @utrs; $j++) {
            my $utr = $utrs[$j];
            my $loadutr = 1;
            #print "\t UTR: Start - " . $utr->start();
            #print "\tEnd - " . $utr->end() . "\n";
            if ($exon->start() == ($utr->end() + 1)) {
                $loadutr = 0;
                $joined_utr{$j} = 1;
                $exon->start($utr->start());
                $utr5 = $utr->end - $utr->start + 1;
            } elsif ($exon->end() == ($utr->start() - 1)) {
                $loadutr = 0;
                $joined_utr{$j} = 1;
                $exon->end($utr->end());
                $utr3 = $utr->end - $utr->start + 1;
            }
        }
        #print "\tNew Exon: Start-".$exon->start()."\tEnd:-".$exon->end()."\n";
        #print "Middle: utr5: " . $utr5 . " | utr3: " . $utr3 . "\n";
        push @exons_new, $exon;
    }
    
    #print "Final: utr5: " . $utr5 . " | utr3: " . $utr3 . "\n";
    
    for (my $j=0; $j<scalar @utrs; $j++) {
        if ($joined_utr{$j}) {
            next;
        } else {
            push @utrs_new, $utrs[$j];
        }
    }
    
    return {'exons' => \@exons_new,
            'utrs'  => \@utrs_new,
            'utr5'  => $utr5,
            'utr3'  => $utr3};
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

PomLoader::Exon - Builds a list of exon objects based on a transcript
                  feature ID.

=head1 DESCRIPTION

Module to build Bio::EnsEMBL::Exon objects.


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
 [current]:
     is_obsolete from Chado feature table.


=head2 exon

    Builder of Bio::EnsEMBL::Exon objects that are loaded to a HashRef.


=head2 number_of_exons

    Returns the number of exons associated to a given transcript.


=head2 overlapping

    Returns 0 or 1 depending on if the set of exons for a given transcript 
    overlap at the start and ends.   Returns 0 if there are no overlaps and
    1 if there is an overlap. 


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

my $exons = PomLoader::Exon->new(
                'dba_ensembl'   => $dba_ensembl,
                'dba_chado'     => $dba_chado,
                'transcript_id' => $feature_id,
                'slice'         => $slice);

my @exonlist = @{$exons->exons()};

=head1 LICENCE

This code is distributed under an Apache style licence. Please see
http://www.ensembl.org/info/about/code_licence.html for details.

=head1 AUTHOR

Mark McDowall <mcdowall@ebi.ac.uk>, Ensembl Genome Team

=head1 CONTACT

=cut