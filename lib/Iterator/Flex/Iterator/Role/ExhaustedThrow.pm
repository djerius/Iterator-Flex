package Iterator::Flex::Iterator::Role::ExhaustedThrow;

# ABSTRACT: Role to add throw on exhaustion to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Scalar::Util;
use Role::Tiny;

sub _construct_next {

    my $class = shift;
    my $self = shift;

    my $sub;
    my $next = $self->{next};

    $sub = sub {
        my $val = $next->( $sub );
        Iterator::Flex::Failure::Exhausted->throw
            if $self->{is_exhausted};
        $val;
    }
}

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is signalled by throwing an exception.  The
C<next> callback must set the iterator state to C<EXHAUSTED>.

=cut

sub next { &{$_[0]} }
*__next__ = \&next;


1;
