package Iterator::Flex::Iterator::Role::ExhaustedPredicate;

# ABSTRACT: Role for iterator which sets the is_exhausted predicate

use strict;
use warnings;

our $VERSION = '0.04';

use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
the iterator itself indicates it is exhausted by calling the C<set_exhausted> method

=cut

sub next {
    local $_ = $_[0];
    $_->{next}->();
}

*__next__ = \&next;

1;
