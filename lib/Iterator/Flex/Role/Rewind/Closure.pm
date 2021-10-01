package Iterator::Flex::Role::Rewind::Closure;

# ABSTRACT: Implement C<rewind> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Base ();
use Iterator::Flex::Utils qw( :default ITERATOR REWIND );
use Role::Tiny;

use namespace::clean;

=method rewind

=method __rewind__

   $iterator->rewind;

Rewind the iterator;

=cut

sub rewind {

    my $self  = shift;

    $self->_apply_method_to_depends( 'rewind' );

    $REGISTRY{ refaddr $self }{ +ITERATOR }{+REWIND}->( $self );
    $self->_clear_state;

    return;
}
*__rewind__ = \&rewind;


requires '_clear_state';

1;

# COPYRIGHT
