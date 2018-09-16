package Iterator::Flex::Role::ExhaustedPredicate;

# ABSTRACT: Role for iterator which sets the is_exhausted predicate.

use strict;
use warnings;

our $VERSION = '0.10';

use Ref::Util;
use Scalar::Util;
use Role::Tiny;

=method next

=method __next__

   $iterator->next;

Wrapper for an iterator whose next method invokes C<set_exhausted> 

=cut

sub _construct_next {

    # my $class = shift;
    shift;
    my $attributes = shift;

    my $sub;

    # if we can store self directly, let's do that
    if ( Ref::Util::is_coderef( $attributes->{ set_self } ) ) {
        $sub = $attributes->{next};
	Scalar::Util::weaken $attributes->{next};
        $attributes->{set_self}->( $sub );
    }

    # otherwise, need to wrap and pass $self
    else {
	my $next = $attributes->{next};
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
