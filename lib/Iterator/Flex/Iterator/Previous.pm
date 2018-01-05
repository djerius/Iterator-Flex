package Iterator::Flex::Iterator::Previous;

# ABSTRACT: Role to add prev method to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.02';

use Role::Tiny;

=method prev

=method __prev__

   $iterator->prev;

Returns the previous value.

=cut

sub prev { goto $_[0]->{prev} }
*__prev__ = \&prev;


1;
