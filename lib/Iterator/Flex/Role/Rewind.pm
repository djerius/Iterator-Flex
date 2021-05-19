package Iterator::Flex::Role::Rewind;

# ABSTRACT: Role to add rewind capability to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Base ();
use Iterator::Flex::Utils;
use Role::Tiny;

use namespace::clean;

=method rewind

=method __rewind__

   $iterator->rewind;

Resets the iterator to its initial value.

=cut

sub rewind {

    my $obj        = $_[0];
    my $attributes = $REGISTRY{ refaddr $obj };

    if ( defined $attributes->{_depends} ) {

        if ( ! $obj->_may_meth( 'rewind', $attributes ) ) {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "a dependency is not rewindable\n" );
        }

        # now rewind them
        $_->rewind foreach @{ $attributes->{_depends} };
    }

    $attributes->{rewind}->( $obj );
    $attributes->{is_exhausted} = 0;

    return;
}
*__rewind__ = \&rewind;

around may => Iterator::Flex::Base->_wrap_may( 'rewind' );

1;

# COPYRIGHT
