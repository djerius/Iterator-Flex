package Iterator::Flex::Role::Exhaustion::RequestedThrow;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.11';

use Role::Tiny;
use Iterator::Flex::Failure;

=method signal_exhaustion

   $iterator->signal_exhaustion;

Signal that the iterator is exhausted.  This version sets the
iterator's exhausted flag and throws an exception.


=cut

sub signal_exhaustion {

    my $self = shift;
    $self->set_exhausted;
    Iterator::Flex::Failure::Exhausted->throw;
}

requires 'set_exhausted';

1;
