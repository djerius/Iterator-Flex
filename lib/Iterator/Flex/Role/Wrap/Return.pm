package Iterator::Flex::Role::Wrap::Return;

# ABSTRACT: wrap imported iterator which returns a sentinel on exhaustion

use strict;
use warnings;

our $VERSION = '0.12';

use Iterator::Flex::Utils qw( :default INPUT_EXHAUSTION );
use Scalar::Util;
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

around _construct_next => sub ( $orig, $class, $ipar, $gpar ) {

    my $next  = $class->$orig( $ipar, $gpar );

    # this will be weakened latter.
    my $wsub;

    my $sentinel = (
        $gpar->{ +INPUT_EXHAUSTION } // do {
            require Iterator::Flex::Failure;
            Iterator::Flex::Failure::parameter->throw(
                "internal error: input exhaustion policy was not registered" );
          }
    )->[1];

    # undef
    if ( !defined $sentinel ) {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val = $next->( $self );
            return !defined $val ? $self->signal_exhaustion : $val;
        };
    }

    # reference
    elsif ( ref $sentinel ) {
        my $sentinel = refaddr $sentinel;

        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val  = $next->( $self );
            my $addr = refaddr $val;
            return defined $addr
              && $addr == $sentinel ? $self->signal_exhaustion : $val;
        };
    }

    # number
    elsif ( Scalar::Util::looks_like_number( $sentinel ) ) {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val = $next->( $self );
            return defined $val
              && $val == $sentinel ? $self->signal_exhaustion : $val;
        };
    }

    # string
    else {
        $wsub = sub {
            my $self = $_[0] // $wsub;
            my $val = $next->( $_[0] );
            return defined $val
              && $val eq $sentinel ? $self->signal_exhaustion : $val;
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
