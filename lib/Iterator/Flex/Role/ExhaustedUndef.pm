package Iterator::Flex::Role::ExhaustedUndef;

# ABSTRACT: Role to wrap next() to set is_exhausted flag when next() returns undef

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
iterator exhaustion is signalled by returning an C<undef> value.
This sets the iterator object's C<is_exhausted> predicate.

=cut

sub _construct_next {

    # my $class = shift;
    shift;
    my $attributes = shift;

    # ensure we don't hold any strong references in the subroutine
    my $next = $attributes->{next};
    Scalar::Util::weaken $next;

    my $sub;
    $sub = sub {
        my $val = $next->( $sub );
        $attributes->{is_exhausted} = ! defined $val;
        $val;
    };

    # create a second reference to the subroutine before we weaken $sub,
    # otherwise $sub will lose its contents, as it would be the only
    # reference.
    my $rsub = $sub;
    Scalar::Util::weaken( $sub );
    return $rsub;
}

sub next { &{$_[0]} }

*__next__ = \&next;

1;
