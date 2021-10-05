package Iterator::Flex::Failure;

# ABSTRACT: Failure classes for Iterator::Flex

use strict;
use warnings;

our $VERSION = '0.13';

use custom::failures qw/Exhausted Error RoleExists Unsupported/;

use custom::failures qw/ class parameter internal /;

1;

# COPYRIGHT

