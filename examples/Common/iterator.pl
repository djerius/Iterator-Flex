#! perl
use v5.10;
use Iterator::Flex::Common ':all';

my $seq = 0;
$iter = iterator { return $seq < 100 ? ++$seq : undef } ;
while ( defined ( my $r = $iter->() ) ) { say $r; }
