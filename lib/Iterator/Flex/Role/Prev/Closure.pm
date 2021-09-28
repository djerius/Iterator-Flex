package Iterator::Flex::Role::Prev::Closure;

# ABSTRACT: Implement C<prev> as a closure stored in the registry

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( :default ITERATOR );
use Role::Tiny;

use namespace::clean;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev {
     $REGISTRY{ refaddr $_[0] }{+ITERATOR}{prev}->( $_[0] );
}
*__prev__ = \&prev;

1;

# COPYRIGHT
