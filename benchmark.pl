use Dumbbench;

use strict;
use warnings;

use lib 'lib';

use Iterator::Flex   ();
use Iterator::Simple ();
use Iterator         ();

my $bench = Dumbbench->new;

sub iarray {
    my $arr = shift;
    my $idx = 0;
    Iterator->new(
        sub {
            Iterator::is_done if $idx == @$arr;
            return $arr->[ $idx++ ];
        } );
}

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
        name => 'Iterator',
        code => sub {
            my $iter = iarray( [ 1 .. $maxarr ] );
            eval {
                while ( $iter->isnt_exhausted ) { $iter->value  }
            };
        }
    ),
);

$bench->run;
$bench->report;
