package Iterator::Flex::Role::ExhaustedPredicate;

# ABSTRACT: Role for iterator which sets the is_exhausted predicate.

use strict;
use warnings;

our $VERSION = '0.10';

use Ref::Util qw[ is_coderef ];
use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for iterator next callback optimized for the case where
the iterator itself indicates it is exhausted by calling the C<set_exhausted> method

=cut

sub _construct_next {

    # my $class = shift;
    shift;
    my $attributes = shift;

    my $next = $attributes->{next};

    my $sub;

    # if we can store self directly, let's do that
    if ( is_coderef( $attributes->{ set_self } ) ) {
	$attributes->{set_self}->( $next );
	$sub = $next;
    }

    # otherwise, need to wrap and pass $self
    else {
	Scalar::Util::weaken $next;

        my $wsub;
        $wsub = sub { $next->( $wsub)  };

        # create a second reference to $wsub, before we weaken it,
        # otherwise it will lose its contents, as it would be the only
        # reference.

        $sub = $wsub;
        Scalar::Util::weaken( $wsub );
    }

    return $sub;
}

sub next { &{$_[0]} }

*__next__ = \&next;

1;
