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

    my $wsub;
    $wsub = sub {
        my $val = eval { $next->( $_[0] ) };
        return $@ eq '' ? $val : $_[0]->signal_exhaustion;
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
