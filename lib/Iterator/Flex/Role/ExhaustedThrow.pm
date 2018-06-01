package Iterator::Flex::Role::ExhaustedThrow;

# ABSTRACT: Role to add throw on exhaustion to an Iterator::Flex::Base

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use Role::Tiny;

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
        Iterator::Flex::Failure::Exhausted->throw
            if ! defined $val && $attributes->{is_exhausted};
        $val;
    };

    # create a second reference to the subroutine before we weaken $sub,
    # otherwise $sub will lose its contents, as it would be the only
    # reference.
    my $rsub = $sub;
    Scalar::Util::weaken( $sub );
    return $rsub;
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
