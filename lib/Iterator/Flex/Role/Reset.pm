package Iterator::Flex::Role::Reset;

# ABSTRACT: Role to add reset capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use List::Util;

use Iterator::Flex::Base ();
use Iterator::Flex::Utils;
use Role::Tiny;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset {

    my $obj = $_[0];

    my $attributes = $REGISTRY{ refaddr $obj };

    if ( defined $attributes->{depends} ) {

        # first check if dependencies can reset.
        my $cant = List::Util::first { !$_->can( 'reset' ) }
        @{ $attributes->{depends} };
        $obj->_croak(
            "dependency: @{[ $cant->{name} ]} does not have a 'reset' method\n"
        ) if $cant;

        # now reset them
        $_->reset foreach @{ $attributes->{depends} };
    }

    $attributes->{reset}->( $obj );
    $attributes->{is_exhausted} = 0;

    return;
}
*__reset__ = \&reset;

around may => Iterator::Flex::Base->_wrap_may( 'reset' );

1;

# COPYRIGHT
