#! perl

use Test2::V0;

use Iterator::Flex qw[ iseq thaw ];

my @tests = (

    {
        name => "begin",
        args => [3],
        expected =>
          [ [ undef, 0 ], [ 0, 1 ], [ 1, 2 ], [ 2, 3 ], [ 3, undef ] ],
    },
    {
        name => "begin, end",
        args => [1, 5],
        expected =>
          [ [ undef, 1 ], [ 1, 2 ], [ 2, 3 ], [ 3, 4 ], [ 4, 5 ], [ 5, undef ] ],
    },
    {
        name => "begin, end, step",
        args => [1, 2.2, 0.5],
        expected =>
          [ [ undef, 1 ], [ 1, 1.5 ], [ 1.5, 2 ], [ 2, undef ] ],
    },

);

for my $test ( @tests ) {

    my ( $args, $expected ) = @{$test}{qw [ args expected ]};

    my $split = @$expected / 2;

    subtest $test->{name} => sub {

        subtest "iseq(end)" => sub {

            my $iter = iseq( @$args );

            subtest "object properties" => sub {

                my @methods = ( 'rewind', 'freeze', 'prev' );
                isa_ok(
                    $iter,
                    ['Iterator::Flex::Iterator'],
                    "correct parent class"
                );
                can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
            };

            subtest "prev, next" => sub {

                my @values
                  = map { [ $iter->prev, $iter->next ] } 1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );

                is( \@values, $expected, "values are correct" );
            };

            subtest "rewind" => sub {
                try_ok { $iter->rewind } "rewind";

                my @values
                  = map { [ $iter->prev, $iter->next ] } 1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );

                is( \@values, $expected, "values are correct" );
            };

        };

        subtest "freeze" => sub {

            my @values;
            my $freeze;
            subtest "setup iter and pull some values" => sub {

                my $iter = iseq( @$args );

                @values = map { [ $iter->prev, $iter->next ] } 1 .. $split;

                is(
                    \@values,
                    [ @{$expected}[ 0 .. $split - 1 ] ],
                    "values are correct"
                );

                try_ok { $freeze = $iter->freeze } "freeze iterator";
            };

            subtest "thaw" => sub {
                my $iter;
                try_ok { $iter = thaw( $freeze ) } "thaw iterator";

                push @values,
                  map { [ $iter->prev, $iter->next ] } $split+1 .. @$expected;

                is( $iter->next, undef, "iterator exhausted" );

                is( \@values, $expected, "values are correct" );
            };

        };

    };

}

done_testing;
