package Iterator::Flex::Iterator::ExhaustedThrow;

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
iterator exhaustion is signalled by throwing an exception.  The
C<next> callback must set the iterator state to C<EXHAUSTED>.

=cut

sub next {
    local $_ = $_[0];
    $_->{state} = ACTIVE;
    my $val = $_->{next}->();

    Iterator::Flex::Failure::Exhausted->throw
        if $_->{state} eq EXHAUSTED;

    $val;
}

*__next__ = \&next;


1;
