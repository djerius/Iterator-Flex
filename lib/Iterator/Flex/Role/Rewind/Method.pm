package Iterator::Flex::Role::Rewind::Method;

# ABSTRACT: Implement C<rewind> as a method

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

use namespace::clean;

=method rewind

=method __rewind__

   $iterator->rewind;

Rewind the iterator.

=cut

around rewind => sub {
    my $orig = shift;
    my $self  = shift;
    $self->_apply_method_to_depends( 'rewind' );

    $self->$orig;
    $self->_clear_state;

    return;
}
*__rewind__ = \&rewind;


requires 'rewind';
requires '_clear_state';

1;

# COPYRIGHT
