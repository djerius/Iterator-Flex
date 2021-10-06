package Iterator::Flex::Role::Exhaustion::Return;

# ABSTRACT: signal exhaustion by returning a sentinel value.

use strict;
use warnings;

our $VERSION = '0.14';

use Scalar::Util();
use Iterator::Flex::Utils qw[ :default :RegistryKeys ];
use Role::Tiny;
use experimental 'signatures';

use namespace::clean;

=method sentinel

  $sentinel = $iterator->sentinel

returns the sentinel which the iterator will return to signal exhaustion

=cut

sub sentinel ($self) {
    return $REGISTRY{ refaddr $self }{+GENERAL}{+EXHAUSTION}[1];
}

=method signal_exhaustion

   $sentinel = $iterator->signal_exhaustion;

Signal that the iterator is exhausted, by calling C<<
$self->set_exhausted >> and returning the iterator's sentinel value.

=cut

sub signal_exhaustion ($self, @) {
    $self->set_exhausted;
    return $self->sentinel;
}


1;

# COPYRIGHT
