package Iterator::Flex::Role::Next::WrapReturn;

# ABSTRACT: Role to add throw on exhaustion to an iterator which sets is_exhausted.

use strict;
use warnings;

our $VERSION = '0.11';

use Iterator::Flex::Utils;
use Scalar::Util;
use Role::Tiny;

around _construct_next => sub {

    my $orig = shift;

    my $next = $orig->( @_ );

    # this will be weakened latter.
    my $wsub;
    $wsub = sub {
        my $val = $next->( $_[0] );

        Iterator::Flex::Utils::_croak( "internal error: no registered sentinel ")
            unless exists $REGISTRY{ refaddr $_[0] };
        my $sentinel = $REGISTRY{ refaddr $_[0] };

        if ( !defined $val ) {
            return ! defined $sentinel ? $_[0]->signal_exhaustion : $val;
        }
        else {
            return defined $sentinel && $val == $sentinel ? $_[0]->signal_exhaustion : $val;
        }

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
