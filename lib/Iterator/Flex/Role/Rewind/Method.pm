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
    $self->_reset_exhausted;

    return;
}
*__rewind__ = \&rewind;

around may => Iterator::Flex::Base->_wrap_may( 'rewind' );

requires 'rewind';
requires '_reset_exhausted';

1;

# COPYRIGHT
