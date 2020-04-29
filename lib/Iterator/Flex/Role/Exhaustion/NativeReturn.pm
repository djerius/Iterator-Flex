package Iterator::Flex::Role::Exhaustion::NativeReturn;

# ABSTRACT: Native iterator returns a sentinel

use strict;
use warnings;

our $VERSION = '0.11';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default :NativeExhaustionActions );

sub sentinel {
    return $REGISTRY{ refaddr $_[0] }{+RETURNS_ON_EXHAUSTION};
}

1;

# COPYRIGHT
