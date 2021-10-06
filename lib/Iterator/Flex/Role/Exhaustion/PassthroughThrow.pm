package Iterator::Flex::Role::Exhaustion::PassthroughThrow;

# ABSTRACT: signal exhaustion by transitioning to exhausted state and throwing exception

use strict;
use warnings;

our $VERSION = '0.13';

use Role::Tiny;
use experimental 'signatures';
use namespace::clean;

=method signal_exhaustion

   $iterator->signal_exhaustion( @exception );

Signal that the iterator is exhausted.

=over

=item 1

Transition to the L<exhausted state|Iterator::Flex::Manual::Overview/Exhausted Stae>
via the L<Iterator::Flex::Base/set_exhausted> method.

=item 2

die with C<@exception> if provided, else throw L<Iterator::Flex::Failure/Exhausted>.

=back

=cut

sub signal_exhaustion ($self, @exception) {
    $self->set_exhausted;

    die( @exception ) if @exception;
    require Iterator::Flex::Failure;
    Iterator::Flex::Failure::Exhausted->throw;
}


1;

# COPYRIGHT
