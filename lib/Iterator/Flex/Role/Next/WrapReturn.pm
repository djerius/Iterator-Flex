package Iterator::Flex::Role::Next::WrapReturn;

# ABSTRACT: wrap imported iterator which returns a sentinel on exhaustion

use strict;
use warnings;

our $VERSION = '0.11';

use Iterator::Flex::Utils qw( :default RETURNS_ON_EXHAUSTION );
use Scalar::Util;
use Role::Tiny;

around _construct_next => sub {

    my $orig = shift;
    my $attr = $_[-1];
    my $next = $orig->( @_ );

    # this will be weakened latter.
    my $wsub;

    Iterator::Flex::Utils::_croak( "internal error: no sentinel " )
      unless exists $attr->{ +RETURNS_ON_EXHAUSTION };

    my $sentinel = $attr->{ +RETURNS_ON_EXHAUSTION };

    # undef
    if ( !defined $sentinel ) {
        $wsub = sub {
            my $val = $next->( $_[0] );
            return !defined $val ? $_[0]->signal_exhaustion : $val;
        };
    }

    # reference
    elsif ( ref $sentinel ) {
        my $sentinel = refaddr $sentinel;

        $wsub = sub {
            my $val  = $next->( $_[0] );
            my $addr = refaddr $val;
            return defined $addr
              && $addr == $sentinel ? $_[0]->signal_exhaustion : $val;
        };
    }

    # number
    elsif ( Scalar::Util::looks_like_number( $sentinel ) ) {
        $wsub = sub {
            my $val = $next->( $_[0] );
            return defined $val
              && $val == $sentinel ? $_[0]->signal_exhaustion : $val;
        };
    }

    # string
    else {
        $wsub = sub {
            my $val = $next->( $_[0] );
            return defined $val
              && $val eq $sentinel ? $_[0]->signal_exhaustion : $val;
        };
    }

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
