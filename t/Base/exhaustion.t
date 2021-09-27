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
        my $iter = iterator { shift @data }
        -pars => { exhaustion => [ return => 11 ] };

        while ( ( my $data = $iter->next ) != 11 ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );

    };


    subtest 'undef => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator { shift @data };

        while ( my $data = $iter->next ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );

    };

    subtest 'integer => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator { shift @data; }
        -pars => { input_exhaustion => [ return => 10 ] };

        while ( ( my $data = $iter->next ) != 10 ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 9 ], "got data" );

    };

    subtest 'string => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator { shift @data // 'A' }
        -pars => { input_exhaustion => [ return => 'A' ] };

        while ( ( my $data = $iter->next ) ne 'A' ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );
    };

    subtest 'reference => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $ref = [];
        my $iter = iterator { shift @data // $ref }
        -pars => { input_exhaustion => [ return => $ref ] };

        my $data;
        while ( $data = $iter->next
            and !( defined refaddr $data && refaddr $data == $ref ) )
        {
            push @got, $data;
        }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );
    };



    subtest 'undef => throw' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator {
            shift @data;
        }
          -pars => { exhaustion => 'throw' } ;

        isa_ok(
            dies {
                while ( my $data = $iter->next ) { push @got, $data }
            },
            ['Iterator::Flex::Failure::Exhausted'],
            "exhaustion"
        );

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );

    };

};

subtest 'throw' => sub {

    subtest 'any => undef' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator {
            die( "exhausted" ) if $data[0] == 9;
            shift @data;
        }
        -pars => {
            input_exhaustion => 'throw',
            exhaustion          => 'return'
        };

        ok(
            lives {
                while ( my $data = $iter->next ) { push @got, $data }
            },
            'iterate to exhaustion'
        );

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 8 ], "got data" );

    };

    subtest 'any => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator {
            die( "exhausted" ) if $data[0] == 9;
            shift @data;
        }
        -pars => { input_exhaustion => 'throw' };

        like(
            dies {
                while ( my $data = $iter->next ) { push @got, $data }
            },
            qr/exhausted/,
            "exhaustion"
        );

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 8 ], "got data" );
    };

    subtest 'regexp' => sub {

        subtest 'exhausted' => sub {

            my @data = ( 1 .. 10, undef );
            my @got;
            my $iter = iterator {
                die( "exhausted" ) if $data[0] == 9;
                shift @data;
            }
            -pars => {
                input_exhaustion => [ throw => qr/exhausted/ ],
                exhaustion          => 'throw'
            };

            isa_ok(
                dies {
                    while ( defined( my $data = $iter->next ) ) {
                        push @got, $data;
                    }
                },
                ['Iterator::Flex::Failure::Exhausted'],
                "exhaustion"
            );

            ok( $iter->is_exhausted, "exhausted flag" );
            is( \@got, [ 1 .. 8 ], "got data" );

        };

        subtest 'died' => sub {

            my @data = ( 1 .. 10, undef );
            my @got;
            my $iter = iterator {
                die( "died" ) if $data[0] == 9;
                shift @data;
            }
            -pars => {
                input_exhaustion => [ throw => qr/exhausted/ ],
                exhaustion          => 'throw'
            };

            like(
                dies {
                    while ( defined( my $data = $iter->next ) ) {
                        push @got, $data;
                    }
                },
                qr/died/,
                "died"
            );

            ok( !$iter->is_exhausted, "exhausted flag" );
            is( \@got, [ 1 .. 8 ], "got data" );

        };

    };

    subtest 'coderef' => sub {

        subtest 'exhausted' => sub {

            my @data = ( 1 .. 10, undef );
            my @got;
            my $iter = iterator {
                die( "exhausted" ) if $data[0] == 9;
                shift @data;
            }
            -pars => {
                input_exhaustion =>
                  [ throw => sub { $_[0] =~ 'exhausted' } ],
                exhaustion => 'throw'
            };

            isa_ok(
                dies {
                    while ( defined( my $data = $iter->next ) ) {
                        push @got, $data;
                    }
                },
                ['Iterator::Flex::Failure::Exhausted'],
                "exhaustion"
            );

            ok( $iter->is_exhausted, "exhausted flag" );
            is( \@got, [ 1 .. 8 ], "got data" );

        };

        subtest 'died' => sub {

            my @data = ( 1 .. 10, undef );
            my @got;
            my $iter = iterator {
                die( "died" ) if $data[0] == 9;
                shift @data;
            }
            -pars => {
                input_exhaustion =>
                  [ throw => sub { $_[0] =~ 'exhausted' } ],
                exhaustion => 'throw'
            };

            like(
                dies {
                    while ( defined( my $data = $iter->next ) ) {
                        push @got, $data;
                    }
                },
                qr/died/,
                "died"
            );

            ok( !$iter->is_exhausted, "exhausted flag" );
            is( \@got, [ 1 .. 8 ], "got data" );

        };

    };

};

done_testing;
