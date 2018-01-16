#! perl

use Test2::V0;

use Iterator::Flex qw[ iseq ifreeze thaw ];
use Data::Dump 'pp';

sub _test_values {

    my $iter = shift;

    my %p = (
        pull_end   => 6,
        pull_begin => 1,
        begin      => 0,
        end        => 5,
        expected   => [
            [ undef, undef, 0, ],
            [ undef, 0,     1 ],
            [ 0,     1,     2 ],
            [ 1,     2,     3 ],
            [ 2,     3,     undef ],
            [ 3,     undef, undef ],
        ],
        @_
    );


    my @values
      = map { [ $iter->prev, $iter->current, $iter->next ] }
      $p{pull_begin} .. $p{pull_end};

    my @expected = ( @{ $p{expected} } )[ $p{begin} .. $p{end} ];

    is( \@values, \@expected, "values are correct" )
      or diag pp( \@values, \@expected );
}


subtest "basic" => sub {

    my $iter = ifreeze {} iseq( 3 );

    subtest "object properties" => sub {

        my @methods = ( 'rewind', 'prev', 'reset', 'current' );
        isa_ok( $iter, ['Iterator::Flex::Iterator'], "correct parent class" );
        can_ok( $iter, \@methods, join( ' ', "has", @methods ) );
    };

    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );

};

subtest "reset" => sub {

    my $iter = ifreeze {} iseq( 3 );

    1 while <$iter>;

    try_ok { $iter->reset } "reset";

    _test_values( $iter );
    is( $iter->next, undef, "iterator exhausted" );
    ok( $iter->is_exhausted, "iterator exhausted (officially)" );
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
                _test_values( thaw( $freeze[$idx] ),
                              pull_begin => $idx + 2,
                              begin => $idx + 1,
                            );
            },
            $_
        );
    }

};


done_testing;
