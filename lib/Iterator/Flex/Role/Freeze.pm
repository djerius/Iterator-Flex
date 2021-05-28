package Iterator::Flex::Role::Freeze;

# ABSTRACT: Role to add serialization capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use List::Util;

use Iterator::Flex::Utils qw( :default ITERATOR );
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
    my $ipar = $REGISTRY{ refaddr $obj }{+ITERATOR};

    my @freeze;

    if ( defined $ipar->{_depends} ) {

        # first check if dependencies can freeze.
        my $cant = List::Util::first { !$_->can( 'freeze' ) }
        @{ $ipar->{_depends} };
        if ( $cant ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "dependency: @{[ $cant->{_name} ]} is not serializeable\n" );
        }

        # now freeze them
        @freeze = map $_->freeze, @{ $ipar->{_depends} };
    }

    push @freeze, $ipar->{freeze}->( $obj ), $obj->is_exhausted;

    return \@freeze;
}

requires 'is_exhausted';

1;

# COPYRIGHT
