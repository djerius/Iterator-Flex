package Iterator::Flex::Role::Current::Closure;

# ABSTRACT: Implement C<current> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.16';

use Iterator::Flex::Utils qw( :default ITERATOR CURRENT );
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current ( $self ) {
    $REGISTRY{ refaddr $self }{ +ITERATOR }{ +CURRENT }->( $self );
}
*__current__ = \&current;

1;

# COPYRIGHT
