package Iterator::Flex::Role::Exhaustion::RequestedReturn;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.11';

use Scalar::Util();
use Iterator::Flex::Utils qw[ :default ON_EXHAUSTION_RETURN ];
use Role::Tiny;

=method signal_exhaustion

   $iterator->signal_exhaustion;

Signal that the iterator is exhausted.  This version simply sets the
iterator's exhausted flag.


=cut

sub signal_exhaustion {
    my $self = shift;
    $self->set_exhausted;
    return $REGISTRY{ refaddr $self }{ +ON_EXHAUSTION_RETURN };
}

requires 'set_exhausted';

1;
