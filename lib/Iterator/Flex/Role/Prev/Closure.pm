package Iterator::Flex::Role::Prev::Closure;

# ABSTRACT: Implement C<prev> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.16';

use Iterator::Flex::Utils qw( :default ITERATOR PREV );
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev ( $self ) {
    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +PREV }->( $self );
}
*__prev__ = \&prev;

1;

# COPYRIGHT
