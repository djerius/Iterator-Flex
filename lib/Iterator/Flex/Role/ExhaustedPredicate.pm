package Iterator::Flex::Role::ExhaustedPredicate;

# ABSTRACT: Role for iterator which sets the is_exhausted predicate

use strict;
use warnings;

our $VERSION = '0.04';

use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
the iterator itself indicates it is exhausted by calling the C<set_exhausted> method

=cut

sub _construct_next {

    my $class = shift;
    my $self = shift;

    # ensure we don't hold any strong references in the subroutine
    my $next = $self->{next};
    Scalar::Util::weaken $next;

    my $sub;
    $sub = sub { $next->( $sub)  };

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
