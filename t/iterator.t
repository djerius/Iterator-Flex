#! perl

use strict;
use warnings;

use Test2::V0;

use Iterator::Flex 'iterator';

subtest 'no attr' => sub {

    my @data = ( 1 .. 10 );
    my @got;
    my $iterator = iterator { shift @data };

    while ( my $data = $iterator->next ) { push @got, $data }

    is( \@got, [ 1 .. 10 ], "got data" );

};

subtest 'attr => rewind' => sub {

    my @data = ( 1 .. 10 );
    my @got;
    my $iterator = iterator { shift @data }
      -pars => { rewind => sub { @data = ( 1 .. 10 ) } };

    while ( my $data = $iterator->next ) { push @got, $data }

    is( \@got, [ 1 .. 10 ], "first run" );

    $iterator->rewind;

    @got = ();
    while ( my $data = $iterator->next ) { push @got, $data }

    is( \@got, [ 1 .. 10 ], "after rewind" );

};

done_testing;
