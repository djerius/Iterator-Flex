package Iterator::Flex::Iterator::Role::ExhaustedUndef;

# ABSTRACT: Role to add throw on exhaustion to an Iterator::Flex::Iterator

use strict;
use warnings;

our $VERSION = '0.04';

use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is signalled by returning an C<undef> value.
It changes the iterator state to C<EXHAUSTED> if it is exhausted.

=cut

sub _construct_next {

    my $class = shift;
    my $self = shift;

    my $sub;
    my $next = $self->{next};

    $sub = sub {
        my $val = $next->( $sub );
        $self->{is_exhausted} = ! defined $val;
        $val;
    }
}

sub next { &{$_[0]} }

*__next__ = \&next;

1;
