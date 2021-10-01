#! perl

# ABSTRACT: test translation of imported iterators

use strict;
use warnings;

use 5.10.0;

use Test2::V0;

use Iterator::Flex::Common 'iterator';
use Scalar::Util 'refaddr';

subtest 'return' => sub {

    subtest 'undef => 10' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter;

        $iter = iterator { $iter->signal_error if $data[0] == 5; shift @data }
        -pars => { exhaustion => [ return => 11 ] };


        isa_ok(
            dies {
                while ( ( my $data = $iter->() ) != 11 ) { push @got, $data }
            },
            'Iterator::Flex::Failure::Error',
        );

        ok( $iter->is_error, "error flag" );
        is( \@got, [ 1 .. 4 ], "got data" );

    };

};

done_testing;
