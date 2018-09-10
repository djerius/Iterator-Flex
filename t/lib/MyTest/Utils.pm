package MyTest::Utils;

use Test2::V0;
use Test2::API qw[ context ];

use Exporter 'import';

our @EXPORT_OK = qw( drain );

sub drain {
    my ( $iter, $max ) = @_;

    my $cnt = 0;
    1 while defined <$iter> && ++$cnt < $max + 1;

    my $ctx = context();

    is( $cnt, $max, "not enough or too few iterations" );

    $ctx->release;
}

1;
