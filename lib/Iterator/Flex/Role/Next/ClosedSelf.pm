package Iterator::Flex::Role::Next::ClosedSelf;

# ABSTRACT: Role for closure iterator which closes over self

use strict;
use warnings;

our $VERSION = '0.12';

use Ref::Util;
use Scalar::Util;
use Role::Tiny;
use Iterator::Flex::Utils qw( NEXT _SELF );

use namespace::clean;

=method next

=method __next__

   $iterator->next;

=cut

sub _construct_next {
    my $class = shift;
    my $ipar = shift;

    my $sub = $ipar->{+NEXT} // $class->_throw( parameter =>  "Missing 'next' parameter" );
    Scalar::Util::weaken $ipar->{+NEXT};

    $class->_throw( parameter =>  "Missing ability to set self" )
      unless exists $ipar->{+_SELF};

    my $ref = $ipar->{+_SELF};
    $$ref = $sub;
    Scalar::Util::weaken $$ref;
    return $sub;
}

sub next { &{ $_[0] } }
*__next__ = \&next;

1;

# COPYRIGHT
