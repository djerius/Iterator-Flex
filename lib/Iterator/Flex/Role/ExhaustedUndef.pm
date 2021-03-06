package Iterator::Flex::Role::ExhaustedUndef;

# ABSTRACT: Role to wrap next() to set is_exhausted flag when next() returns undef

use strict;
use warnings;

our $VERSION = '0.11';

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

    my $wsub;
    $wsub = sub {
        my $val = $next->( $wsub );
        $attributes->{is_exhausted} = !defined $val;
        $val;
    };

    # create a second reference to $wsub, before we weaken it,
    # otherwise it will lose its contents, as it would be the only
    # reference.

    my $sub = $wsub;
    Scalar::Util::weaken( $wsub );
    return $sub;
}

sub next { &{ $_[0] } }

*__next__ = \&next;

1;

# COPYRIGHT
