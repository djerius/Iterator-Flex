use Dumbbench;

use strict;
use warnings;

use lib 'lib';

use Iterator::Flex   ();
use Iterator::Simple ();
use Iterator::Util   ();

my $bench = Dumbbench->new;

my $maxarr = 10000;

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        name => 'Simple',
        code => sub {
            my $iter = Iterator::Simple::iarray( [ 1 .. $maxarr ] );
            while ( defined $iter->() ) {}
        }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'Flex',
        code => sub {
            my $iter = Iterator::Flex::iarray( [ 1 .. $maxarr ] );
            while ( defined $iter->next ) { }
        }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'Flex: avoid method lookup',
        code => sub {
            my $iter = Iterator::Flex::iarray( [ 1 .. $maxarr ] );
            my $next = $iter->can('next');
            while ( defined $next->($iter) ) { }
        }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'Flex: $iter->()',
        code => sub {
            my $iter = Iterator::Flex::iarray( [ 1 .. $maxarr ] );
            while ( defined $iter->() ) { }
        }
    ),
    Dumbbench::Instance::PerlSub->new(
        name => 'Iterator',
        code => sub {
            my $iter = Iterator::Util::iarray( [ 1 .. $maxarr ] );
            eval {
                while ( $iter->isnt_exhausted ) { $iter->value  }
            };
        }
    ),
);

$bench->run;
$bench->report;
