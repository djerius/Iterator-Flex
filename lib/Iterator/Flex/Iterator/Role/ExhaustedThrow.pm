package Iterator::Flex::Iterator::Role::ExhaustedThrow;

# ABSTRACT: Role to add throw on exhaustion to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is signalled by throwing an exception.  The
C<next> callback must set the iterator state to C<EXHAUSTED>.

=cut

sub next {
    local $_ = $_[0];

    my $val = $_->{next}->();
    Iterator::Flex::Failure::Exhausted->throw
        if $_->{is_exhausted};

    $val;
}

*__next__ = \&next;


1;
