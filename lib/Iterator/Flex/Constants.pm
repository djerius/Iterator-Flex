package Iterator::Flex::Constants;

use strict;
use warnings;

# ABSTRACT: Constants for Iterator::Flex

our $VERSION = '0.03';

use Exporter 'import';
use constant { INACTIVE => 0, ACTIVE => 1, EXHAUSTED => 2 };

our @EXPORT_OK = qw[ INACTIVE ACTIVE EXHAUSTED ];
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

1;



