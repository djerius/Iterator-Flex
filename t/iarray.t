#! perl

use Test2::V0;

use Iterator::Flex qw[ iarray thaw ];

subtest "basic" => sub {

    my $iter = iarray( [ 0, 10, 20 ] );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'freeze', 'prev' );
        isa_ok( $iter, ['Iterator::Flex::Iterator'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    subtest "prev, next" => sub {

        my @values = map { [ $iter->prev, $iter->next ] } 1 .. 4;

        is( $iter->next, undef, "iterator exhausted" );

        is(
            \@values,
            [ [ undef, 0 ], [ 0, 10 ], [ 10, 20 ], [ 20, undef ] ],
            "values are correct"
        );


    };
};

subtest "rewind" => sub {

    my $iter = iarray( [ 0, 10, 20 ] );

    subtest "values" => sub {
        my @values = map { <$iter> } 1 .. 3;
        is( $iter->next, undef, "iterator exhausted" );
        is( \@values, [ 0, 10, 20 ], "values are correct" );
    };

    try_ok { $iter->rewind } "rewind";

    subtest "rewound values" => sub {
        my @values = map { <$iter> } 1 .. 3;
        is( $iter->next, undef, "iterator exhausted" );
        is( \@values, [ 0, 10, 20 ], "values are correct" );
    };

};

subtest "freeze" => sub {

    my @values;
    my $freeze;
    subtest "setup iter and pull some values" => sub {
        my $iter = iarray( [ 0, 10, 20 ] );
        push @values, <$iter>;
        is( \@values, [0], "values are correct" );
        try_ok { $freeze = $iter->freeze } "freeze iterator";
    };

    subtest "thaw" => sub {
        my $iter;
        try_ok { $iter = thaw( $freeze ) } "thaw iterator";

        push @values, <$iter> for 1 .. 2;

        is( \@values, [ 0, 10, 20 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };

};


done_testing;
