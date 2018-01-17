package Iterator::Flex::Iterator::Role::ExhaustedUndef;

# ABSTRACT: Role to add throw on exhaustion to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.02';

use Role::Tiny;
use Iterator::Flex::Constants;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is signalled by returning an C<undef> value.
It changes the iterator state to C<EXHAUSTED> if it is exhausted.

=cut

sub next {
    local $_ = $_[0];

    $_->{state} = Iterator::Flex::Constants::ACTIVE if $_->{state} == Iterator::Flex::Constants::INACTIVE;
    my $val = $_->{next}->();
    $_->{state} = Iterator::Flex::Constants::EXHAUSTED unless defined $val;
    $val;
}

*__next__ = \&next;

1;
