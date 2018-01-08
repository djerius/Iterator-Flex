#! perl

use Test2::V0;

use Iterator::Flex qw[ iseq ifreeze thaw ];

sub _test_values {

    my $iter = shift;
    my $start = shift || 0;

    my @values = map { [ $iter->prev, $iter->next ] } $start .. 4;
    my @expected
      = ( [ undef, 0 ], [ 0, 1 ], [ 1, 2 ], [ 2, 3 ], [ 3, undef ] )
      [ $start .. 4 ];

    is( $iter->next, undef, "iterator exhausted" );

    is( \@values, \@expected, "values are correct" );
}


subtest "basic" => sub {

    my $iter = ifreeze {} iseq( 3 );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'prev' );
        isa_ok( $iter, ['Iterator::Flex::Iterator'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    subtest "values" => sub { _test_values( $iter ) };
};

subtest "rewind" => sub {

    my $iter = ifreeze {} iseq( 3 );

    1 while <$iter>;

    try_ok { $iter->rewind } "rewind";

    subtest "rewound values" => sub { _test_values( $iter ) };

};

subtest "serialize" => sub {

    my @freeze;

    my $iter = ifreeze { push @freeze, $_ } iseq( 3 );

    1 while <$iter>;

    is( scalar @freeze, 5, "number of frozen states" );

    for ( 0 .. 4 ) {
        subtest(
            "thaw state $_" => sub {
                my $idx = shift;
                _test_values( thaw( $freeze[$idx] ), $idx + 1 );
            },
            $_
        );
    }

};


done_testing;
