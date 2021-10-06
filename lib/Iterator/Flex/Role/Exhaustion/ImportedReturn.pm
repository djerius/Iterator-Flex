package Iterator::Flex::Role::Exhaustion::ImportedReturn;

# ABSTRACT: Imported iterator returns a sentinel

use strict;
use warnings;

our $VERSION = '0.14';

use Iterator::Flex::Utils qw( :default :RegistryKeys );

use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method imported_sentinel

  $sentinel = $iterator->sentinel

returns the sentinel which the iterator will return to signal exhaustion

=cut

sub imported_sentinel ($self) {
    return $REGISTRY{ refaddr $self }{+GENERAL}{ +INPUT_EXHAUSTION }[1];
}

1;

# COPYRIGHT
