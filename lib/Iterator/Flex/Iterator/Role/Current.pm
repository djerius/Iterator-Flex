package Iterator::Flex::Iterator::Role::Current;

# ABSTRACT: Role to add current method to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Role::Tiny;

=method current

=method __current__

   $iterator->current;

Returns the current value.

=cut

sub current {

    my $self = $Iterator::Flex::Iterator::REGISTRY{ Scalar::Util::refaddr $_[0] };

    $self->{current}->( $_[0] );
}
*__current__ = \&current;


1;
