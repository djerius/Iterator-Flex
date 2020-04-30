#! perl

# ABSTRACT: test translation of imported iterators

use strict;
use warnings;

use 5.10.0;

use Test2::V0;

use Iterator::Flex 'iterator';
use Scalar::Util 'refaddr';

subtest 'sentinel' => sub {

    subtest 'undef => 10' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator { shift @data }
        on_exhaustion_return => 11;

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
        my $iter = iterator { shift @data; } returns_on_exhaustion => 10;

        while ( ( my $data = $iter->next ) != 10 ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 9 ], "got data" );

    };

    subtest 'string => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $iter = iterator { shift @data // 'A' } returns_on_exhaustion => 'A';

        while ( ( my $data = $iter->next ) ne 'A' ) { push @got, $data }

        ok( $iter->is_exhausted, "exhausted flag" );
        is( \@got, [ 1 .. 10 ], "got data" );
    };

    subtest 'reference => passthrough' => sub {

        my @data = ( 1 .. 10 );
        my @got;
        my $ref = [];
        my $iter
          = iterator { shift @data // $ref } returns_on_exhaustion => $ref;

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
        on_exhaustion_throw => 1;

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
        throws_on_exhaustion   => 1,
          on_exhaustion_return => undef;

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
        throws_on_exhaustion => 1;

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
            throws_on_exhaustion  => qr/exhausted/,
              on_exhaustion_throw => 1;

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
            throws_on_exhaustion  => qr/exhausted/,
              on_exhaustion_throw => 1;

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
            throws_on_exhaustion  => sub { $_[0] =~ 'exhausted' },
              on_exhaustion_throw => 1;

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
            throws_on_exhaustion  => sub { $_[0] =~ 'exhausted' },
              on_exhaustion_throw => 1;

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
