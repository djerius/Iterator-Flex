#! perl

use Test2::V0;

use Iterator::Flex qw[ iproduct thaw ];

subtest "basic" => sub {

    subtest "unlabeled iterators" => sub {
        my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

        subtest "object properties" => sub {

            my @methods = ( 'rewind', 'freeze' );
            isa_ok(
                $iter,
                ['Iterator::Flex::Iterator'],
                "correct parent class"
            );
            can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
        };

        subtest "values" => sub {

            my @values = map { <$iter> }  1..4;

            is( $iter->next, undef, "iterator exhausted" );

            is(
                \@values,
                [ [ 0, 2 ], [ 0, 3 ], [ 1, 2 ], [ 1, 3 ] ],
                "values are correct"
            );

        };

    };

    subtest "labeled iterators" => sub {
        my $iter = iproduct( a => [ 0, 1 ], b => [ 2, 3 ] );

        subtest "values" => sub {
            my @values = map { <$iter> }  1..4;

            is( $iter->next, undef, "iterator exhausted" );

            is(
                \@values,
               [ { a=> 0, b => 2 }, { a => 0, b => 3 }, { a => 1, b => 2 }, { a => 1, b => 3 } ],
                "values are correct"
            );

        };

    };

};


subtest "rewind" => sub {

    my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

    subtest "values" => sub {
        my @values = map { <$iter> }  1..4;

        is( $iter->next, undef, "iterator exhausted" );

        is(
           \@values,
           [ [ 0, 2 ], [ 0, 3 ], [ 1, 2 ], [ 1, 3 ] ],
           "values are correct"
          );
    };

    try_ok { $iter->rewind } "rewind";

    subtest "rewound values" => sub {

        my @values = map { <$iter> }  1..4;

        is( $iter->next, undef, "iterator exhausted" );
        is(
           \@values,
           [ [ 0, 2 ], [ 0, 3 ], [ 1, 2 ], [ 1, 3 ] ],
           "values are correct"
          );
    };

};

subtest "freeze" => sub {

    my @values;
    my $freeze;

    subtest "setup iter and pull some values" => sub {
        my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

        @values = map { <$iter> } 1..2;

        is( \@values, [ [0, 2], [0, 3] ], "values are correct" );
        try_ok { $freeze = $iter->freeze } "freeze iterator";
    };

    subtest "thaw" => sub {
        my $iter;
        try_ok { $iter = thaw( $freeze ) } "thaw iterator";

        push @values, map { <$iter> } 1..2;

        is(
           \@values,
           [ [ 0, 2 ], [ 0, 3 ], [ 1, 2 ], [ 1, 3 ] ],
           "values are correct"
          );
        is( $iter->next, undef, "iterator exhausted" );
    };

};


done_testing;
