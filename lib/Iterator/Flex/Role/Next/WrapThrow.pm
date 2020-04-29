package Iterator::Flex::Role::Next::WrapThrow;

# ABSTRACT: Role to add throw on exhaustion to an iterator which sets is_exhausted.

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util;
use Role::Tiny;

around _construct_next => sub {

    my $orig = shift;

    my $next = $orig->( @_ );

    # ensure we don't hold any strong references in the subroutine
    Scalar::Util::weaken $next;

    # this will be weakened latter.
    my $wsub;
    $wsub = sub {
        my $val = eval { $next->( $_[0] ) };
        return $@ ne '' ? $_[0]->signal_exhaustion : $val;
    };

    # create a second reference to $wsub, before we weaken it,
    # otherwise it will lose its contents, as it would be the only
    # reference.

    my $sub = $wsub;
    Scalar::Util::weaken( $wsub );
    return $sub;
};

requires 'signal_exhaustion';

1;

# COPYRIGHT
