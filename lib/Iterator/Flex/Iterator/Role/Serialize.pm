package Iterator::Flex::Iterator::Role::Serialize;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Carp ();
use List::Util ();

use Role::Tiny;

=method freeze

  $freeze = $iter->freeze;

Returns a recipe to freeze an iterator and its dependencies.  See
L<Iterator::Flex/"Serialization of Iterators"> for more information.

=cut

sub freeze {

    my $self = shift;

    my @freeze;

    if ( defined $self->{depends} ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { ! $_->can( 'freeze' ) } @{ $self->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not serializeable\n" )
            if $cant;

        # now freeze them
        @freeze = map $_->freeze, @{$self->{depends} };
    }

    local $_ = $self;
    push @freeze, $self->{freeze}->(), $_->{is_exhausted};

    return \@freeze;
}

1;
