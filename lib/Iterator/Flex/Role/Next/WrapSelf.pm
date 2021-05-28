package Iterator::Flex::Role::Next::WrapSelf;

# ABSTRACT: Construct a next() method for iterators which handle exhaustion

use strict;
use warnings;

our $VERSION = '0.12';

use Scalar::Util;
use Role::Tiny;

use namespace::clean;

sub _construct_next {

    # my $class = shift;
    shift;
    my $ipar = shift;

    # ensure we don't hold any strong references in the subroutine
    my $next = $ipar->{next};
    Scalar::Util::weaken $next;

    my $sub;
    $sub = sub { $next->( $sub ) };

    # create a second reference to the subroutine before we weaken $sub,
    # otherwise $sub will lose its contents, as it would be the only
    # reference.
    my $rsub = $sub;
    Scalar::Util::weaken( $sub );
    return $rsub;
}

1;

# COPYRIGHT
