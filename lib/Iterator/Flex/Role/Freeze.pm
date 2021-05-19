package Iterator::Flex::Role::Freeze;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use List::Util;

use Iterator::Flex::Utils;
use Iterator::Flex::Base;
use Role::Tiny;

use namespace::clean;

=method freeze

  $freeze = $iter->freeze;

Returns a recipe to freeze an iterator and its dependencies.  See
L<Iterator::Flex/"Serialization of Iterators"> for more information.

=cut

sub freeze {

    my $obj        = $_[0];
    my $attributes = $REGISTRY{ refaddr $obj };

    my @freeze;

    if ( defined $attributes->{_depends} ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { !$_->can( 'freeze' ) }
        @{ $attributes->{_depends} };
        if ( $cant ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "dependency: @{[ $cant->{name} ]} is not serializeable\n" );
        }

        # now freeze them
        @freeze = map $_->freeze, @{ $attributes->{_depends} };
    }

    push @freeze, $attributes->{freeze}->( $obj ), $attributes->{is_exhausted};

    return \@freeze;
}

1;

# COPYRIGHT
