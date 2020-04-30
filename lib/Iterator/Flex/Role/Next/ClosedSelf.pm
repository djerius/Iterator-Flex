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

    my $class      = shift;
    my $attributes = shift;

    my $sub = $attributes->{next}
      // $class->_croak( "Missing 'next' attribute" );

    Scalar::Util::weaken $attributes->{next};

    if ( exists $attributes->{self} ) {
        my $ref = $attributes->{self};
        $$ref = $sub;
        Scalar::Util::weaken $$ref;
    }
    else {
        $class->_croak( "Missing ability to set self" );
    }

    return $sub;
}

1;

# COPYRIGHT
