#! perl

use Test2::V0;

use Iterator::Flex 'iterator';


my @data = ( 0 .. 10 );

my $iter = iterator {

    pop @data;

} methods => { now => sub {

                   isa_ok( $_[0], [ 'Iterator::Flex::Base' ], 'initial arg is object' );
                   $data[-1]
               } };


is ( $iter->next, 10, "first value" );
is ( $iter->now, 9, "method call" );


done_testing;
