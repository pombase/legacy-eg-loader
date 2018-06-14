#!/usr/bin/env perl

use Config::Tiny;
use Data::Dumper;
use Bio::Chado::Schema;
use PomLoader::BioDefinitions;

# Create a config
my $config = Config::Tiny->new();

# Open the config
$config = Config::Tiny->read( "$ENV{HOME}/.perlDbs" );

my $chadodb   = $config->{postgresboxpombe};

my $chado = Bio::Chado::Schema -> connect(
    "DBI:Pg:dbname=$chadodb->{dbname};host=$chadodb->{host};port=$chadodb->{port}",
    $chadodb->{user},
    $chadodb->{pass}
) or croak();

my $bd = PomLoader::BioDefinitions->new('dba_chado' => $chado);

#print $bd->biotype->{321}, "\n" or next;

#my $d = Data::Dumper->new(\%{$bd->go->{'Non-traceable Author Statement'}});
#print $d->Dump();

#print $bd->go->{'Non-traceable Author Statement'};

my $go = $bd->go();
print $go->{'non-traceable author statement'} . "\n";

my %evid_code = %{ _get_evidence_code('Non-traceable Author Statement') };

print $evid_code{'source_set'};


sub _get_evidence_code {
    my ( $evid ) = @_;

    #my $biodef = PomLoader::BioDefinitions->new('dba_chado' => $self->dba_chado);
    my $biodef = $bd;
    $evid = lc $evid;
    my $valid = 0;
    my %evidence = ();
    #foreach my $x ( keys %{ $biodef->go } ) {
    #    print "\t$x";
    #}
    #print "\n";
    my $finalfullid = q{};
    print "\t$evid\n";
    foreach my $fullid ( keys %{ $biodef->go } ) {
        print "\t\t$fullid: ";
        if ( $evid eq $fullid ) {
            $evidence{'evidence'} = $biodef->go->{$fullid};
            $valid = 1;
            $finalfullid = $fullid;
            print "MATCH 1\n";
            last;
        } elsif ( $biodef->go->{$fullid} eq uc $evid ) {
            $evidence{'evidence'} = $biodef->go->{$fullid};
            $valid = 1;
            $finalfullid = $fullid;
            print "MATCH 2\n";
            last;
        }
        print "FAILED\n";
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

#foreach my $x ( @{$bd->go->{'Non-traceable Author Statement'}} ) {
#    foreach my $y (@{$x}) {
#        print $y;
#    }
#    print $x;
#    my $d = Data::Dumper->new(%{$x});
#    print $d->Dump();
#}

#print isa %{$bd}, "\n" or next;

#print my $text ||= [];