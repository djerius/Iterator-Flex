package Iterator::Flex::Role::Current::Closure;

# ABSTRACT: Implement C<current> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( :default ITERATOR CURRENT );
use Role::Tiny;

use namespace::clean;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{+CURRENT}->( $_[0] );
}
*__current__ = \&current;

1;

# COPYRIGHT
