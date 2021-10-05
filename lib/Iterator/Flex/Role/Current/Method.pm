package Iterator::Flex::Role::Current::Method;

# ABSTRACT: Implement C<current> as a method

use strict;
use warnings;

our $VERSION = '0.13';

use Role::Tiny;

use namespace::clean;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

requires 'current';

*__current__ = \&current;

1;

# COPYRIGHT
