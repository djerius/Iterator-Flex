package Iterator::Flex::Role::Reset::Method;

# ABSTRACT: Implement C<reset> as a method

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

use namespace::clean;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

around reset => sub {
    my $orig = shift;
    my $self = shift;
    $self->_apply_method_to_depends( 'reset' );

    $self->$orig;
    $self->_reset_exhausted;

    return;
}
*__reset__ = \&reset;


requires 'reset';
requires '_reset_exhausted';
1;

# COPYRIGHT
