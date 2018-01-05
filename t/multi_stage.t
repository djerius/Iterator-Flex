#! perl

use Test2::V0;

use Iterator::Flex qw[ igrep imap iarray ];

subtest "basic" => sub {

    my $iter = igrep { $_ >= 12 } imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest "object properties" => sub {

        isa_ok( $iter, ['Iterator::Flex::Iterator'], "correct parent class" );
        can_ok( $iter, [ 'rewind', ], "has rewind" );
        is( $iter->can( 'freeze'), undef, "can't freeze" );
    };

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 12, 22 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };
};

subtest "rewind" => sub {

    my $iter = igrep { $_ >= 10 } imap { $_ + 2 } iarray( [ 0, 10, 20 ] );

    subtest "values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 12, 22 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };

    try_ok { $iter->rewind } "rewind";

    subtest "rewound values" => sub {
        my @values;
        push @values, <$iter>;
        push @values, <$iter>;
        is( \@values, [ 12, 22 ], "values are correct" );
        is( $iter->next, undef, "iterator exhausted" );
    };

};


done_testing;
