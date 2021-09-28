package Iterator::Flex::Role::Reset::Closure;

# ABSTRACT: Implement C<reset> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.12';

use Scalar::Util;
use List::Util;

use Iterator::Flex::Base ();
use Iterator::Flex::Utils qw( :default ITERATOR );
use Role::Tiny;

use namespace::clean;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset {
    my $self = shift;
    $self->_apply_method_to_depends( 'reset' );

    $REGISTRY{ refaddr $self }{ +ITERATOR }{reset}->( $self );
    $self->_reset_exhausted;

    return;
}
*__reset__ = \&reset;

around may => Iterator::Flex::Base->_wrap_may( 'reset' );

requires '_reset_exhausted';
1;

# COPYRIGHT
