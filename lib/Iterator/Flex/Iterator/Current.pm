package Iterator::Flex::Iterator::Current;

# ABSTRACT: Role to add current method to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.03';

use Role::Tiny;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current { local $_ = $_[0]; $_->{current}->() }
*__current__ = \&current;


1;
