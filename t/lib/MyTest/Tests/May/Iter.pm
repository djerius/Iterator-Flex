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

    return {
        name   => 'prev',
        next   => sub { },
        rewind => sub { },
        ( @_ ? ( depends => [ @_ ] ) : () ),
    };
}

__PACKAGE__->_add_roles( qw[
      ExhaustedPredicate
      Rewind
] );


1;
