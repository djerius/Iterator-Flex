package Iterator::Flex::Role::Current;

# ABSTRACT: Role to add current method to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( :default ITERATOR );
use Role::Tiny;

use namespace::clean;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current {
    $REGISTRY{ refaddr $_[0] }{+ITERATOR}{current}->( $_[0] );
}
*__current__ = \&current;

1;

# COPYRIGHT
