package MyTest::Utils;

use Exporter 'import';

our @EXPORT_OK = qw( drain );

sub drain {
    my ( $max, $iter ) = @_;

    my $cnt = 0;
    1 while defined <$iter> && ++$cnt < $max + 1;

    return $cnt;
}

1;
