package Iterator::Flex::Role::Next::ClosedSelf;

# ABSTRACT: Role for closure iterator which closes over self

use strict;
use warnings;

our $VERSION = '0.11';

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
    my $set_self = $attributes->{set_self}
      // $class->_croak( "Missing 'set_self' attribute" );
    Scalar::Util::weaken $attributes->{next};
    $set_self->( $sub );
    return $sub;
}

1;

# COPYRIGHT
