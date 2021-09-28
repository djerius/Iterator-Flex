package Iterator::Flex::Role::Prev::Method;

# ABSTRACT: Implement C<prev> as a method

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

use namespace::clean;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

requires 'prev';

*__prev__ = \&prev;

1;

# COPYRIGHT
