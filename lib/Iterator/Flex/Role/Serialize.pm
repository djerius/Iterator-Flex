package Iterator::Flex::Role::Serialize;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.10';

use Carp ();
use List::Util ();

use Iterator::Flex;
use Role::Tiny;

=method freeze

  $freeze = $iter->freeze;

Returns a recipe to freeze an iterator and its dependencies.  See
L<Iterator::Flex/"Serialization of Iterators"> for more information.

=cut

sub freeze {

    my $obj = $_[0];
    my $attributes = $Iterator::Flex::Base::REGISTRY{ Scalar::Util::refaddr $obj };

    my @freeze;

    if ( defined $attributes->{depends} ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { ! $_->can( 'freeze' ) } @{ $attributes->{depends} };
        Carp::croak( "dependency: @{[ $cant->{name} ]} is not serializeable\n" )
            if $cant;

        # now freeze them
        @freeze = map $_->freeze, @{$attributes->{depends} };
    }

    push @freeze, $attributes->{freeze}->( $obj ), $attributes->{is_exhausted};

    return \@freeze;
}

1;
