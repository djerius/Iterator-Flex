#! perl

use Test2::V0;

use Iterator::Flex qw[ iproduct thaw ];

sub _test_values {

    my $iter = shift;
    my $npull = shift || 6;
    my ( $begin, $end );

    defined( $begin = shift ) or $begin = 0;
    defined( $end   = shift ) or $end   = 5;

    my @values = map { [ $iter->current, $iter->next ] } 1 .. $npull;

    my @expected = (
        [ undef, [ 0, 2 ] ],
        [ [ 0, 2 ], [ 0, 3 ] ],
        [ [ 0, 3 ], [ 1, 2 ] ],
        [ [ 1, 2 ], [ 1, 3 ] ],
        [ [ 1, 3 ], undef ],
        [ undef, undef ],
    )[ $begin .. $end ];

    is( \@values, \@expected, "values are correct" )
      or do { use Data::Dump 'pp'; diag pp( \@values ) };
}

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

            _test_values( $iter );
            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );
        };

    };

    subtest "labeled iterators" => sub {
        my $iter = iproduct( a => [ 0, 1 ], b => [ 2, 3 ] );

        subtest "values" => sub {
            my @values = map { [ $iter->current, $iter->next ] } 1 .. 6;

            is( $iter->next, undef, "iterator exhausted" );
            ok( $iter->is_exhausted, "iterator exhausted (officially)" );

            is(
                \@values,
                [
                    [ undef, { a => 0, b => 2 } ],
                    [ { a => 0, b => 2 }, { a => 0, b => 3 } ],
                    [ { a => 0, b => 3 }, { a => 1, b => 2 } ],
                    [ { a => 1, b => 2 }, { a => 1, b => 3 } ],
                    [ { a => 1, b => 3 }, undef ],
                    [ undef, undef ],
                ],
                "values are correct"
            ) or do { use Data::Dump 'pp'; diag pp( \@values ) };

        };

    };

};


subtest "rewind" => sub {

    my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

    1 while <$iter>;

    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

    try_ok { $iter->rewind } "rewind";


    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

};

subtest "freeze" => sub {

    my $freeze;

    subtest "setup iter and pull some values" => sub {
        my $iter = iproduct( [ 0, 1 ], [ 2, 3 ] );

        _test_values( $iter, 2, 0, 1 );

        try_ok { $freeze = $iter->freeze } "freeze iterator";
    };

    use Data::Dump; dd $freeze;

    subtest "thaw" => sub {
        my $iter;
        try_ok { $iter = thaw( $freeze ) } "thaw iterator";

        _test_values( $iter, 4, 2, 5 );

        is( $iter->next, undef, "iterator exhausted" );
        ok( $iter->is_exhausted, "iterator exhausted (officially)" );
    };

};


done_testing;
