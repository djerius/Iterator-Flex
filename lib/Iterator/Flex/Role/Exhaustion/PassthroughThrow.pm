package Iterator::Flex::Role::Exhaustion::PassthroughThrow;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.11';

use Role::Tiny;
use Iterator::Flex::Failure;

use namespace::clean;

=method signal_exhaustion

   $iterator->signal_exhaustion( @_ );

Signal that the iterator is exhausted.  This version sets the
iterator's exhausted flag and throws C<@_> if provided,
else C<Iterator::Flex::Failure::Exhausted>.


=cut

sub signal_exhaustion {

    my $self = shift;
    $self->set_exhausted;

    die( @_ ) if @_;
    Iterator::Flex::Failure::Exhausted->throw;
}

requires 'set_exhausted';

1;
