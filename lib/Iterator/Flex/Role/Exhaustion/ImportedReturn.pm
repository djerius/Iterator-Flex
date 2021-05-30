package Iterator::Flex::Role::Exhaustion::ImportedReturn;

# ABSTRACT: Imported iterator returns a sentinel

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;
use Iterator::Flex::Utils qw( :default :RegistryKeys );

use namespace::clean;

=method imported_sentinel

  $sentinel = $iterator->sentinel

returns the sentinel which the iterator will return to signal exhaustion

=cut

sub imported_sentinel {
    return $REGISTRY{ refaddr $_[0] }{+GENERAL}{ +INPUT_EXHAUSTION }[1];
}

1;

# COPYRIGHT
