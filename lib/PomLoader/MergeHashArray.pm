package PomLoader::MergeHashArray;

use Moose;

has 'hash1' => ( isa => 'HashRef', is => 'ro', required => 1);
has 'hash2' => ( isa => 'HashRef', is => 'ro', required => 1);

has 'get_new_hash' => ( isa => 'HashRef', is => 'ro', lazy => 1, builder => '_mergehashes');

sub _mergehashes {
    my $self = shift;
    if (scalar keys %{ $self->hash1 } >= scalar keys %{ $self->hash2 }) {
        return $self->_combine_hashes($self->hash1, $self->hash2);
    } else {
        return $self->_combine_hashes($self->hash2, $self->hash1);
    }
}


sub _combine_hashes {
    my ( $self, $hsh1, $hsh2 ) = @_;
    my %h1 = %{ $hsh1 };
    my %h2 = %{ $hsh2 };
    if (scalar keys %h2 == 0) {
        return \%h1;
    }
    #print '|', %h1, "|\t|", %h2, "|\n" or confess;
    foreach my $h2key ( keys %h2 ) {        # For each key in the smallest hash
        #print $h2key, "\n" or confess;
        if ( exists  $h1{ $h2key } ) {      # Test if key exists in %h1
            my @a1 = @{$h1{ $h2key }};         # Get array @a1
            my @a2 = @{$h2{ $h2key }};         # Get array @a2
            my %a1a = map { $_ => 1 } @a1;  # Create map of values in @a1
            foreach my $e ( @a2 ) {
                if (!$a1a{$e}) {            # Test @a1 does not contain element of @a2 
                    push @a1, $e;
                    %a1a = map { $_ => 1 } @a1;
                }
            }
            #print 'New array: ', @a1, "\n" or confess;
            $h1{$h2key} = \@a1;              # Assign @a1 to key $h2key in %h1
            #print 'New hash:  ', %h1, ' (', @{$h1{$h2key}}, ")\n" or confess;
        } else {
            my @a2 = @{ $h2{ $h2key } };    # Get the array from %h2
            $h1{$h2key} = @a2;              # Insert missing key and array into %h1
        }
    }
    #print %h1, "\n" or confess;
    return \%h1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

