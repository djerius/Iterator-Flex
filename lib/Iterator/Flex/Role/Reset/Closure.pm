package Iterator::Flex::Role::Reset::Closure;

# ABSTRACT: Implement C<reset> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.16';

use Scalar::Util;
use List::Util;

use Iterator::Flex::Base  ();
use Iterator::Flex::Utils qw( :default ITERATOR RESET );
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method reset

=method __reset__

   $iterator->reset;

Resets the iterator to its initial value.

=cut

sub reset ( $self ) {
    $self->_apply_method_to_depends( 'reset' );

    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +RESET }->( $self );
    $self->_clear_state;

    return;
}
*__reset__ = \&reset;


requires '_clear_state';
1;

# COPYRIGHT
