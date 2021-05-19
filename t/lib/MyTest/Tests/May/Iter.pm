package MyTest::Tests::May::Iter;

use strict;
use warnings;
use Role::Tiny ();

use parent 'Iterator::Flex::Base';

sub construct {
    my $class = shift;
    $class->construct_from_state( @_ );
}

sub construct_from_state {

    my $class = shift;

    my $x;
    return {
        name   => 'prev',
        next   => sub { ++$x },
        rewind => sub { ++$x },
        ( @_ ? ( _depends => [@_] ) : () ),
    };
}

__PACKAGE__->_add_roles( qw[
      Next::NoSelf
      Next
      Rewind
] );


1;
