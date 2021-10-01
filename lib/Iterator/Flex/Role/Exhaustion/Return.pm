package Iterator::Flex::Role::Exhaustion::Return;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.12';

use Scalar::Util();
use Iterator::Flex::Utils qw[ :default :RegistryKeys ];
use Role::Tiny;

use namespace::clean;

=method sentinel

  $sentinel = $iterator->sentinel

returns the sentinel which the iterator will return to signal exhaustion

=cut

sub sentinel {
    return $REGISTRY{ refaddr $_[0] }{+GENERAL}{+EXHAUSTION}[1];
}

=method signal_exhaustion

   $sentinel = $iterator->signal_exhaustion;

Signal that the iterator is exhausted, by setting the iterators I<exhausted> flag
and returning the iterator's sentinel value.

=cut

sub signal_exhaustion {
    my $self = shift;
    $self->set_exhausted;
    return $self->sentinel;
}


1;

# COPYRIGHT
