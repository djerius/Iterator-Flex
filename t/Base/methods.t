#! perl

use Test2::V0;

use Iterator::Flex::Common 'iterator';


my @data = ( 0 .. 10 );

my $iter = iterator {
    pop @data;
}
-pars => {
    methods => {
        now => sub {
            isa_ok( $_[0], ['Iterator::Flex::Base'], 'initial arg is object' );
            $data[-1];
        }
    } };


is( $iter->next, 10, "first value" );
is( $iter->now,  9,  "method call" );

# creating another now method should succeed
my $error;
ok(
    lives {
        $iter = iterator(
            sub { },
            -pars => {
                methods => {
                    now => sub { }
                } } );
    },
    'reuse method name'
) or note $@;

can_ok( $iter, ['now'], "method created for second iterator" );

done_testing;
