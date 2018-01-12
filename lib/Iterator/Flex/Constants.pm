package Iterator::Flex::Constants;

use Exporter 'import';
use constant { INACTIVE => 0, ACTIVE => 1, EXHAUSTED => 2 };

our @EXPORT_OK = qw[ INACTIVE ACTIVE EXHAUSTED ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;



