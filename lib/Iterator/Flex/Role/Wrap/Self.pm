package Iterator::Flex::Role::Wrap::Self;

# ABSTRACT: Construct a next() method for a coderef which expects to be passed an object ref

# is this actually used?

use strict;
use warnings;

our $VERSION = '0.14';

use Scalar::Util;
use Iterator::Flex::Utils 'NEXT';

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

sub _construct_next ( $, $ipar, $ ) {

    # ensure we don't hold any strong references in the subroutine
    my $next = $ipar->{+NEXT};
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
