package Iterator::Flex::Role::Next::ClosedSelf;

# ABSTRACT: Role for closure iterator which closes over self

use strict;
use warnings;

our $VERSION = '0.12';

use Ref::Util;
use Scalar::Util;
use Role::Tiny;

use namespace::clean;

=method next

=method __next__

   $iterator->next;

=cut

sub _construct_next {

    # my $class = shift;
    shift;
    my $ipar = shift;

    my $sub = $ipar->{next} // do {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw( "Missing 'next' parameter" );
    };

    Scalar::Util::weaken $ipar->{next};

    if ( exists $ipar->{_self} ) {
        my $ref = $ipar->{_self};
        $$ref = $sub;
        Scalar::Util::weaken $$ref;
    }
    else {
        require Iterator::Flex::Failure;
        Iterator::Flex::Failure::parameter->throw(
            "Missing ability to set self" );
    }

    return $sub;
}

1;

# COPYRIGHT
