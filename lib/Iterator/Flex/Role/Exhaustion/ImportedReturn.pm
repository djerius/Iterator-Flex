package Iterator::Flex::Role::Exhaustion::ImportedReturn;

# ABSTRACT: Imported iterator returns a sentinel

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default :ImportedExhaustionActions );

use namespace::clean;

sub sentinel {
    return $REGISTRY{ refaddr $_[0] }{ +RETURNS_ON_EXHAUSTION };
}

1;

# COPYRIGHT
