package Iterator::Flex::Role::Exhaustion::PassthroughThrow;

# ABSTRACT: signal exhaustion by setting exhausted flag;

use strict;
use warnings;

our $VERSION = '0.12';

use Role::Tiny;

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
    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Exhausted->throw;
}


1;

# COPYRIGHT
