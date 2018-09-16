package Iterator::Flex::Role::ExhaustedThrow;

# ABSTRACT: Role to add throw on exhaustion to an iterator which sets is_exhausted.

use strict;
use warnings;

our $VERSION = '0.10';

use Scalar::Util;
use Role::Tiny;

sub _construct_next {

    # my $class = shift;
    shift;
    my $attributes = shift;

    my $next = $attributes->{next};

    # if we can store self directly, let's do that
    if ( is_coderef( $attributes->{ set_self } ) ) {
        $attributes->{set_self}->( $next );
    }

    # ensure we don't hold any strong references in the subroutine
    Scalar::Util::weaken $next;

    # this will be weakened latter.
    my $wsub;
    $wsub = sub {
        my $val = $next->( $wsub );
        Iterator::Flex::Failure::Exhausted->throw
            if ! defined $val && $attributes->{is_exhausted};
        $val;
    };

    # create a second reference to $wsub, before we weaken it,
    # otherwise it will lose its contents, as it would be the only
    # reference.

    my $sub = $wsub;
    Scalar::Util::weaken( $wsub );
    return $sub;
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
